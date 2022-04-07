#!/usr/bin/bash -l
SAMPFILE=samples.csv
TEMPLATE=lib/template.sbt
OUTDIR=lib/sbt

mkdir -p $OUTDIR
IFS=,
tail -n +2 $SAMPFILE |  while read SPECIES STRAIN VERSION PHYLUM BIOPROJECT BIOSAMPLE LOCUS
do
	STRAIN_NOSPACE=$(echo -n "$STRAIN" | perl -p -e 's/\s+/_/g')
	perl -p -e "s/SAMXXXXXXXX/$BIOSAMPLE/" $TEMPLATE > $OUTDIR/$STRAIN_NOSPACE.sbt
done
