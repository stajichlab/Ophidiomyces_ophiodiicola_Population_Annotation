#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 24G --out logs/vecscreen.%a.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=genomes
MINLEN=5000
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
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN VERSION  PHYLUM BIOPROJECT BIOSAMPLE LOCUS
do
    name=$(echo -n ${SPECIES}_${STRAIN}.$VERSION | perl -p -e 's/\s+/_/g')
    if [ ! -f $INDIR/${name}.assembled.fasta ]; then
	echo "Cannot find $name in $INDIR - may not have been run yet"
	exit
    fi
    echo "$name"
    
    if [ ! -f $OUTDIR/${name}.sorted.fasta ]; then
	module load AAFTF
	if [ ! -f $OUTDIR/${name}.vecscreen.fasta ]; then
	    AAFTF vecscreen -i $OUTDIR/${name}.assembled.fasta -o $OUTDIR/${name}.vecscreen.fasta --cpus $CPU
	fi
	AAFTF sort -i $OUTDIR/${name}.vecscreen.fasta -o $OUTDIR/${name}.sorted.fasta --minlen $MINLEN
    fi
done
