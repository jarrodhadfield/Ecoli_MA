#!/usr/bin/env bash
set -euo pipefail

# ------------- USER SETTINGS ---------------------------------
bwa_threads=8
root=~/Work/Ecoli_MA                                                # project root
# -------------------------------------------------------------

mkdir -p "$root"/bam_test  # directory for storing bam files  

raw="$root"/raw  # location of fastq files (separate directories per sample)

echo -e "\n=== ALIGNMENT ==="

for dir in "$raw"/*/ ; do                     # every sample folder
    [[ -d $dir ]] || continue                 # check dir is a directory

    sample=${dir#"$raw"/} ; sample=${sample%/}  # get sample name
    bam=$root/bam_test/${sample}.bam                 # output bam file name
    ref=$root/ref_test/${sample}.fna                 # reference genome file name

    bwa index  "$ref"; 
    samtools faidx "$ref"; 
    # create bwa and fai index files for the reference genome if they do not exist

    r1=$(find "$dir" -maxdepth 1 -name '*_R1*.fastq.gz' -print -quit)
    r2=$(find "$dir" -maxdepth 1 -name '*_R2*.fastq.gz' -print -quit)
    # get file names for the paired ends

    if [[ -z "$r1" || -z "$r2" ]]; then
        echo "PROBLEM: Missing R1 or R2 file in $dir – skipped" >&2
        continue
    fi

    echo "ALLIGNING  $sample"

    bwa mem -t"$bwa_threads" "$ref"  "$r1" "$r2" \
      | samtools sort -n  -@4 -o - -          \
      | samtools fixmate   -m - -             \
      | samtools sort      -@4 -o - -         \
      | samtools markdup   -@4 - "$bam"    

    # aligns to reference genome
    # sorts output by read name
    # corrects mate-pair info
    # resorts output by location
    # mark duplicate reads     

    samtools index "$bam"   # create index file for the final BAM file


done

echo -e "\n Mapping finished OK"
