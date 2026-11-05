# Reviewer-Driven Validation

## Scope

This directory contains revision-specific validation analyses added in response to reviewer concerns.

These analyses are deliberately separated from the core manuscript runner. They test robustness and interpretation without silently changing the locked instability definition or the original core analysis workflow.

Outputs are stored under:

```text
04_results/reviewer_validation/
```

## Formal Interaction Validation

Script:

```text
01_formal_interaction_validation.R
```

This analysis evaluates formal interaction structure relevant to the interpretation of pooled versus subgroup-aware effects.

## Independent Enrichment Validation

Script:

```text
02_independent_enrichment_validation.R
```

This analysis provides an independent enrichment-oriented validation of instability-prioritized signal structure.

## Subgroup and Sample-Size Sensitivity

Script:

```text
03_subgroup_sample_size_sensitivity.R
```

The finalized sensitivity analysis contains two complementary perturbation designs.

### UV: Leave-One-Treatment-Timepoint-Out

Fourteen leave-one-treatment-timepoint-out perturbations were evaluated.

Across perturbations:

- Spearman correlation with the full-data instability ranking: median 0.9837, range 0.9614-0.9919.
- Top-set Jaccard similarity: median 0.8759, range 0.7966-0.9167.
- Retention of the original top set: median 0.9338, range 0.8868-0.9566.
- Full-data median instability: 0.4278.
- Perturbed median instability: median 0.4244, range 0.4041-0.4683.

These results show that the UV instability ranking and high-instability set are highly stable to removal of individual treatment-timepoint observations.

### DES: Exhaustive n=3 to n=2 Per-Cell Sensitivity

Eighty-one exhaustive reduced-sample configurations were evaluated by reducing each DES cell from three to two samples.

Across perturbations:

- Spearman correlation with the full-data instability ranking: median 0.7536, range 0.6138-0.8444.
- Top-set Jaccard similarity: median 0.5320, range 0.3885-0.6812.
- Retention of the original top set: median 0.6945, range 0.5596-0.8104.
- Full-data median instability: 0.3919.
- Perturbed median instability: median 0.4124, range 0.3306-0.5442.

DES is therefore less stable than UV under deliberate sample-size reduction, as expected for the smaller subgroup design, but retains substantial rank and top-set structure across the exhaustive perturbations.

The sensitivity results should not be interpreted as demonstrating invariance to sample size. Instead, they quantify the degree to which the observed instability structure persists under the specific perturbations tested.

## Design and Result Locks

The analysis design and finalized interpretation are documented in:

```text
R2C2_R3C1_DESIGN_LOCK.md
R2C2_R3C1_RESULT_LOCK.md
```

These lock files should be consulted together with the generated TSV outputs when auditing reviewer-response claims.

## Historical Bootstrap Audit

Historical bootstrap reconstruction material is retained under:

```text
historical_bootstrap_audit/
```

This material is provenance/audit support and is not part of the current master manuscript runner.
