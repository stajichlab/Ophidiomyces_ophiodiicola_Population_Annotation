#!/bin/bash
#SBATCH -p short --ntasks 32 --nodes 1 --mem 24G --out logs/mask.%a.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

module load workspace/scratch

INDIR=$(realpath genomes)
OUTDIR=$(realpath genomes)
LOGS=$(realpath logs)
mkdir -p repeat_library
RL=$(realpath repeat_library)

SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
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
LIBRARY=$RL/Ophidiomyces_ophiodiicola.repeatmodeler-library.fasta
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN VERSION PHYLUM BIOPROJECT BIOSAMPLE LOCUS
do
  name=$(echo -n ${SPECIES}_${STRAIN} | perl -p -e 's/\s+/_/g')
  name=$(echo -n ${STRAIN} | perl -p -e 's/\s+/_/g; s/NWHC_//; s/(CBS|UAMH)_/$1-/')

  if [ ! -f $INDIR/${name}_fullMito.fasta ]; then
     echo "Cannot find ${name}_fullMito.fasta in $INDIR - may not have been run yet"
     exit
  fi
  echo "$name"
  
  if [ ! -f $OUTDIR/${name}.masked.fasta ]; then
     module unload perl python
     module unload miniconda2 anaconda3 miniconda3
     module load funannotate
     export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
     #if [ -f $RL/${name}.repeatmodeler-library.fasta ]; then
    #	  LIBRARY=$RL/${name}.repeatmodeler-library.fasta
     #fi

     #pushd $SCRATCH

     if [ ! -z $LIBRARY ]; then
     	 echo "LIBRARY is $LIBRARY"
    	 funannotate mask --cpus $CPU -i $INDIR/${name}_fullMito.fasta -o $OUTDIR/${name}.masked.fasta -l $LIBRARY --method repeatmodeler
     else
 	echo "de novo needs to be run outside of this and library created with this version of funannogtate"
	exit
       funannotate mask --cpus $CPU -i $INDIR/${name}.sorted.fasta -o $OUTDIR/${name}.masked.fasta --method repeatmodeler
       echo "finished running masking"
       mv repeatmodeler-library.*.fasta $RL/${name}.repeatmodeler-library.fasta
       mv funannotate-mask.log $LOGS/masklog_long.$name.log
       ls -l
     fi
  else
     echo "Skipping ${name} as masked already"
  fi
done
