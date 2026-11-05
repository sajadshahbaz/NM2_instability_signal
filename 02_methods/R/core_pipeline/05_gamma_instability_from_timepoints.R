#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
})

root <- Sys.getenv("NM2_ROOT")

nm2_root <- Sys.getenv("NM2_ROOT")
if (nm2_root == "") nm2_root <- normalizePath(getwd(), mustWork = TRUE)

tp_file <- file.path(
  nm2_root,
  "01_data", "precomputed", "gamma", "gamma_timepoint_effects.tsv"
)

out_dir <- file.path(root, "04_results/tables")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

dt <- fread(tp_file)

dt <- dt[condition == "gamma"]

# keep only gene + logFC + timepoint
dt <- dt[, .(gene, logFC, timepoint)]

# compute metrics per gene
res <- dt[, {

  tp_vals <- logFC

  delta_pool <- mean(tp_vals)

  hetero_gap <- max(tp_vals) - min(tp_vals)

  sign_vec <- sign(tp_vals)
  discordance <- mean(sign_vec != sign(mean(tp_vals)))

  instability_score <- abs(hetero_gap) * (1 + discordance)

  var_proxy <- var(tp_vals)

  .(
    n_timepoints = .N,
    delta_pool = delta_pool,
    hetero_gap = hetero_gap,
    discordance = discordance,
    instability_score = instability_score,
    var_proxy = var_proxy
  )

}, by = gene]

fwrite(res,
       file.path(out_dir, "gam_pool_vs_strat_all.tsv"),
       sep="\t")

cat("Gamma instability table written\n")
