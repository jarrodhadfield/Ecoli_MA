#!/usr/bin/env bash
set -euo pipefail

# ------------- USER SETTINGS ---------------------------------
threads=32                              
raw=~/Work/Ecoli_MA/raw                
work=~/Work/Ecoli_MA                  
# -------------------------------------------------------------

mkdir -p "$work"/qc

# 1. optional FastQC on trimmed reads ---------------------------------
if [[ ! -d $work/qc/fastqc_done ]]; then
    echo "Running FastQC …"
    parallel -j"$threads" fastqc -q -o "$work/qc" {} ::: "$raw"/*/*_R{1,2}*.fastq.gz
    touch "$work/qc/fastqc_done"
fi

echo -e "\n  QC finished OK"
