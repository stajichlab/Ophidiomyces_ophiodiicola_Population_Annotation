#!/bin/bash -l
#SBATCH -p short -C ryzen --ntasks 2 --nodes 1 --mem 24G --out logs/repeatLandscape.%a.log -a 1-5

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
if [ -z $SLURM_JOB_ID ]; then
  SLURM_JOB_ID=$$
fi
module load RepeatMasker
module load kent
module load workspace/scratch

GENOMEDIR=$(realpath genomes)
INDIR=$(realpath repeatmasker_reports)
OUTDIR=$(realpath repeatmasker_plots)
SAMPFILE=samples.csv

mkdir -p $OUTDIR
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPFILE | awk '{print $1}')
if [ $N -gt $(expr $MAX) ]; then
    MAXSMALL=$(expr $MAX)
    echo "$N is too big, only $MAXSMALL lines in $SAMPFILE"
    exit
fi

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN VERSION PHYLUM BIOPROJECT BIOSAMPLE LOCUS
do
    name=$(echo -n ${SPECIES}_${STRAIN}.${VERSION} | perl -p -e 's/\s+/_/g')
    genome=$GENOMEDIR/$name.sorted.fasta
    twoBit=$GENOMEDIR/$name.sorted.2bit
    if [[ ! -s $twoBit || $genome -nt $twoBit ]]; then
	    faToTwoBit $genome $twoBit
    fi
    # sum all the contigs to get genome size
    genomeSize=$(twoBitInfo -noNs $twoBit stdout | cut -f2 | paste -s -d+ - | bc)

    RUNDIR=$INDIR/${name}.RM
    if [ ! -d $RUNDIR ]; then
	echo "No repeatmasker dir $RUNDIR"
    fi
    TMPDIV=$RUNDIR/${name}.sorted.fasta.align
    DIVFILE=""
    # test to see if we have either an uncompressed version of the file or compressed ones
    for div in $TMPDIV $TMPDIV.gz $TMPDIV.bz2
    do
	if [ -f $div ]; then
	    DIVFILE=$div
	    break
	fi
    done
    if [ ! -z $DIVFILE ]; then
	echo "using divfile $DIVFILE"
    else 
	echo "Cannot find a divfile in $RUNDIR ($TMPDIV)"
	exit
    fi
    DIVSUM=$OUTDIR/${name}.divsum
    if [[ ! -s $DIVSUM || $DIVFILE -nt $DIVSUM ]]; then
	calcDivergenceFromAlign.pl -s $DIVSUM $DIVFILE
    fi
    ./scripts/createRepeatLandscape.pl -div $DIVSUM -twoBit $twoBit > $OUTDIR/${name}.landscape.html

    tail -n 72 $DIVSUM > $DIVSUM.tbl
    Rscript scripts/plot_kimuradist_TE.R $DIVSUM.tbl $genomeSize

done
