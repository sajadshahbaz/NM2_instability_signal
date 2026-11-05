# Repository Map

This document maps the principal manuscript figures, analysis scripts, generated outputs, and supplementary materials in the NM2 instability-signal repository.

## Main Figures

### Figure 1

Canonical manuscript asset:

```text
03_figures/main/Fig1_conceptual_masking.tiff
```

Conceptual illustration of pooling-induced signal attenuation and instability-based recovery.

### Figure 2

Analysis scripts:

```text
02_methods/R/figure_generation/figure2_pooled_failure.R
02_methods/R/figure_generation/figure2_instability_enrichment.R
```

Generated panel outputs:

```text
04_results/figure2b/figure2B_final_lock.pdf
04_results/figure2c/figure2C_final_lock.pdf
```

The final composite is assembled separately with:

```text
02_methods/R/figure_generation/assemble_figure2_composite.sh
```

Canonical manuscript asset:

```text
03_figures/main/Fig2_synthetic_validation.tiff
```

The composite assembler is intentionally separate from the R master runner.

### Figure 3

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

### Figure 4

Supporting DES and GAM analyses:

```text
02_methods/R/figure_generation/figure4_des_support.R
02_methods/R/figure_generation/figure4_gam_temporal_extension.R
```

Main cross-condition analysis:

```text
02_methods/R/figure_generation/figure4_cross_condition_panel.R
```

Generated main-panel output:

```text
04_results/figure4_mixed_real_and_control_conditions_LOCKED/figure4_mixed_real_and_control_conditions_LOCKED.pdf
```

Canonical manuscript asset:

```text
03_figures/main/Fig4_cross_condition_specificity.tif
```

DES and GAM support are retained as supplementary analyses rather than separate main Figure 4 panels.

### Figure 5

Figure 5a:

```text
02_methods/R/figure_generation/figure5_rank_displacement.R
04_results/figure5a_rank_displacement/figure5a_rank_displacement_locked.pdf
```

Figure 5b:

```text
02_methods/R/figure_generation/figure5_topN_overlap.R
04_results/figure5b_topN_overlap/figure5b_topN_overlap_locked.pdf
```

Selection-stability analysis:

```text
02_methods/R/figure_generation/figure5c_selection_stability.R
04_results/figure5c_selection_stability_FINAL/Figure5C_selection_stability_FINAL.pdf
```

NCBI annotation workflow executed by the master runner:

```text
02_methods/R/figure5c_annotation_workflow/01_build_ncbi_reference_map_for_figure5c.R
02_methods/R/figure5c_annotation_workflow/02_match_figure5c_genes_to_ncbi_reference.R
02_methods/R/figure5c_annotation_workflow/03_extract_matched_ncbi_proteins_for_figure5c.R
02_methods/R/figure5c_annotation_workflow/04_merge_annotation_and_make_figure5c.R
02_methods/R/figure5c_annotation_workflow/00_validate_mapping_integrity.R
```

Figure 5d:

```text
02_methods/R/figure_generation/figure5d_curated_examples_table.R
04_results/figure5d_curated_examples_TABLE_FINAL_REVISED/Figure5d_curated_examples_TABLE_FINAL_REVISED.pdf
```

Figure 5e:

```text
02_methods/R/figure_generation/figure5e_functional_composition.R
04_results/figure5e_FINAL/figure5e_FINAL.pdf
```

Canonical manuscript asset:

```text
03_figures/main/Fig5_prioritization_divergence.tiff
```

### Figure 6

Script:

```text
02_methods/R/figure_generation/figure6_variance_disentanglement.R
```

Generated output:

```text
04_results/figure6_variance_disentanglement_FINAL/Figure6_variance_disentanglement_FINAL.pdf
```

Canonical manuscript asset:

```text
03_figures/main/Fig6_variance_disentanglement.tiff
```

## Supplementary Figures

```text
05_supplementary/supplementary_figures/FigS1.png
05_supplementary/supplementary_figures/FigS2.png
05_supplementary/supplementary_figures/Supplementary_Figure_Captions.md
```

Figure S1 contains DES magnitude-divergence support.

Figure S2 contains GAM temporal-divergence support.

## Supplementary Tables

```text
05_supplementary/supplementary_tables/TableS1_metadata.csv
05_supplementary/supplementary_tables/TableS2_representative_masked_genes.csv
05_supplementary/supplementary_tables/TableS3_annotations.xlsx
05_supplementary/supplementary_tables/Supplementary_Table_Captions.md
```

## Instability-versus-Variance Supporting Package

```text
05_supplementary/instability_vs_variance/
```

This directory contains supporting analyses used to distinguish instability from conventional variance-based summaries.

## Reviewer-Driven Validation

```text
02_methods/R/reviewer_validation/
04_results/reviewer_validation/
```

These revision-specific validation analyses are maintained separately from the core manuscript runner so that they do not silently alter the locked instability definitions or original core workflow.

## External Reference Data

Figure 5 annotation analyses require the version-locked NCBI GenBank assembly:

```text
GCA_001949185.1
```

The required CDS and protein FASTA files are public external reference data and are intentionally excluded from Git. They can be prepared with:

```bash
bash 02_methods/reference_data/prepare_ncbi_reference.sh
```

## Historical Material

Historical or exploratory material retained for provenance is not part of the final master manuscript workflow unless explicitly referenced by the current runner or documentation.
