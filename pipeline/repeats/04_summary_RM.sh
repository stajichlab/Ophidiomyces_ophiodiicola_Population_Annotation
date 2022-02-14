#!/usr/bin/bash -l
#SBATCH -p short -C xeon -N 1 -n 1 --mem 8gb
module load miniconda3

./scripts/summarize_repeatmasker_comparative.py  -op summary_RM_pct.csv -o summary_RM.csv -d repeatmasker_reports
