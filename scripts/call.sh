#!/usr/bin/env bash
set -euo pipefail

# ------------- USER SETTINGS ---------------------------------
threads=32                               # number of cores to be used                   
export ref=~/Work/Ecoli_MA/ref/GCF_000005845.2_ASM584v2_genomic.fna  # reference genome
root=~/Work/Ecoli_MA                    # project root
# -------------------------------------------------------------

mkdir -p "$root"/vcf
# directory for writing vcf files


echo -e "\n=== VARIANT CALLING ==="
parallel -j2 '
    bam={}                                                    # path to bam file
    sample=$(basename ${bam%.bam})                            # generates sample name from bam file name
    rawvcf='$root'/vcf/${sample}.raw.vcf.gz                   # path to vcf output file
    filtered_bam='$root'/filtered_bam/${sample}.filtered.bam           # path to filtered bam file

    [[ -f $rawvcf ]] && { echo "SKIPPED  $sample raw VCF exists" ; exit; }

    samtools view -F 0xF04 -b "$bam" -o "$filtered_bam"
    samtools index "$filtered_bam"

    # removes unmapped, QC-failed and duplicate reads + secondary/supplementary alignments

    bcftools mpileup  --threads 4 -f '"$ref"' \
        -E  \
        --min-MQ 30 --min-BQ 20 "$filtered_bam" |   
    bcftools call   --threads 4 --ploidy 1 -m -Oz -o "$rawvcf"

    # summarise the bases at aligned reads only using reads with mapping quality >30
    # and at bases with base quality >20. Then call variants
    
    bcftools index  "$rawvcf"  # index the vcf files
' ::: "$root"/bam/*.bam

echo -e "\n=== FILTERING ==="

parallel -j"$threads" '
    
    invcf={}                               # path to vcf files
    
    sample=$(basename "$invcf" .raw.vcf.gz)  # get sample name from vcf file name

    outvcf='$root'/vcf/${sample}.flt.vcf.gz  # path to filtered vcf output file

    [[ -f $outvcf ]] && { echo "SKIPPED  $sample filtered VCF exists" ; exit ; }

    bcftools filter -e "QUAL<20" -S . "$invcf" | 
    bcftools view   -v snps,indels -Ou |
    bcftools norm  -m -any -f "$ref" -Oz -o "$outvcf"

    # flags sites with a QUAL score less than 20
    # filter out variants that are not snps or indels
    # standardises variant format
    # index the filtered vcf files
    # standardises variant format

    bcftools index "$outvcf"  # index the fitered vcf files

' ::: "$root"/vcf/*.raw.vcf.gz

echo -e "\n Variant calling finished OK"
