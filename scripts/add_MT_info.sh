#!/bin/bash -l
#SBATCH -p short -N 1 -n 8 --mem 32gb --out logs/fix_MT_rerun.log
module unload miniconda3
module load funannotate/1.8
source activate funannotate-1.8
which python
SCRIPT=/opt/linux/centos/7.x/x86_64/pkgs/miniconda3/4.3.31/envs/funannotate-1.8/lib/python3.8/site-packages/funannotate/aux_scripts/tbl2asn_parallel.py 

SAMPFILE=samples.csv

IFS=,
tail -n +2 $SAMPFILE | while read SPECIES STRAIN VERSION PHYLUM BIOSAMPLE BIOPROJECT LOCUSTAG
do
	BASE=$(echo -n ${STRAIN} | perl -p -e 's/\s+/_/g; s/NWHC_//; s/(CBS|UAMH)_/$1-/')
	STRAIN_NOSPACE=$(echo -n "$STRAIN" | perl -p -e 's/\s+/_/g')
  	TEMPLATE=$(realpath lib/sbt/$STRAIN_NOSPACE.sbt)
	SPFULL=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/ /_/g')
	echo "$SPFULL"

	TARGETSQN=annotate/$BASE/annotate_results/$SPFULL.sqn
  if [ ! -f $TEMPLATE ]; then
    echo "NO TEMPLATE for $name"
    exit
  fi
  echo "processing $BASE"
  FASTA=annotate/$BASE/annotate_misc/tbl2asn/genome.fsa
        perl -p -e 's/^>mt/>mt [location=mitochondrion] [topology=circular] [gcode=4]/' annotate/$BASE/annotate_misc/genome.scaffolds.fasta > $FASTA
	python3.8 $SCRIPT -i annotate/$BASE/annotate_misc/tbl2asn/genome.tbl -f $FASTA \
		-o annotate/$BASE/annotate_misc/tbl2asn --sbt $TEMPLATE -d ${BASE}_discrepency.report.txt -s "$SPECIES" \
		-t '-l paired-ends' -v 1 -c 8 --strain "$STRAIN"
	rsync -a annotate/$BASE/annotate_misc/tbl2asn/genome.sqn $TARGETSQN
done
