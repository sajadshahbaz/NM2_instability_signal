#!/usr/bin/env Rscript

# R2-C2 / R3-C1 reviewer validation
#
# DESIGN LOCK:
# 02_methods/R/reviewer_validation/R2C2_R3C1_DESIGN_LOCK.md
#
# Locked design SHA256:
# dc08727722230aafbda99d798f8e389b8617bbc74baa9502f8cc89f0f2f6567d
#
# Components:
#   A. UV leave-one-treatment-timepoint-out sensitivity (14 configurations)
#   B. UV shared nominal 12-h cross-study diagnostic
#   C. DES exhaustive n=3 -> n=2 per-cell sensitivity (81 configurations)
#
# This script DOES NOT:
#   - rebalance UV by deleting timepoints to equalize study sizes;
#   - impose equal subgroup weights;
#   - pool the two independent UV 12-h groups;
#   - alter the instability definition.
#
# The original sample-number weighting rule and instability equations are
# reproduced exactly from the core UV/DES implementation.

suppressPackageStartupMessages({
  library(data.table)
})

options(stringsAsFactors = FALSE)

# -------------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------------

nm2_root <- Sys.getenv("NM2_ROOT")
if (nm2_root == "") {
  stop("NM2_ROOT is not set", call. = FALSE)
}

config_file <- file.path(nm2_root, "00_config", "config.yaml")

core_script <- file.path(
  nm2_root,
  "02_methods/R/core_pipeline/01_pool_vs_strat_rebuild_uv_des.R"
)

design_lock <- file.path(
  nm2_root,
  "02_methods/R/reviewer_validation/R2C2_R3C1_DESIGN_LOCK.md"
)

expected_design_sha <- "dc08727722230aafbda99d798f8e389b8617bbc74baa9502f8cc89f0f2f6567d"

outdir <- file.path(
  nm2_root,
  "04_results/reviewer_validation/subgroup_sensitivity"
)

dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------

stop2 <- function(...) stop(sprintf(...), call. = FALSE)

sha256_file <- function(path) {
  cmd <- sprintf("sha256sum %s", shQuote(path))
  x <- system(cmd, intern = TRUE)
  strsplit(x[1], "[[:space:]]+")[[1]][1]
}

effect_delta <- function(X, treat_ids, ctrl_ids) {
  if (length(treat_ids) == 0L || length(ctrl_ids) == 0L) {
    stop2("Empty treatment or control set encountered.")
  }

  rowMeans(X[, treat_ids, drop = FALSE], na.rm = TRUE) -
    rowMeans(X[, ctrl_ids, drop = FALSE], na.rm = TRUE)
}

sign_eps <- function(x, eps = 1e-6) {
  out <- integer(length(x))
  out[x > eps] <- 1L
  out[x < -eps] <- -1L
  out
}

calc_instability <- function(m, X) {

  subs <- sort(unique(m$baseline_block))

  if (length(subs) != 2L) {
    stop2(
      "Expected exactly two baseline_block levels; observed: %s",
      paste(subs, collapse = ", ")
    )
  }

  s1 <- subs[1]
  s2 <- subs[2]

  m1 <- m[baseline_block == s1]
  m2 <- m[baseline_block == s2]

  treat_1 <- m1[group_type == "treatment", sample_id]
  ctrl_1  <- m1[group_type == "control", sample_id]

  treat_2 <- m2[group_type == "treatment", sample_id]
  ctrl_2  <- m2[group_type == "control", sample_id]

  treat_all <- m[group_type == "treatment", sample_id]
  ctrl_all  <- m[group_type == "control", sample_id]

  d1 <- effect_delta(X, treat_1, ctrl_1)
  d2 <- effect_delta(X, treat_2, ctrl_2)
  d_pool <- effect_delta(X, treat_all, ctrl_all)

  # Exact core weighting rule: treatment + control observations per subgroup.
  n1 <- length(treat_1) + length(ctrl_1)
  n2 <- length(treat_2) + length(ctrl_2)

  w1 <- n1 / (n1 + n2)
  w2 <- n2 / (n1 + n2)

  d_strat <- w1 * d1 + w2 * d2

  sgn1 <- sign_eps(d1)
  sgn2 <- sign_eps(d2)

  sign_flip <- (sgn1 != 0L) & (sgn2 != 0L) & (sgn1 != sgn2)

  hetero_gap <- abs(d1 - d2)
  discordance <- abs(d_pool - d_strat)
  instability <- hetero_gap + discordance

  data.table(
    feature = rownames(X),
    subgroup_1 = s1,
    subgroup_2 = s2,
    delta_1 = d1,
    delta_2 = d2,
    delta_pool = d_pool,
    delta_strat = d_strat,
    sign_flip = sign_flip,
    hetero_gap = hetero_gap,
    discordance = discordance,
    instability_score = instability,
    n1 = n1,
    n2 = n2,
    w1 = w1,
    w2 = w2
  )
}

compare_instability <- function(full, perturbed) {

  z <- merge(
    full[, .(feature, instability_full = instability_score)],
    perturbed[, .(feature, instability_perturbed = instability_score)],
    by = "feature"
  )

  if (nrow(z) == 0L) {
    stop2("No common genes in full/perturbed comparison.")
  }

  rho <- suppressWarnings(
    cor(
      z$instability_full,
      z$instability_perturbed,
      method = "spearman",
      use = "complete.obs"
    )
  )

  q90_full <- as.numeric(
    quantile(
      z$instability_full,
      probs = 0.90,
      na.rm = TRUE,
      names = FALSE
    )
  )

  q90_perturbed <- as.numeric(
    quantile(
      z$instability_perturbed,
      probs = 0.90,
      na.rm = TRUE,
      names = FALSE
    )
  )

  top_full <- z[
    instability_full >= q90_full,
    unique(feature)
  ]

  top_perturbed <- z[
    instability_perturbed >= q90_perturbed,
    unique(feature)
  ]

  common_top <- intersect(top_full, top_perturbed)
  union_top <- union(top_full, top_perturbed)

  list(
    n_genes = nrow(z),

    spearman_rho = rho,

    q90_full = q90_full,
    q90_perturbed = q90_perturbed,

    n_top_full = length(top_full),
    n_top_perturbed = length(top_perturbed),
    n_top_intersection = length(common_top),

    top_jaccard =
      if (length(union_top) > 0L)
        length(common_top) / length(union_top)
      else NA_real_,

    original_top_retention =
      if (length(top_full) > 0L)
        length(common_top) / length(top_full)
      else NA_real_,

    median_full =
      median(z$instability_full, na.rm = TRUE),

    median_perturbed =
      median(z$instability_perturbed, na.rm = TRUE)
  )
}

# -------------------------------------------------------------------------
# Validate design lock
# -------------------------------------------------------------------------

if (!file.exists(design_lock)) {
  stop2("Design-lock file missing: %s", design_lock)
}

observed_design_sha <- sha256_file(design_lock)

if (!identical(observed_design_sha, expected_design_sha)) {
  stop2(
    paste0(
      "DESIGN LOCK SHA256 MISMATCH.\n",
      "Expected: %s\n",
      "Observed: %s\n",
      "Refusing to run."
    ),
    expected_design_sha,
    observed_design_sha
  )
}

cat("Design-lock SHA256: PASS\n")

# -------------------------------------------------------------------------
# Load inputs through the same configuration contract as the core pipeline
# -------------------------------------------------------------------------

if (!file.exists(config_file)) {
  stop2("Configuration file missing: %s", config_file)
}

if (!file.exists(core_script)) {
  stop2("Core UV/DES script missing: %s", core_script)
}

read_config_simple <- function(path) {
  if (!file.exists(path)) {
    stop2("Config not found: %s", path)
  }

  x <- readLines(path, warn = FALSE)
  x <- gsub("#.*$", "", x)
  x <- x[nzchar(trimws(x))]

  kv <- list()

  for (ln in x) {
    if (!grepl(":", ln, fixed = TRUE)) next
    if (grepl("^\\s*[A-Za-z0-9_]+\\s*:\\s*$", ln)) next

    m <- regexec(
      "^\\s*([A-Za-z0-9_]+)\\s*:\\s*(.*)\\s*$",
      ln
    )

    r <- regmatches(ln, m)[[1]]

    if (length(r) != 3L) next

    key <- r[2]
    val <- r[3]
    val <- gsub('^"(.*)"$', "\\1", val)

    kv[[key]] <- val
  }

  kv
}

cfg <- read_config_simple(config_file)

vst_file <- cfg[["vst"]]
meta_file <- cfg[["meta"]]

sid_col  <- cfg[["sample_id_col"]]
cond_col <- cfg[["condition_col"]]
sub_col  <- cfg[["subgroup_col"]]
grp_col  <- cfg[["group_col"]]

required_cfg <- c(
  vst = vst_file,
  meta = meta_file,
  sample_id_col = sid_col,
  condition_col = cond_col,
  subgroup_col = sub_col,
  group_col = grp_col
)

if (any(vapply(required_cfg, is.null, logical(1)))) {
  stop2("Required core configuration key is missing.")
}

if (!file.exists(vst_file)) {
  stop2("Missing VST: %s", vst_file)
}

if (!file.exists(meta_file)) {
  stop2("Missing metadata: %s", meta_file)
}

cat("Config: ", config_file, "\n", sep = "")
cat("Metadata: ", meta_file, "\n", sep = "")
cat("VST input: ", vst_file, "\n", sep = "")

# -------------------------------------------------------------------------
# Load and validate data
# -------------------------------------------------------------------------

meta <- fread(meta_file)
vst <- fread(vst_file)

required_meta <- c(
  "sample_id",
  "condition",
  "group_type",
  "baseline_block",
  "timepoint"
)

missing_meta <- setdiff(required_meta, names(meta))

if (length(missing_meta) > 0L) {
  stop2(
    "Missing metadata columns: %s",
    paste(missing_meta, collapse = ", ")
  )
}

feature_col <- names(vst)[1]
features <- vst[[feature_col]]

X <- as.matrix(vst[, -1, with = FALSE])
storage.mode(X) <- "numeric"
rownames(X) <- features

common <- intersect(meta$sample_id, colnames(X))

if (length(common) == 0L) {
  stop2("No sample overlap between metadata and VST matrix.")
}

meta <- meta[sample_id %in% common]

uv_meta <- meta[tolower(condition) == "uv"]
des_meta <- meta[tolower(condition) == "des"]

if (nrow(uv_meta) != 48L) {
  stop2("Expected 48 UV samples; observed %d.", nrow(uv_meta))
}

if (nrow(des_meta) != 12L) {
  stop2("Expected 12 DES samples; observed %d.", nrow(des_meta))
}

# -------------------------------------------------------------------------
# Validate UV structure before computation
# -------------------------------------------------------------------------

uv_short_treat <- uv_meta[
  baseline_block == "short" & group_type == "treatment"
]

uv_long_treat <- uv_meta[
  baseline_block == "long" & group_type == "treatment"
]

uv_short_ctrl <- uv_meta[
  baseline_block == "short" & group_type == "control"
]

uv_long_ctrl <- uv_meta[
  baseline_block == "long" & group_type == "control"
]

short_timepoints <- sort(unique(uv_short_treat$timepoint))
long_timepoints <- sort(unique(uv_long_treat$timepoint))

if (length(short_timepoints) != 8L) {
  stop2(
    "Expected 8 short UV treatment timepoints; observed %d.",
    length(short_timepoints)
  )
}

if (length(long_timepoints) != 6L) {
  stop2(
    "Expected 6 long UV treatment timepoints; observed %d.",
    length(long_timepoints)
  )
}

if (nrow(uv_short_ctrl) != 3L || nrow(uv_long_ctrl) != 3L) {
  stop2("Expected three controls in each UV study/block.")
}

short_counts <- uv_short_treat[, .N, by = timepoint]
long_counts <- uv_long_treat[, .N, by = timepoint]

if (any(short_counts$N != 3L) || any(long_counts$N != 3L)) {
  stop2("Expected three replicates per UV treatment timepoint.")
}

if (
  !("12h" %in% short_timepoints) ||
  !("12h" %in% long_timepoints)
) {
  stop2(
    "Expected independent 12h treatment groups in both UV studies."
  )
}

cat(
  sprintf(
    "UV structure: PASS (%d short + %d long treatment timepoints)\n",
    length(short_timepoints),
    length(long_timepoints)
  )
)

# -------------------------------------------------------------------------
# Validate DES structure
# -------------------------------------------------------------------------

des_counts <- des_meta[
  ,
  .N,
  by = .(baseline_block, group_type)
]

required_des_cells <- CJ(
  baseline_block = c("fast", "slow"),
  group_type = c("control", "treatment")
)

des_check <- merge(
  required_des_cells,
  des_counts,
  by = c("baseline_block", "group_type"),
  all.x = TRUE
)

if (
  nrow(des_check) != 4L ||
  any(is.na(des_check$N)) ||
  any(des_check$N != 3L)
) {
  stop2("Expected DES n=3 in each of four subgroup-by-treatment cells.")
}

cat("DES structure: PASS (n=3 in each of four cells)\n")

# -------------------------------------------------------------------------
# Full-data reference calculations
# -------------------------------------------------------------------------

uv_full <- calc_instability(uv_meta, X)
des_full <- calc_instability(des_meta, X)

# Save reference weighting for provenance.
reference_weights <- rbind(
  data.table(
    condition = "UV",
    subgroup_1 = uv_full$subgroup_1[1],
    subgroup_2 = uv_full$subgroup_2[1],
    n1 = uv_full$n1[1],
    n2 = uv_full$n2[1],
    w1 = uv_full$w1[1],
    w2 = uv_full$w2[1]
  ),
  data.table(
    condition = "DES",
    subgroup_1 = des_full$subgroup_1[1],
    subgroup_2 = des_full$subgroup_2[1],
    n1 = des_full$n1[1],
    n2 = des_full$n2[1],
    w1 = des_full$w1[1],
    w2 = des_full$w2[1]
  )
)

# -------------------------------------------------------------------------
# A. UV leave-one-treatment-timepoint-out sensitivity
# -------------------------------------------------------------------------

uv_loto <- list()
idx <- 1L

for (study in c("short", "long")) {

  tps <- if (study == "short") {
    short_timepoints
  } else {
    long_timepoints
  }

  for (tp in tps) {

    # Remove all three treatment replicates at exactly one timepoint.
    remove_ids <- uv_meta[
      baseline_block == study &
        group_type == "treatment" &
        timepoint == tp,
      sample_id
    ]

    if (length(remove_ids) != 3L) {
      stop2(
        "Expected three samples for UV %s %s; observed %d.",
        study,
        tp,
        length(remove_ids)
      )
    }

    reduced_meta <- uv_meta[!sample_id %in% remove_ids]

    # Controls must remain unchanged.
    if (
      reduced_meta[
        baseline_block == "short" &
          group_type == "control",
        .N
      ] != 3L ||
      reduced_meta[
        baseline_block == "long" &
          group_type == "control",
        .N
      ] != 3L
    ) {
      stop2("UV control count changed unexpectedly.")
    }

    reduced <- calc_instability(reduced_meta, X)
    cmp <- compare_instability(uv_full, reduced)

    uv_loto[[idx]] <- data.table(
      configuration = idx,
      omitted_study = study,
      omitted_timepoint = tp,
      n_samples_removed = length(remove_ids),

      subgroup_1 = reduced$subgroup_1[1],
      subgroup_2 = reduced$subgroup_2[1],
      n1 = reduced$n1[1],
      n2 = reduced$n2[1],
      w1 = reduced$w1[1],
      w2 = reduced$w2[1],

      n_genes = cmp$n_genes,
      spearman_rho = cmp$spearman_rho,

      q90_full = cmp$q90_full,
      q90_perturbed = cmp$q90_perturbed,

      n_top_full = cmp$n_top_full,
      n_top_perturbed = cmp$n_top_perturbed,
      n_top_intersection = cmp$n_top_intersection,
      top_jaccard = cmp$top_jaccard,
      original_top_retention = cmp$original_top_retention,

      median_full = cmp$median_full,
      median_perturbed = cmp$median_perturbed,
      median_change =
        cmp$median_perturbed - cmp$median_full
    )

    idx <- idx + 1L
  }
}

uv_loto <- rbindlist(uv_loto)

if (nrow(uv_loto) != 14L) {
  stop2(
    "Expected 14 UV leave-one-timepoint-out configurations; observed %d.",
    nrow(uv_loto)
  )
}

# -------------------------------------------------------------------------
# B. UV shared nominal 12-h cross-study diagnostic
# -------------------------------------------------------------------------

short_12_treat <- uv_meta[
  baseline_block == "short" &
    group_type == "treatment" &
    timepoint == "12h",
  sample_id
]

long_12_treat <- uv_meta[
  baseline_block == "long" &
    group_type == "treatment" &
    timepoint == "12h",
  sample_id
]

short_ctrl <- uv_meta[
  baseline_block == "short" &
    group_type == "control",
  sample_id
]

long_ctrl <- uv_meta[
  baseline_block == "long" &
    group_type == "control",
  sample_id
]

if (
  length(short_12_treat) != 3L ||
  length(long_12_treat) != 3L ||
  length(short_ctrl) != 3L ||
  length(long_ctrl) != 3L
) {
  stop2("Unexpected sample counts for UV shared-12h diagnostic.")
}

delta_12_short <- effect_delta(
  X,
  short_12_treat,
  short_ctrl
)

delta_12_long <- effect_delta(
  X,
  long_12_treat,
  long_ctrl
)

eps <- 1e-6

sgn_short <- sign_eps(delta_12_short, eps)
sgn_long <- sign_eps(delta_12_long, eps)

both_nonzero <- (sgn_short != 0L) & (sgn_long != 0L)

direction_concordant <- rep(NA, length(both_nonzero))
direction_concordant[both_nonzero] <-
  sgn_short[both_nonzero] == sgn_long[both_nonzero]

shared12_gene_table <- data.table(
  feature = rownames(X),
  delta_12h_short = delta_12_short,
  delta_12h_long = delta_12_long,
  absolute_difference =
    abs(delta_12_short - delta_12_long),
  direction_short = sgn_short,
  direction_long = sgn_long,
  both_nonzero = both_nonzero,
  direction_concordant = direction_concordant
)

shared12_summary <- data.table(
  n_genes = nrow(shared12_gene_table),

  n_short_12h = length(short_12_treat),
  n_long_12h = length(long_12_treat),
  n_short_control = length(short_ctrl),
  n_long_control = length(long_ctrl),

  spearman_rho = suppressWarnings(
    cor(
      delta_12_short,
      delta_12_long,
      method = "spearman",
      use = "complete.obs"
    )
  ),

  pearson_r = suppressWarnings(
    cor(
      delta_12_short,
      delta_12_long,
      method = "pearson",
      use = "complete.obs"
    )
  ),

  n_both_nonzero = sum(both_nonzero, na.rm = TRUE),

  direction_concordance_fraction =
    if (sum(both_nonzero, na.rm = TRUE) > 0L)
      mean(direction_concordant[both_nonzero], na.rm = TRUE)
    else NA_real_,

  median_absolute_difference = median(
    abs(delta_12_short - delta_12_long),
    na.rm = TRUE
  )
)

# -------------------------------------------------------------------------
# C. DES exhaustive n=3 -> n=2 per-cell sensitivity
# -------------------------------------------------------------------------

des_cells <- list(
  fast_control = des_meta[
    baseline_block == "fast" &
      group_type == "control",
    sample_id
  ],

  fast_treatment = des_meta[
    baseline_block == "fast" &
      group_type == "treatment",
    sample_id
  ],

  slow_control = des_meta[
    baseline_block == "slow" &
      group_type == "control",
    sample_id
  ],

  slow_treatment = des_meta[
    baseline_block == "slow" &
      group_type == "treatment",
    sample_id
  ]
)

if (!all(vapply(des_cells, length, integer(1)) == 3L)) {
  stop2("DES cell validation failed before exhaustive sensitivity.")
}

drop_grid <- expand.grid(
  dropped_fast_control = des_cells$fast_control,
  dropped_fast_treatment = des_cells$fast_treatment,
  dropped_slow_control = des_cells$slow_control,
  dropped_slow_treatment = des_cells$slow_treatment,
  stringsAsFactors = FALSE
)

if (nrow(drop_grid) != 81L) {
  stop2(
    "Expected 81 DES configurations; observed %d.",
    nrow(drop_grid)
  )
}

des_sensitivity <- vector("list", nrow(drop_grid))

for (i in seq_len(nrow(drop_grid))) {

  dropped <- unlist(
    drop_grid[i, , drop = FALSE],
    use.names = FALSE
  )

  if (length(unique(dropped)) != 4L) {
    stop2(
      "DES configuration %d does not contain four unique dropped samples.",
      i
    )
  }

  reduced_meta <- des_meta[!sample_id %in% dropped]

  reduced_counts <- reduced_meta[
    ,
    .N,
    by = .(baseline_block, group_type)
  ]

  if (
    nrow(reduced_counts) != 4L ||
    any(reduced_counts$N != 2L)
  ) {
    stop2(
      "DES configuration %d failed n=2/cell validation.",
      i
    )
  }

  reduced <- calc_instability(reduced_meta, X)
  cmp <- compare_instability(des_full, reduced)

  des_sensitivity[[i]] <- data.table(
    configuration = i,

    dropped_fast_control =
      drop_grid$dropped_fast_control[i],

    dropped_fast_treatment =
      drop_grid$dropped_fast_treatment[i],

    dropped_slow_control =
      drop_grid$dropped_slow_control[i],

    dropped_slow_treatment =
      drop_grid$dropped_slow_treatment[i],

    n_per_cell = 2L,

    subgroup_1 = reduced$subgroup_1[1],
    subgroup_2 = reduced$subgroup_2[1],
    n1 = reduced$n1[1],
    n2 = reduced$n2[1],
    w1 = reduced$w1[1],
    w2 = reduced$w2[1],

    n_genes = cmp$n_genes,
    spearman_rho = cmp$spearman_rho,

    q90_full = cmp$q90_full,
    q90_perturbed = cmp$q90_perturbed,

    n_top_full = cmp$n_top_full,
    n_top_perturbed = cmp$n_top_perturbed,
    n_top_intersection = cmp$n_top_intersection,
    top_jaccard = cmp$top_jaccard,
    original_top_retention = cmp$original_top_retention,

    median_full = cmp$median_full,
    median_perturbed = cmp$median_perturbed,
    median_change =
      cmp$median_perturbed - cmp$median_full
  )
}

des_sensitivity <- rbindlist(des_sensitivity)

# -------------------------------------------------------------------------
# Summaries
# -------------------------------------------------------------------------

range_summary <- function(x) {
  c(
    median = median(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE),
    max = max(x, na.rm = TRUE)
  )
}

uv_rho <- range_summary(uv_loto$spearman_rho)
uv_jac <- range_summary(uv_loto$top_jaccard)
uv_ret <- range_summary(uv_loto$original_top_retention)
uv_med <- range_summary(uv_loto$median_perturbed)

des_rho <- range_summary(des_sensitivity$spearman_rho)
des_jac <- range_summary(des_sensitivity$top_jaccard)
des_ret <- range_summary(des_sensitivity$original_top_retention)
des_med <- range_summary(des_sensitivity$median_perturbed)

sensitivity_summary <- rbind(
  data.table(
    condition = "UV",
    analysis =
      "leave-one-treatment-timepoint-out",
    n_configurations = nrow(uv_loto),

    spearman_median = uv_rho["median"],
    spearman_min = uv_rho["min"],
    spearman_max = uv_rho["max"],

    top_jaccard_median = uv_jac["median"],
    top_jaccard_min = uv_jac["min"],
    top_jaccard_max = uv_jac["max"],

    original_top_retention_median = uv_ret["median"],
    original_top_retention_min = uv_ret["min"],
    original_top_retention_max = uv_ret["max"],

    median_instability_full =
      unique(uv_loto$median_full)[1],

    median_instability_perturbed_median =
      uv_med["median"],

    median_instability_perturbed_min =
      uv_med["min"],

    median_instability_perturbed_max =
      uv_med["max"]
  ),

  data.table(
    condition = "DES",
    analysis =
      "exhaustive-n3-to-n2-per-cell",
    n_configurations = nrow(des_sensitivity),

    spearman_median = des_rho["median"],
    spearman_min = des_rho["min"],
    spearman_max = des_rho["max"],

    top_jaccard_median = des_jac["median"],
    top_jaccard_min = des_jac["min"],
    top_jaccard_max = des_jac["max"],

    original_top_retention_median = des_ret["median"],
    original_top_retention_min = des_ret["min"],
    original_top_retention_max = des_ret["max"],

    median_instability_full =
      unique(des_sensitivity$median_full)[1],

    median_instability_perturbed_median =
      des_med["median"],

    median_instability_perturbed_min =
      des_med["min"],

    median_instability_perturbed_max =
      des_med["max"]
  ),
  fill = TRUE
)

# -------------------------------------------------------------------------
# Write outputs
# -------------------------------------------------------------------------

fwrite(
  reference_weights,
  file.path(
    outdir,
    "full_data_subgroup_weights.tsv"
  ),
  sep = "\t"
)

fwrite(
  uv_loto,
  file.path(
    outdir,
    "uv_leave_one_timepoint_out_sensitivity.tsv"
  ),
  sep = "\t"
)

fwrite(
  shared12_gene_table,
  file.path(
    outdir,
    "uv_shared_12h_gene_level_diagnostic.tsv"
  ),
  sep = "\t"
)

fwrite(
  shared12_summary,
  file.path(
    outdir,
    "uv_shared_12h_diagnostic_summary.tsv"
  ),
  sep = "\t"
)

fwrite(
  des_sensitivity,
  file.path(
    outdir,
    "des_n3_to_n2_per_cell_sensitivity.tsv"
  ),
  sep = "\t"
)

fwrite(
  sensitivity_summary,
  file.path(
    outdir,
    "subgroup_sample_size_sensitivity_summary.tsv"
  ),
  sep = "\t"
)

# -------------------------------------------------------------------------
# Console report
# -------------------------------------------------------------------------

cat("\nR2-C2 / R3-C1 REVIEWER SENSITIVITY VALIDATION\n")
cat("==============================================\n\n")

cat("FULL-DATA WEIGHTS\n")
print(reference_weights)

cat("\nUV LEAVE-ONE-TIMEPOINT-OUT SUMMARY\n")
print(sensitivity_summary[condition == "UV"])

cat("\nUV SHARED 12-h CROSS-STUDY DIAGNOSTIC\n")
print(shared12_summary)

cat("\nDES n=3 -> n=2/CELL SUMMARY\n")
print(sensitivity_summary[condition == "DES"])

cat(
  "\nOutputs written to:\n",
  outdir,
  "\n",
  sep = ""
)

cat(
  "\nIMPORTANT INTERPRETATION BOUNDARY:\n",
  "UV study/block and temporal composition remain confounded. ",
  "The sensitivity analyses do not remove that limitation.\n",
  sep = ""
)
