# NM2 Reproducibility

## Reproducibility Scope

This repository contains processed expression inputs, metadata, analysis scripts, precomputed annotation resources, generated result tables, and frozen manuscript assets for the NM2 instability-signal study.

The primary manuscript analysis is executed with:

```bash
bash run_all.sh
```

which invokes:

```bash
Rscript 02_methods/R/run_nm2_pipeline.R
```

The master runner executes each analysis script in a separate `Rscript --vanilla` process.

## Clean-Checkout Prerequisite: External NCBI Reference

The Figure 5 annotation workflow requires public reference files from the version-locked NCBI GenBank assembly:

```text
GCA_001949185.1
```

Required files:

```text
01_data/raw/ncbi_dataset/ncbi_dataset/data/GCA_001949185.1/cds_from_genomic.fna
01_data/raw/ncbi_dataset/ncbi_dataset/data/GCA_001949185.1/protein.faa
```

These external reference files are intentionally excluded from Git.

Before running the complete manuscript pipeline from a clean checkout, prepare them with:

```bash
bash 02_methods/reference_data/prepare_ncbi_reference.sh
```

The preparation script requires the NCBI Datasets command-line client and `unzip`. It is locked to `GCA_001949185.1`, checks that both required files exist and are non-empty, and reuses a complete existing reference on subsequent runs.

## Processed Analysis Inputs

The manuscript-level NM2 workflow starts from distributed processed expression matrices and metadata. It does not require regeneration of the processed matrices from FASTQ files.

An optional reconstructed upstream preprocessing workflow is provided under:

```text
02_methods/preprocessing/
```

This preprocessing workflow is separate from the manuscript master runner.

## Precomputed Annotation Resources

Figure 5e uses supplied Pfam/HMMER and InterProScan outputs:

```text
01_data/precomputed/figure5e_annotation/figure5e_pfam.domtblout
01_data/precomputed/figure5e_annotation/figure5e_interproscan.tsv
```

At the start of the master workflow, `02_methods/R/00_prepare_precomputed_resources.R` copies these resources into the runtime result location:

```text
04_results/figure5e_global_functional_structure/annotation_from_scratch/
```

The master pipeline does not rerun Pfam/HMMER or InterProScan.

## Master Runner Boundary

`02_methods/R/run_nm2_pipeline.R` executes the core instability analyses and manuscript figure-generation scripts, including the current Figure 5 NCBI annotation workflow and Figure 6 analysis.

Two release components are intentionally outside that master runner:

1. final Figure 2 composite assembly; and
2. reviewer-driven revision validation.

This separation is explicit rather than hidden inside the main analysis command.

## Figure 2 Composite

The R master runner regenerates the analytical Figure 2 panel outputs.

Final Figure 2 composite assembly is maintained as a separate deterministic step:

```bash
bash 02_methods/R/figure_generation/assemble_figure2_composite.sh
```

The canonical manuscript asset is:

```text
03_figures/main/Fig2_synthetic_validation.tiff
```

## Reviewer-Driven Validation

Reviewer-specific validation scripts are maintained under:

```text
02_methods/R/reviewer_validation/
```

with outputs under:

```text
04_results/reviewer_validation/
```

These analyses are not executed by `run_nm2_pipeline.R`. They provide revision-specific robustness evidence without silently changing the locked core workflow.

## Lightweight Validation

A smoke test is available as:

```bash
bash run_smoke.sh
```

It checks core input/output functionality without executing the complete manuscript pipeline.

The manuscript output inventory can be checked with:

```bash
bash run_figure_output_audit.sh
```

The output audit verifies the presence of canonical manuscript figures, key generated Figure 5 components, Figure 5e annotation resources, and supplementary manuscript assets.

## Release Validation Policy

A repository state should be described as fully reproducibility-tested only after all applicable release checks have succeeded in that release candidate:

1. external NCBI reference preparation;
2. smoke test;
3. complete master pipeline;
4. Figure 2 composite assembly verification;
5. manuscript output audit; and
6. final Git diff/status review.

Until those checks have been completed on the release candidate, documentation should describe the workflow and prerequisites without claiming a final successful release run.
