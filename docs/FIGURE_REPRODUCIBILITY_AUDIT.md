# Figure Reproducibility Audit

## Purpose

This document records the current code-to-output mapping for manuscript figures in the NM2 instability-signal repository.

It is an architecture and provenance audit. A final release-level execution PASS must be established separately by running the release validation commands on the release candidate.

## Figure 1

Canonical manuscript asset:

```text
03_figures/main/Fig1_conceptual_masking.tiff
```

Figure 1 is a conceptual manuscript figure and is retained as a canonical frozen asset.

## Figure 2

Analytical scripts:

```text
02_methods/R/figure_generation/figure2_pooled_failure.R
02_methods/R/figure_generation/figure2_instability_enrichment.R
```

Generated analytical panels:

```text
04_results/figure2b/figure2B_final_lock.pdf
04_results/figure2c/figure2C_final_lock.pdf
```

Conceptual panel asset:

```text
01_data/precomputed/figure_assets/figure2A_conceptual_locked.png
```

Final deterministic composite assembler:

```text
02_methods/R/figure_generation/assemble_figure2_composite.sh
```

Canonical manuscript asset:

```text
03_figures/main/Fig2_synthetic_validation.tiff
```

The composite assembler is intentionally outside `run_nm2_pipeline.R`.

## Figure 3

Scripts:

```text
02_methods/R/figure_generation/figure3_uv_quadrant.R
02_methods/R/figure_generation/figure3_instability_vs_variance.R
02_methods/R/figure_generation/figure3_instability_vs_disagreement.R
02_methods/R/figure_generation/figure3_gene_examples.R
```

Canonical manuscript asset:

```text
03_figures/main/Fig3_uv_instability.tiff
```

## Figure 4

DES support:

```text
02_methods/R/figure_generation/figure4_des_support.R
04_results/figure4a_des_support/figureS4a_des_support_locked.pdf
```

GAM temporal extension:

```text
02_methods/R/figure_generation/figure4_gam_temporal_extension.R
04_results/figure4b_gam_temporal_extension/figureS4b_gam_temporal_extension_locked.pdf
```

Main cross-condition analysis:

```text
02_methods/R/figure_generation/figure4_cross_condition_panel.R
04_results/figure4_mixed_real_and_control_conditions_LOCKED/figure4_mixed_real_and_control_conditions_LOCKED.pdf
```

Canonical manuscript asset:

```text
03_figures/main/Fig4_cross_condition_specificity.tif
```

In the revised manuscript architecture, the cross-condition analysis is the main Figure 4. DES and GAM analyses are retained as supplementary support.

## Figure 5a

Script:

```text
02_methods/R/figure_generation/figure5_rank_displacement.R
```

Generated output:

```text
04_results/figure5a_rank_displacement/figure5a_rank_displacement_locked.pdf
```

## Figure 5b

Script:

```text
02_methods/R/figure_generation/figure5_topN_overlap.R
```

Generated output:

```text
04_results/figure5b_topN_overlap/figure5b_topN_overlap_locked.pdf
```

## Figure 5c: Selection Stability

Script:

```text
02_methods/R/figure_generation/figure5c_selection_stability.R
```

Generated output:

```text
04_results/figure5c_selection_stability_FINAL/Figure5C_selection_stability_FINAL.pdf
```

## Figure 5 Annotation Workflow

The current master runner executes:

```text
02_methods/R/figure5c_annotation_workflow/01_build_ncbi_reference_map_for_figure5c.R
02_methods/R/figure5c_annotation_workflow/02_match_figure5c_genes_to_ncbi_reference.R
02_methods/R/figure5c_annotation_workflow/03_extract_matched_ncbi_proteins_for_figure5c.R
02_methods/R/figure5c_annotation_workflow/04_merge_annotation_and_make_figure5c.R
02_methods/R/figure5c_annotation_workflow/00_validate_mapping_integrity.R
```

The workflow requires the version-locked external NCBI reference `GCA_001949185.1`, prepared with:

```bash
bash 02_methods/reference_data/prepare_ncbi_reference.sh
```

`02_methods/R/figure5c_annotation_workflow/05_term_enrichment_for_figure5c.R` is retained in the repository but is not called by the current master runner and therefore is not represented here as part of the release master workflow.

## Figure 5d

Script:

```text
02_methods/R/figure_generation/figure5d_curated_examples_table.R
```

Generated output:

```text
04_results/figure5d_curated_examples_TABLE_FINAL_REVISED/Figure5d_curated_examples_TABLE_FINAL_REVISED.pdf
```

## Figure 5e

Script:

```text
02_methods/R/figure_generation/figure5e_functional_composition.R
```

Generated output:

```text
04_results/figure5e_FINAL/figure5e_FINAL.pdf
```

The script uses:

```text
01_data/raw/ncbi_dataset/ncbi_dataset/data/GCA_001949185.1/cds_from_genomic.fna
```

together with precomputed Pfam/HMMER and InterProScan resources prepared for runtime use under:

```text
04_results/figure5e_global_functional_structure/annotation_from_scratch/
```

## Figure 5 Canonical Asset

```text
03_figures/main/Fig5_prioritization_divergence.tiff
```

## Figure 6

Script:

```text
02_methods/R/figure_generation/figure6_variance_disentanglement.R
```

Generated outputs:

```text
04_results/figure6_variance_disentanglement_FINAL/Figure6_variance_disentanglement_FINAL.pdf
04_results/figure6_variance_disentanglement_FINAL/figure6_source_table.tsv
```

Canonical manuscript asset:

```text
03_figures/main/Fig6_variance_disentanglement.tiff
```

## Supplementary Figures

```text
05_supplementary/supplementary_figures/FigS1.png
05_supplementary/supplementary_figures/FigS2.png
```

## Reviewer-Driven Validation

Revision-specific robustness analyses are stored under:

```text
02_methods/R/reviewer_validation/
04_results/reviewer_validation/
```

They are intentionally outside the manuscript master runner.

## Release Audit

The repository provides:

```bash
bash run_figure_output_audit.sh
```

to verify the presence of the canonical manuscript figure assets and selected generated components.

This document should not be interpreted as evidence that the current release candidate has passed a fresh full execution. That status is established only after the release validation sequence is actually run.
