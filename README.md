# NM2 Instability Signal

This repository contains the analysis code, processed inputs, reproducibility resources, generated results, and manuscript figure assets for the NM2 instability-signal study.

The central analysis asks when a pooled condition-level summary becomes misleading because biologically structured subgroup or temporal responses disagree internally. Instability is used as a diagnostic of that structured internal disagreement; it is not a replacement for differential-expression testing.

## Repository Structure

```text
00_config/                  Configuration and analysis settings
01_data/
  metadata/                 Sample metadata
  processed/                Processed expression inputs
  precomputed/              Frozen/precomputed analysis resources
  raw/                      External-reference location and documentation
02_methods/
  preprocessing/            Optional reconstructed upstream preprocessing workflow
  reference_data/           External reference preparation
  R/
    core_pipeline/          Core instability analyses
    figure_generation/      Manuscript figure-generation scripts
    figure5c_annotation_workflow/
                            Figure 5 annotation workflow
    reviewer_validation/    Revision-specific validation analyses
03_figures/
  main/                     Canonical main manuscript figures
04_results/                 Generated analysis outputs and tables
05_supplementary/
  supplementary_figures/    Supplementary manuscript figures
  supplementary_tables/     Supplementary manuscript tables
  instability_vs_variance/  Supporting instability/variance analyses
docs/                       Reproducibility and audit documentation
env/                        Environment-related files
```

## Main Reproduction Workflow

From the repository root, first prepare the required public NCBI reference:

```bash
bash 02_methods/reference_data/prepare_ncbi_reference.sh
```

The reference preparation is locked to NCBI GenBank assembly:

```text
GCA_001949185.1
```

The downloaded CDS and protein FASTA files are intentionally excluded from Git.

Then run the manuscript analysis:

```bash
bash run_all.sh
```

which executes:

```bash
Rscript 02_methods/R/run_nm2_pipeline.R
```

The master runner starts from the distributed processed expression matrices and metadata. It does not require regeneration of those matrices from FASTQ files.

## Figure 2 Composite

The R master runner regenerates the analytical Figure 2 panels. Final Figure 2 composite assembly is a separate deterministic step:

```bash
bash 02_methods/R/figure_generation/assemble_figure2_composite.sh
```

The canonical manuscript asset is:

```text
03_figures/main/Fig2_synthetic_validation.tiff
```

## Figure 5 External and Precomputed Resources

The Figure 5 annotation workflow requires the external NCBI CDS/protein reference prepared above.

Figure 5e additionally uses bundled precomputed Pfam/HMMER and InterProScan outputs under:

```text
01_data/precomputed/figure5e_annotation/
```

These precomputed resources are copied to their runtime result location by the master workflow. The repository does not rerun Pfam/HMMER or InterProScan.

## Reviewer-Driven Validation

Revision-specific robustness analyses are maintained separately under:

```text
02_methods/R/reviewer_validation/
```

with outputs under:

```text
04_results/reviewer_validation/
```

They are not executed by the master manuscript runner. This keeps reviewer-response validation separate from the locked core analysis.

## Optional Upstream Preprocessing

A reconstructed preprocessing workflow is provided under:

```text
02_methods/preprocessing/
```

This workflow documents the route from upstream sequencing inputs toward the processed matrices used by the manuscript analysis.

It is intentionally separate from the main manuscript reproduction command.

## Canonical Main Figures

```text
03_figures/main/Fig1_conceptual_masking.tiff
03_figures/main/Fig2_synthetic_validation.tiff
03_figures/main/Fig3_uv_instability.tiff
03_figures/main/Fig4_cross_condition_specificity.tif
03_figures/main/Fig5_prioritization_divergence.tiff
03_figures/main/Fig6_variance_disentanglement.tiff
```

## Supplementary Material

Supplementary figures:

```text
05_supplementary/supplementary_figures/
```

Supplementary tables:

```text
05_supplementary/supplementary_tables/
```

The current supplementary tables include:

```text
TableS1_metadata.csv
TableS2_representative_masked_genes.csv
TableS3_annotations.xlsx
```

## Validation Utilities

Lightweight smoke test:

```bash
bash run_smoke.sh
```

Manuscript-output inventory audit:

```bash
bash run_figure_output_audit.sh
```

Detailed reproducibility documentation:

```text
docs/reproducibility.md
```

Figure code-to-output audit:

```text
docs/FIGURE_REPRODUCIBILITY_AUDIT.md
```

Repository map:

```text
REPOSITORY_MAP.md
```

## Reproducibility Status

The repository is structured to support a controlled release-level reproduction check.

A specific release should only be described as fully reproducibility-tested after the external reference preparation, smoke test, complete master run, Figure 2 composite verification, output audit, and final Git review have all succeeded for that release candidate.
