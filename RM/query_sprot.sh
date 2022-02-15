#!/usr/bin/bash -l
#SBATCH -p short -C xeon -n 8 --mem 16gb

module load diamond
CPU=8
diamond blastx --threads 8 --db /srv/projects/db/Swissprot/2021_01/uniprot_sprot.dmnd -q 23942-1.fasta-families.fa -f 6 --out 23942-1.fasta-families.sprot.BLASTX.tab
