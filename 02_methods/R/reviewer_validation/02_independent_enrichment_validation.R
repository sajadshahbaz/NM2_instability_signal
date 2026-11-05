#!/usr/bin/env Rscript

# R2-C4 reviewer validation:
# Tests whether genes in the top 10% of instability are enriched for
# independently defined formal heterogeneity evidence (FDR < 0.05).
#
# This analysis does not alter the core instability calculation.

options(stringsAsFactors = FALSE)

outdir <- "04_results/reviewer_validation/formal_interaction"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

files <- list(
  UV  = file.path(outdir, "uv_formal_interaction.tsv"),
  DES = file.path(outdir, "des_formal_interaction.tsv"),
  GAM = file.path(outdir, "gam_formal_temporal_heterogeneity.tsv")
)

results <- list()
gene_tables <- list()

for (cond in names(files)) {

  d <- read.delim(
    files[[cond]],
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  fdr_col <- if (cond == "GAM") "temporal_FDR" else "interaction_FDR"

  required <- c("GeneID", fdr_col, "instability")
  missing_cols <- setdiff(required, colnames(d))

  if (length(missing_cols) > 0) {
    stop(
      cond, ": missing required columns: ",
      paste(missing_cols, collapse = ", ")
    )
  }

  if (anyDuplicated(d$GeneID)) {
    stop(cond, ": duplicated GeneID values detected.")
  }

  if (any(!is.finite(d$instability))) {
    stop(cond, ": non-finite instability values detected.")
  }

  if (any(!is.finite(d[[fdr_col]]))) {
    stop(cond, ": non-finite formal FDR values detected.")
  }

  # Top decile defined condition-specifically from the complete analytical
  # universe. Using >= preserves all genes tied at the Q90 boundary.
  q90 <- unname(quantile(
    d$instability,
    probs = 0.90,
    na.rm = FALSE,
    type = 7
  ))

  d$top10_instability <- d$instability >= q90
  d$formal_FDR05 <- d[[fdr_col]] < 0.05

  # Rows = top-decile status; columns = formal FDR status.
  tab <- table(
    top10 = d$top10_instability,
    formal = d$formal_FDR05
  )

  # Force explicit 2 x 2 representation even if one outcome class is absent.
  a <- sum(d$top10_instability & d$formal_FDR05)
  b <- sum(d$top10_instability & !d$formal_FDR05)
  c <- sum(!d$top10_instability & d$formal_FDR05)
  dd <- sum(!d$top10_instability & !d$formal_FDR05)

  formal_total <- a + c
  top_total <- a + b

  if (formal_total == 0L) {
    # Fisher enrichment is not informative when the independent outcome
    # contains no positive genes.
    odds_ratio <- NA_real_
    fisher_p <- NA_real_
    ci_low <- NA_real_
    ci_high <- NA_real_
    test_status <- "NON-INFORMATIVE: zero genes at formal FDR < 0.05"
  } else {
    ft <- fisher.test(
      matrix(
        c(a, b, c, dd),
        nrow = 2,
        byrow = TRUE,
        dimnames = list(
          instability = c("top10", "remaining"),
          formal = c("FDR_lt_0.05", "FDR_ge_0.05")
        )
      ),
      alternative = "greater"
    )

    odds_ratio <- unname(ft$estimate)
    fisher_p <- ft$p.value
    ci_low <- unname(ft$conf.int[1])
    ci_high <- unname(ft$conf.int[2])
    test_status <- "TESTED"
  }

  results[[cond]] <- data.frame(
    condition = cond,
    n_genes = nrow(d),
    instability_q90 = q90,
    n_top10 = top_total,
    n_formal_FDR05 = formal_total,
    top10_formal_FDR05 = a,
    top10_not_formal = b,
    remaining_formal_FDR05 = c,
    remaining_not_formal = dd,
    formal_fraction_top10 = if (top_total > 0) a / top_total else NA_real_,
    formal_fraction_remaining =
      if ((c + dd) > 0) c / (c + dd) else NA_real_,
    odds_ratio = odds_ratio,
    fisher_p_greater = fisher_p,
    fisher_CI_low = ci_low,
    fisher_CI_high = ci_high,
    test_status = test_status,
    stringsAsFactors = FALSE
  )

  gene_tables[[cond]] <- d[, c(
    "GeneID",
    "instability",
    fdr_col,
    "top10_instability",
    "formal_FDR05"
  )]
}

summary_df <- do.call(rbind, results)
rownames(summary_df) <- NULL

summary_file <- file.path(
  outdir,
  "independent_formal_enrichment_summary.tsv"
)

write.table(
  summary_df,
  summary_file,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

for (cond in names(gene_tables)) {
  write.table(
    gene_tables[[cond]],
    file.path(
      outdir,
      paste0(tolower(cond), "_independent_enrichment_gene_table.tsv")
    ),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
  )
}

cat("\nR2-C4 INDEPENDENT ENRICHMENT VALIDATION\n")
cat("=======================================\n\n")
print(summary_df, row.names = FALSE)
cat("\nSummary written to:\n", summary_file, "\n")
