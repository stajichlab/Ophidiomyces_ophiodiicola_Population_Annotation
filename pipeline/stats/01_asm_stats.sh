#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 --mem 4gb --out logs/assess.log

module load AAFTF

IFS=,
SAMPLES=samples.csv
OUTDIR=genomes

mkdir -p $OUTDIR
while read STRAIN GENOME
do
	BASE=$(basename $GENOME .fasta)
	if [[ ! -f $OUTDIR/$BASE.stats.txt || $OUTDIR/$GENOME -nt $OUTDIR/$BASE.stats.txt ]]; then
		AAFTF assess -i $OUTDIR/$GENOME -r $OUTDIR/$BASE.stats.txt
	    fi
done < $SAMPLES


