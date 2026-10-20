#!/usr/bin/env bash
set -u

tool="./pb-CpG-tools-v3.0.0-x86_64-unknown-linux-gnu/bin/aligned_bam_to_cpg_scores"

if [[ ! -x "$tool" ]]; then
  echo "Error: tool is missing or not executable: $tool" >&2
  exit 1
fi

shopt -s nullglob
bams=(./bam_files/*.bam)
if (( ${#bams[@]} == 0 )); then
  echo "No BAM files found in the current directory." >&2
  exit 1
fi

failed=0
for bam in "${bams[@]}"; do
  prefix=${bam#./}
  prefix=${prefix%.bam}
  echo "Processing: $bam"
  if "$tool" --bam "$bam" --pileup-mode count --min-coverage 1 --min-mapq 0 --output-prefix "$prefix"; then
    echo "Completed: $prefix"
  else
    rc=$?
    echo "Failed (exit $rc): $bam" >&2
    failed=1
  fi
done

exit "$failed"
