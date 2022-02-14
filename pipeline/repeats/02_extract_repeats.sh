#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 -C xeon --mem 16gb --out logs/extract_LTRs.%A.%a.log -a 1

module unload miniconda2
module load miniconda3

source activate bcbio
which python

INDIR=genomes
OUTDIR=repeatmasker_reports
SAMPFILE=samples.csv

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
    if [ ! -f $INDIR/${name}.sorted.fasta ]; then
	echo "Cannot find $name in $INDIR - may not have been run yet"
	exit
    fi
    echo "$name"

    GFF=$OUTDIR/${name}.RM/${name}.sorted.fasta.out.gff
    OUT=$OUTDIR/${name}.RM/${name}.sorted.fasta.out
    if [[ -f $GFF && ! -f $GFF.bz2 ]]; then
	     pbzip2 $GFF
    fi
    if [[ -f $OUT && ! -f $OUT.bz2 ]]; then
	     pbzip2 $OUT
    fi

    if [[ ! -f $OUT.bz2 ]]; then
	     echo "No $OUT.bz2"
	      exit
    fi
    mkdir -p repeat_families/${name}
    python scripts/repeatMasker_to_align.py -g $INDIR/${name}.sorted.fasta -i $OUT.bz2 --outdir repeat_families/${name}

done
