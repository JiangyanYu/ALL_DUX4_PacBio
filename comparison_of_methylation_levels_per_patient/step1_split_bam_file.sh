#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Input BAM file
INPUT_BAM="reads_without_DUX4r.bam"

# Check if input file exists
if [ ! -f "$INPUT_BAM" ]; then
    echo "Error: Input file $INPUT_BAM not found!"
    exit 1
fi

echo "Analyzing read names and splitting $INPUT_BAM..."

# 1. Extract header and keep it in memory/variable or temporary file
HEADER_FILE=$(mktemp)
samtools view -H "$INPUT_BAM" > "$HEADER_FILE"

# 2. Stream alignment records, extract sample name, and split via awk/samtools
samtools view "$INPUT_BAM" | while read -r line; do
    # Extract the read name (1st column)
    read_name=$(echo "$line" | awk '{print $1}')
    
    # Extract sample name (everything before the first '/')
    sample_name=$(echo "$read_name" | cut -d'/' -f1)
    
    # If it's a primary/mapped alignment or you want to group all lines for this sample:
    # Append the header + line to a temporary SAM/BAM pipeline, or write to individual SAM files first.
    # For a robust approach with thousands of reads, writing to a temp SAM per sample is safest:
    
    # Create file if it doesn't exist yet and prepend header
    if [ ! -f "${sample_name}.sam" ]; then
        cat "$HEADER_FILE" > "${sample_name}.sam"
    fi
    
    # Append the read line to the sample's SAM file
    echo "$line" >> "${sample_name}.sam"
done

# 3. Convert all generated SAM files into compressed BAM files and index them
echo "Converting temporary SAM files to BAM format..."
for sam_file in *.sam; do
    # Skip the header template file if named differently, or process all .sam files except header
    if [ "$sam_file" == "$(basename "$HEADER_FILE")" ]; then
        continue
    fi
    
    base_name="${sam_file%.sam}"
    bam_output="${base_name}_reads_without_DUX4r.bam"
    
    # Convert SAM to BAM, sort, and index
    samtools view -b "$sam_file" | samtools sort -o "$bam_output"
    samtools index "$bam_output"
    
    # Clean up intermediate SAM file
    rm "$sam_file"
    echo "Created: $bam_output"
done

# Clean up header temp file
rm "$HEADER_FILE"

echo "Done! All BAM files have been successfully split by sample name."