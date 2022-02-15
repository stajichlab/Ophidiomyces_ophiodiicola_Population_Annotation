#!/usr/bin/bash
#SBATCH --mem 2G --ntasks 1

module load RepeatMasker/4-0-7
SCRIPT=$(dirname $(which RepeatMasker))/util/queryRepeatDatabase.pl
module load funannotate
#SCRIPT=queryRepeatDatabase.pl
#export PERL5LIB=$PERL5LIB:$(dirname $(which RepeatMasker))
 perl $SCRIPT -species fungi -clade > fungi.lib

 cat 23942-1.fasta-families.fa fungi.lib > Ophidiomyces_ophiodiicola.repeatmodeler-library.fasta
