#!/usr/bin/bash -l
#SBATCH -p short -C xeon -N 1 -n 96 --mem 128gb --out logs/mafft_run.%A.%a.log -a 1-7

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

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

    module load mafft
    module load clipkit
    MAKE=$(realpath scripts/makefile.mafft_repeatfam)
    pushd repeat_families/$name
    make -f $MAKE -j $CPU
done
