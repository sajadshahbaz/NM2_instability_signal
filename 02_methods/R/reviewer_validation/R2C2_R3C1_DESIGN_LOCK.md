# R2-C2 / R3-C1 reviewer-validation design lock

## Purpose

This document defines the reviewer-driven sensitivity analyses used to address:

- R2-C2: concern that UV instability may reflect unequal temporal sampling, exposure-time structure, or small sample numbers rather than biological heterogeneity.
- R3-C1: concern about sensitivity of instability to small subgroup sizes.

This document is a design lock established before running the sensitivity analyses. The analyses must preserve the original biological grouping and the original instability definition.

No subgroup, timepoint, weighting rule, or instability equation is redefined for the purpose of obtaining more favorable results.

---

# 1. Original UV experimental structure

UV contains two predefined and experimentally separate exposure series.

## Short-exposure series

Control:
- 0 h, n = 3

Treatment:
- 1 h, n = 3
- 2 h, n = 3
- 3 h, n = 3
- 4 h, n = 3
- 5 h, n = 3
- 6 h, n = 3
- 9 h, n = 3
- 12 h, n = 3

Total:
- control n = 3
- treatment n = 24

## Long-exposure series

Control:
- 0 h, n = 3

Treatment:
- 12 h, n = 3
- 18 h, n = 3
- 24 h, n = 3
- 36 h, n = 3
- 48 h, n = 3
- 72 h, n = 3

Total:
- control n = 3
- treatment n = 18

## Critical design point

The short and long exposure series originate from separate experimental studies/blocks.

Both series contain a nominal 12-h treatment timepoint, but the two 12-h groups are independent observations originating from their respective studies and have their own corresponding 0-h controls.

They must NOT be pooled or treated as replicate measurements of a single 12-h experimental group.

The short and long series otherwise sample different temporal ranges. Consequently, study/block, exposure regime, and temporal composition cannot be fully disentangled using the available UV data.

---

# 2. Original UV instability calculation

The original biological partitions are retained exactly:

- short exposure
- long exposure

For each subgroup:

delta_k = mean(treatment_k) - mean(control_k)

The pooled effect is:

delta_pool = mean(all treatment samples) - mean(all control samples)

The stratified effect uses the original sample-number weighting:

w_k = n_k / (n_1 + n_2)

delta_strat = w_1 * delta_1 + w_2 * delta_2

where n_k is the total number of treatment plus control observations in subgroup k.

Instability remains:

heterogeneity gap = |delta_1 - delta_2|

discordance = |delta_pool - delta_strat|

instability = heterogeneity gap + discordance

The weighting rule will NOT be replaced by equal weighting during reviewer validation.

---

# 3. UV sensitivity analysis A: leave-one-timepoint-out

## Question

Is the full-data UV instability ranking disproportionately dependent on any single treatment timepoint?

## Procedure

Starting from the complete UV design:

1. Remove one short-series treatment timepoint at a time.
2. Recalculate instability using all remaining samples and the unchanged core equations.
3. Repeat for each of the eight short treatment timepoints.
4. Separately remove one long-series treatment timepoint at a time.
5. Recalculate instability using all remaining samples and the unchanged core equations.
6. Repeat for each of the six long treatment timepoints.

Total sensitivity configurations:

- short series: 8
- long series: 6
- total: 14

All three biological replicates belonging to the omitted timepoint are removed together.

The corresponding 0-h controls are never removed.

Weights are recalculated using the original sample-number weighting formula after each omission.

## Comparisons with full-data UV result

For every configuration calculate:

- Spearman correlation between full-data and reduced-data gene-level instability;
- overlap of top-decile instability genes;
- Jaccard index for full versus reduced top-decile sets;
- retention fraction of the original full-data top-decile genes;
- median instability;
- change in median instability relative to the full-data analysis.

No arbitrary PASS threshold is defined before observing the results.

## Interpretation boundary

This analysis tests sensitivity to individual sampled treatment timepoints.

It does NOT remove or resolve the confounding between study/block and temporal composition.

---

# 4. UV sensitivity analysis B: shared 12-h diagnostic

## Question

How concordant are the treatment effects observed at the only nominal exposure time shared between the independent short and long UV studies?

## Effects

Calculate independently:

delta_12h_short =
mean(short-study 12-h treatment) -
mean(short-study 0-h control)

and:

delta_12h_long =
mean(long-study 12-h treatment) -
mean(long-study 0-h control)

The two effects are compared across genes.

## Primary diagnostic quantities

Record:

- Spearman correlation between delta_12h_short and delta_12h_long;
- Pearson correlation as a secondary descriptive quantity;
- proportion of genes with concordant non-zero effect direction;
- median absolute difference between the two 12-h effects.

## Interpretation boundary

The two 12-h groups originate from different studies/blocks.

Therefore this is a cross-study concordance diagnostic, not a replicated 12-h treatment experiment.

Strong concordance would support reproducibility of gene-level response direction/magnitude at the shared nominal exposure time despite study differences.

Weak concordance would indicate substantial study/block dependence and would require correspondingly cautious interpretation of UV instability.

This diagnostic cannot separate study effects from other experimental differences between the two UV series.

---

# 5. DES experimental structure

DES contains two predefined regimes:

Fast:
- control n = 3
- treatment n = 3

Slow:
- control n = 3
- treatment n = 3

The design is balanced but contains only three observations per subgroup-by-treatment cell.

---

# 6. DES small-sample sensitivity analysis

## Question

How sensitive is DES instability to individual observations when each subgroup-by-treatment cell contains only n = 3?

## Procedure

For each of the four cells:

- fast control
- fast treatment
- slow control
- slow treatment

remove one observation while retaining two observations in that cell.

All combinations are evaluated exhaustively.

Number of configurations:

3 x 3 x 3 x 3 = 81

Each reduced configuration therefore contains n = 2 in every subgroup-by-treatment cell.

Instability is recalculated using the unchanged core equations and weighting rule.

## Comparisons with full-data DES result

For every configuration calculate:

- Spearman correlation between full-data and reduced-data gene-level instability;
- top-decile overlap;
- top-decile Jaccard index;
- retention fraction of the original full-data top-decile genes;
- median instability;
- change in median instability relative to the full-data analysis.

No arbitrary PASS threshold is defined before observing the results.

---

# 7. What these analyses can and cannot establish

## Can evaluate

The analyses can determine:

1. whether UV instability is disproportionately dependent on an individual sampled treatment timepoint;
2. whether the two independent UV studies show concordant gene-level effects at their shared nominal 12-h exposure;
3. whether DES instability rankings are highly sensitive to individual observations at n = 3 per cell;
4. how stable high-instability gene rankings are under these predefined perturbations.

## Cannot establish

The analyses cannot:

1. remove the confounding between UV study/block and temporal exposure structure;
2. transform the two UV studies into a balanced common-time experiment;
3. treat the two independent 12-h UV groups as biological replicates;
4. establish that UV instability represents biological heterogeneity independently of temporal composition;
5. provide formal inferential significance or FDR values for the instability score itself.

These limitations must remain explicit in the revised manuscript and response to reviewers.

---

# 8. Prohibited post hoc modifications

The following changes are not permitted after observing the sensitivity results unless independently justified and explicitly documented:

- deleting selected UV timepoints merely to force equal short/long sample numbers;
- imposing equal 0.5/0.5 subgroup weights instead of the existing weighting rule;
- pooling the independent short-study and long-study 12-h groups;
- changing the instability equation;
- selecting only favorable sensitivity configurations;
- introducing an arbitrary robustness threshold after seeing the results;
- changing the primary DES significance threshold because FDR < 0.05 produces no formal interaction positives.

Adverse or ambiguous sensitivity results must be reported rather than optimized away.

---

# 9. Planned reproducibility artifacts

Final executable analysis:

`02_methods/R/reviewer_validation/03_subgroup_sample_size_sensitivity.R`

Planned output directory:

`04_results/reviewer_validation/subgroup_sensitivity/`

Required retained outputs:

1. UV leave-one-timepoint-out configuration-level results;
2. UV shared-12-h cross-study diagnostic;
3. DES 81-configuration sensitivity results;
4. concise sensitivity summary table.

The final reviewer-validation README must map these outputs to R2-C2 and R3-C1.

The revision ledger will be updated only after the analyses have been executed, checked, and scientifically interpreted.
