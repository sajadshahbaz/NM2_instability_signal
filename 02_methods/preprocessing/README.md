# NM2 paper-specific RNA-seq preprocessing

Purpose: reconstruct the 111-sample upstream RNA-seq processing used to create the expression inputs for the NM2 instability manuscript.

Historical settings recovered from the analysis notebook:
- 111 samples are authoritative. A historical MultiQC prose reference to 107 was documentation error only.
- fastp followed by MultiQC for read QC/trimming.
- Salmon 1.10.3 historically used; Salmon index k=31.
- Salmon quantification: library autodetection, `--validateMappings --gcBias`.
- gene aggregation: tximport with `countsFromAbundance="lengthScaledTPM"`.
- DESeq2 design for the all-condition preview: `~ condition + group_type`.
- low-count filter before VST: `rowSums(counts(dds_all)) >= 10`.
- VST: `vst(dds_all, blind=TRUE)`.

Following VST, genes are screened for finite values and non-zero variance, and the validated NM2 expression-prevalence filter retains genes with VST-transformed expression >=5 in at least 20% of the 111 analytical samples. This reduces the analytical matrix from 19,270 to 15,187 genes. The identical retained GeneID set is applied to the corresponding tximport gene-level abundance matrix, producing `vst_counts_filtered.tsv` and `x_count_filt.csv` for the downstream NM2 manuscript workflow.

## Required environment variables
`METADATA`, `FASTQ_DIR`, `GENOME`, `ANNOTATION`, `OUT`; optional `THREADS`.

Example:
```bash
export METADATA=/path/Simplified_Metadata_Table.csv
export FASTQ_DIR=/path/raw_fastq
export GENOME=/path/genome.fa
export ANNOTATION=/path/genomic.gff
export OUT=/path/NM2_preprocessing_reproduction
export THREADS=12
bash run_preprocessing.sh
```

After completion, compare reconstructed `x_count.csv` and `vst_counts_all_groups.tsv` with the archived products using `07_validate_against_archived.R`.

The raw-data preprocessing workflow is intentionally separate from the downstream manuscript master runner. `run_all.sh` reproduces the manuscript analyses from the repository-provided processed inputs and does not require reprocessing the raw sequencing reads.
