# Per-patient methylation analysis

This folder contains a workflow for calculating CpG methylation summaries for each patient/read-name group, assigning CpG regions to genes, and analyzing the resulting per-patient tables.

## Workflow

Run the shell scripts in order. Run each script from this folder unless noted otherwise.

### 1. Split the BAM by patient/read-name prefix

Place `reads_without_DUX4r.bam` in this folder, then run:

```bash
bash step1_split_bam_file.sh
```

The script groups alignment records by the part of each read name before the first `/`, writes one sorted and indexed BAM per group, and removes its intermediate SAM files. Outputs are named `<group>_reads_without_DUX4r.bam` in the current directory. It requires `samtools` on `PATH`.

### 2. Calculate CpG scores for the DUX4 part

Place the per-patient BAMs in `bam_files/` and place the CpG tools distribution at the path expected by the script:

```text
./pb-CpG-tools-v3.0.0-x86_64-unknown-linux-gnu/bin/aligned_bam_to_cpg_scores
```

Then run:

```bash
bash step2_run_cpg_scores.sh
```

For each BAM, the script runs `aligned_bam_to_cpg_scores` in count pileup mode to quantify CpG methylation in the DUX4 part. Its filtering thresholds are set directly in the command in `step2_run_cpg_scores.sh`:

| Parameter | Current value | Meaning |
| --- | ---: | --- |
| `--min-mapq` | `0` | Minimum mapping quality for reads included in the calculation. |
| `--min-coverage` | `1` | Minimum read coverage required at a CpG position. |

These values are currently permissive: reads with mapping quality 0 are allowed, and a CpG position needs coverage from at least one read. Change the values in the script to use different thresholds. The script searches for BAMs in `./bam_files/`, writes outputs with prefixes based on each BAM path, and exits nonzero if no BAMs are found or any sample fails. It requires the CpG tools executable above.

### 3. Map CpG calls to genes and calculate means

Make sure `genes_final.bed` exists in this folder and that the `.combined.bed` files produced by the CpG scoring step are in `cpg_minmapq0_mincov1_bed_files/`. Then run:

```bash
bash step3_bedtools_map_use_genenames.sh
```

This step requires `bedtools` on `PATH`. For each input BED, it removes comment lines, sorts records, intersects them with the gene annotation, creates unique gene-associated regions, and calculates the mean of column 4 over those regions. It writes intermediate annotated/region BED files and a `<sample>_methylation_mean.txt` result alongside the input BED; the cleaned and sorted intermediate files are removed when processing succeeds.

The commented commands at the top of the script show one approach for deriving `genes_final.bed` from a GTF and assembly report. Obtain the matching reference annotation files separately and check that the chromosome naming convention matches the CpG BED files.

## Analysis notebook

`repo4.3_all_patients_methylation_analysis.Rmd` contains the downstream R Markdown analysis. Open and knit it in an R environment with the packages and input files referenced by the notebook available.

## Notes

- Step 1 creates per-group BAMs in the current directory, while step 2 reads BAMs from `bam_files/`. Move or copy the step 1 outputs into that directory before running step 2.
- Keep the reference genome/annotation and CpG BED chromosome names consistent (for example, `chr1` versus accession-style sequence names).
