# R2-C2 / R3-C1 reviewer-validation result lock

## Status

ANALYSIS COMPLETE / SCIENTIFIC INTERPRETATION LOCKED

Administrative closure remains pending until:
- reviewer-response text is finalized;
- manuscript changes are finalized;
- revised line references are available;
- reviewer-driven changes are highlighted;
- revision ledger is updated.

## Design provenance

Design lock:
`02_methods/R/reviewer_validation/R2C2_R3C1_DESIGN_LOCK.md`

Design-lock SHA256:
`dc08727722230aafbda99d798f8e389b8617bbc74baa9502f8cc89f0f2f6567d`

Executable analysis:
`02_methods/R/reviewer_validation/03_subgroup_sample_size_sensitivity.R`

Script SHA256:
`6c91e52a4e32f4017acd0e48d7a05b3d52262f95051a56d5193b7582cbf57dd8`

---

# 1. Full-data subgroup weighting

UV:
- long: n = 21
- short: n = 27
- long weight = 0.4375
- short weight = 0.5625

DES:
- fast: n = 6
- slow: n = 6
- fast weight = 0.5
- slow weight = 0.5

These values reproduce the original sample-number weighting rule.

---

# 2. UV leave-one-treatment-timepoint-out sensitivity

Fourteen predefined perturbations were evaluated:
- eight omissions from the short-exposure study;
- six omissions from the long-exposure study.

All three biological replicates belonging to the selected treatment timepoint were removed together.
Controls were retained.
Instability was recalculated using the original equations and sample-number weighting.

## Results

Spearman correlation with full-data instability ranking:
- median = 0.983723633808958
- minimum = 0.961416488950252
- maximum = 0.991862345618051

Top-decile Jaccard:
- median = 0.875889228901569
- minimum = 0.796570076877587
- maximum = 0.916719242902208

Original full-data top-decile retention:
- median = 0.933838051349572
- minimum = 0.886767610269915
- maximum = 0.956550362080316

Full-data median instability:
- 0.427841928881106

Perturbed median instability:
- median = 0.424424393561961
- minimum = 0.404104902095549
- maximum = 0.468323985866138

## Worst perturbation

Omission:
- long-exposure study
- 24-h treatment timepoint
- three samples removed

Result:
- Spearman rho = 0.961416488950252
- top-decile Jaccard = 0.796570076877587
- original top-decile retention = 0.886767610269915
- full median instability = 0.427841928881106
- perturbed median instability = 0.468323985866138
- median change = +0.040482056985032

## Locked interpretation

The UV instability ranking is not disproportionately driven by any single sampled treatment timepoint.

This result demonstrates robustness to individual treatment-timepoint omission.

It does NOT establish independence from temporal composition and does NOT resolve confounding between study/block and exposure regime.

---

# 3. UV shared nominal 12-h cross-study diagnostic

The short- and long-exposure studies each contain:
- three independent 12-h treatment samples;
- three corresponding study-specific control samples.

The two 12-h groups originate from different studies and are not biological replicates of a single experiment.

## Results

Genes evaluated:
- 15,187

Spearman correlation:
- 0.345495919350833

Pearson correlation:
- 0.391296421003759

Genes with non-zero effects in both comparisons:
- 13,756

Directional concordance among genes non-zero in both:
- 0.627362605408549

Median absolute difference between short- and long-study 12-h effects:
- 0.419352833734218

## Locked interpretation

Gene-level effects at the shared nominal 12-h exposure show only modest cross-study concordance.

Therefore the 12-h diagnostic does not support treating the two UV studies as equivalent or replicated temporal experiments.

The result indicates that study/block and temporal-regime differences remain substantial.

Because study identity and temporal design are coupled in the available data, their separate contributions cannot be identified from this comparison.

---

# 4. DES exhaustive small-sample sensitivity

The original DES design contains:
- fast control n = 3
- fast treatment n = 3
- slow control n = 3
- slow treatment n = 3

One observation was removed from each of the four cells in every possible combination.

Total configurations:
- 81

Every reduced configuration therefore contains n = 2 per cell.

## Results

Spearman correlation with full-data instability ranking:
- median = 0.753591071414338
- minimum = 0.613788141583396
- maximum = 0.844356151452813

Top-decile Jaccard:
- median = 0.532022188603127
- minimum = 0.388482632541133
- maximum = 0.681239623685667

Original full-data top-decile retention:
- median = 0.694535878867676
- minimum = 0.559578670177749
- maximum = 0.810401579986834

Full-data median instability:
- 0.391937694175023

Perturbed median instability:
- median = 0.412373593230405
- minimum = 0.33063264321185
- maximum = 0.544161288481249

Largest absolute median-instability change:
- full = 0.391937694175023
- perturbed = 0.544161288481249
- change = +0.152223594306226

## Locked interpretation

DES retains moderate rank-level agreement under exhaustive reduction from n = 3 to n = 2 per subgroup-by-treatment cell.

However, individual gene rankings, top-decile membership, and instability magnitude show appreciable sensitivity to sample composition.

The DES analysis must therefore retain an explicit limitation concerning its small per-cell sample size.

The sensitivity results do not justify describing DES instability as strongly robust to small-sample perturbation.

---

# 5. Reviewer-facing scientific conclusions

## R2-C2

The reviewer concern is substantively valid.

The unequal UV sample numbers arise from the predefined experimental structure:
- short study: eight treatment timepoints;
- long study: six treatment timepoints.

No artificial balancing was performed.

Leave-one-timepoint-out analysis shows that the overall UV instability ranking is highly stable to omission of any single treatment timepoint.

However, study/block and temporal composition remain confounded.

The independent shared-12-h diagnostic shows only modest concordance between the two studies and therefore does not remove this limitation.

## R3-C1

The reviewer concern is also valid.

UV shows strong stability to treatment-timepoint omission.

DES, with only n = 3 per subgroup-by-treatment cell, shows moderate rather than strong stability under exhaustive n = 3 to n = 2 perturbation.

This limitation must be stated explicitly.

---

# 6. Permitted claims

Permitted:

- UV instability rankings were highly stable to omission of individual treatment timepoints.
- All 14 UV leave-one-timepoint-out analyses retained high rank correlation with the full-data result.
- UV study/block and temporal composition cannot be fully disentangled.
- The two independent UV studies showed only modest gene-level concordance at their shared nominal 12-h exposure.
- DES showed moderate rank stability under exhaustive small-sample perturbation.
- DES results are sensitive to limited replication and should be interpreted accordingly.

---

# 7. Prohibited claims

Do NOT claim:

- that UV temporal imbalance has been eliminated;
- that UV study effects have been controlled or separated from temporal effects;
- that the two UV 12-h groups are biological replicates;
- that the 12-h comparison demonstrates strong cross-study reproducibility;
- that UV instability has been proven independent of exposure time;
- that DES is strongly robust to small sample size;
- that sensitivity analysis provides inferential significance or FDR for instability;
- that unfavorable sensitivity results were excluded.

---

# 8. Retained output provenance

`des_n3_to_n2_per_cell_sensitivity.tsv`
SHA256:
`3f92131724477cf4c17595cfb2173860065bb34a8e842b6bdd921c184ccaff27`

`full_data_subgroup_weights.tsv`
SHA256:
`df51e49009903f695c162233068d23649ab805998b222423360d1e10b70227a9`

`subgroup_sample_size_sensitivity_summary.tsv`
SHA256:
`fb8325bf7c28adcb65674277f6713edb890863c126e7485f3e3d2b5a3f8b289d`

`uv_leave_one_timepoint_out_sensitivity.tsv`
SHA256:
`125ddebbf22ff4e27cf89b43e15aa19c42ae9ee18ba811dbc57884fb45d4d44c`

`uv_shared_12h_diagnostic_summary.tsv`
SHA256:
`6a58bbd520476359b7b5934c715a532c843e3c92d294294784dbb0b6ff6ca687`

`uv_shared_12h_gene_level_diagnostic.tsv`
SHA256:
`a4a170f1332b3e4dfebcf96f8529de987bf98454abba47b2d510a0c9682817bd`

---

# 9. Administrative status

R2-C2:
ANALYSIS PASS / SCIENTIFIC INTERPRETATION LOCKED / ADMINISTRATIVELY OPEN

R3-C1:
ANALYSIS PASS / SCIENTIFIC INTERPRETATION LOCKED / ADMINISTRATIVELY OPEN

Do not mark either comment CLOSED until manuscript text, reviewer response, highlighting, and exact revised line references are complete.
