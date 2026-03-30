 #!/bin/bash

# Usage: ./split_bam_by_read_list.sh merged.bam reads.csv

## small bam files were merged by
## split reads with WT and rearranged DUX4
# samtools merge merged.bam ./DUX4_only_aligned_bam/*.bam

# Input arguments
BAM_FILE="$1"
CSV_FILE="$2"

# Check input
if [[ -z "$BAM_FILE" || -z "$CSV_FILE" ]]; then
  echo "Usage: $0 <merged.bam> <reads.csv>"
  exit 1
fi

# Output filenames
READ_LIST="read_list.txt"
SUBSET_BAM="reads_with_DUX4r.bam"
REST_BAM="reads_without_DUX4r.bam"

# Step 1: Convert CSV to read name list (one per line)
echo "[INFO] Converting CSV to read list..."
tr ',' '\n' < "$CSV_FILE" | sed 's/^ *//;s/ *$//' | grep -v '^$' > "$READ_LIST"

# Step 2: Extract reads in the list
echo "[INFO] Extracting matching reads to $SUBSET_BAM..."
samtools view -b -N "$READ_LIST" "$BAM_FILE" > "$SUBSET_BAM"

# Step 3: Extract remaining reads
echo "[INFO] Extracting non-matching reads to $REST_BAM..."
samtools view -b -N "$READ_LIST" -U "$REST_BAM" "$BAM_FILE" > /dev/null

# Step 4: Index the output BAM files
echo "[INFO] Indexing output BAM files..."
samtools index "$SUBSET_BAM"
samtools index "$REST_BAM"

# Done
echo "[INFO] Done. Files created:"
echo " - $SUBSET_BAM"
echo " - $REST_BAM"
