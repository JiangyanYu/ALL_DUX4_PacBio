
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

sample="reads_with_DUX4r_MAPQ1"

##annotate cpg-tools output by adding the gene name of the position
grep -v "^#" ${sample}.combined.bed  > ${sample}.combined_cleaned.bed 
sort -k1,1V -k2,2n ${sample}.combined_cleaned.bed  > ${sample}.combined_cleaned.sorted.bed 

bedtools intersect -a ${sample}.combined_cleaned.sorted.bed  -b genes_final.bed -wa -wb > ${sample}.combined_cleaned.sorted_annotated.bed

## remove tmp files
rm  ${sample}.combined_cleaned.bed ${sample}.combined_cleaned.sorted.bed

## get an overview of all regions
awk 'BEGIN{OFS="\t"} {print $10,$11,$12,$13}' ${sample}.combined_cleaned.sorted_annotated.bed |sort -k1,1V -k2,2n |uniq > ${sample}.regions.bed

## bedtools map the methylation score across this regions
bedtools map -a ${sample}.regions.bed -b ${sample}.combined_cleaned.sorted_annotated.bed  -c 4 -o mean > ${sample}_methylation_mean.txt





