#!/usr/bin/env bash
## get ref gene names

#awk -F ";" '{print $1}' GCF_009914755.1_T2T-CHM13v2.0_genomic.gtf | awk -F "\t" '{OFS="\t"; print $1,$4-1,$5,$9}' | sed 's/gene_id //g' |sed 's/"//g' > genes.bed
#sort -k1,1 -k2,2n genes.bed  | uniq > genes_chr.sorted.bed

## convert NC like chr name to chr

#grep -v "^#" GCF_009914755.1_T2T-CHM13v2.0_assembly_report.txt | awk -F '\t' '{print $7"\t"$10}' > chr_map.txt
#join -t $'\t' -1 1 -2 1 genes_chr.sorted.bed chr_map.txt | awk 'BEGIN{OFS="\t"} {print $5, $2, $3, $4}' > genes_chr.bed
#sed 's/\r//' genes_chr.bed > genes_final.bed
#rm genes.bed genes_cleaned.bed genes_chr.sorted.bed chr_map.txt genes_chr.bed genes_chr.cleaned.bed
 

 ## cpg-tools was performed on the bam file
# sudo /data/genmedbfx/bfx_tools/pb-cpg-tools-v3.0.0/pb-CpG-tools-v3.0.0-x86_64-unknown-linux-gnu/bin/aligned_bam_to_cpg_scores 
#          --bam /home/yu_j/smbshare/tmp/DUX4_only_aligned_bam/${bam_file} 
#          --output-prefix ${sample} 
#          --threads 64

set -euo pipefail

# Run from any working directory; inputs and outputs are relative to this script.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
input_dir="${script_dir}/cpg_minmapq0_mincov1_bed_files"
#input_dir="${script_dir}/bed_files"
genes_bed="${script_dir}/genes_final.bed"

if ! command -v bedtools >/dev/null 2>&1; then
    echo "Error: bedtools is not available in PATH." >&2
    exit 1
fi
if [[ ! -f "${genes_bed}" ]]; then
    echo "Error: gene annotation file not found: ${genes_bed}" >&2
    exit 1
fi

shopt -s nullglob
bed_files=("${input_dir}"/*.combined.bed)
if (( ${#bed_files[@]} == 0 )); then
    echo "Error: no *.combined.bed files found in ${input_dir}" >&2
    exit 1
fi

for bed_file in "${bed_files[@]}"; do
    base="${bed_file%.combined.bed}"
    cleaned="${base}.combined_cleaned.bed"
    sorted="${base}.combined_cleaned.sorted.bed"
    annotated="${base}.combined_cleaned.sorted_annotated.bed"
    regions="${base}.regions.bed"
    means="${base}_methylation_mean.txt"

    echo "Processing $(basename -- "${bed_file}")"

    grep -v '^#' "${bed_file}" > "${cleaned}" || [[ $? -eq 1 ]]
    sort -k1,1V -k2,2n "${cleaned}" > "${sorted}"
    bedtools intersect -a "${sorted}" -b "${genes_bed}" -wa -wb > "${annotated}"

    awk 'BEGIN { OFS="\t" } { print $11,$12,$13, $14 }' "${annotated}" \
        | sort -k1,1V -k2,2n \
        | uniq > "${regions}"

    bedtools map -a "${regions}" -b "${annotated}" -c 4 -o mean > "${means}"
    rm -- "${cleaned}" "${sorted}"
done





