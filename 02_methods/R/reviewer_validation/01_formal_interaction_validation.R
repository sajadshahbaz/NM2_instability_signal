#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(limma)
})

root <- Sys.getenv("NM2_ROOT", unset = getwd())

vst_file <- file.path(root, "01_data/processed/vst_counts_filtered.tsv")
meta_file <- file.path(root, "01_data/metadata/Simplified_Metadata_Table.core.csv")
uv_inst_file <- file.path(root, "04_results/tables/uv_pool_vs_strat_all.tsv")
des_inst_file <- file.path(root, "04_results/tables/des_pool_vs_strat_all.tsv")
gam_inst_file <- file.path(root, "04_results/tables/gam_pool_vs_strat_all.tsv")

outdir <- file.path(root, "04_results/reviewer_validation/formal_interaction")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

vst <- fread(vst_file)
meta <- fread(meta_file)

stopifnot(names(vst)[1] == "GeneID")
genes <- vst$GeneID
expr <- as.matrix(vst[, -1])
rownames(expr) <- genes

stopifnot(all(meta$sample_id %in% colnames(expr)))

fit_two_by_two <- function(condition_name, block_levels, instability_file) {

  m <- meta[condition == condition_name]
  m[, treatment := factor(group_type, levels = c("control", "treatment"))]
  m[, block := factor(baseline_block, levels = block_levels)]

  x <- expr[, m$sample_id, drop = FALSE]

  design <- model.matrix(~ treatment * block, data = m)

  if (qr(design)$rank != ncol(design)) {
    stop(condition_name, ": design matrix is not full rank")
  }

  fit <- eBayes(lmFit(x, design))

  interaction_coef <- grep("treatment.*:block|block.*:treatment",
                           colnames(design), value = TRUE)

  if (length(interaction_coef) != 1L) {
    stop(condition_name, ": expected exactly one interaction coefficient; found ",
         paste(interaction_coef, collapse = ", "))
  }

  tt <- topTable(
    fit,
    coef = interaction_coef,
    number = Inf,
    sort.by = "none",
    adjust.method = "BH"
  )

  out <- data.table(
    GeneID = rownames(tt),
    interaction_logFC = tt$logFC,
    interaction_t = tt$t,
    interaction_p = tt$P.Value,
    interaction_FDR = tt$adj.P.Val
  )

  inst <- fread(instability_file)

  gene_col <- intersect(c("GeneID", "feature", "gene", "gene_id"), names(inst))
  if (length(gene_col) != 1L)
    stop(condition_name, ": cannot uniquely identify gene column in instability table")

  if (!"instability_score" %in% names(inst))
    stop(condition_name, ": instability_score column absent")

  setnames(inst, gene_col, "GeneID")

  merged <- merge(
    out,
    inst[, .(GeneID, instability = instability_score)],
    by = "GeneID",
    all.x = TRUE,
    sort = FALSE
  )

  if (anyNA(merged$instability))
    stop(condition_name, ": missing instability values after merge")

  fwrite(
    merged,
    file.path(outdir, paste0(condition_name, "_formal_interaction.tsv")),
    sep = "\t"
  )

  data.table(
    condition = condition_name,
    n_samples = nrow(m),
    n_genes = nrow(merged),
    interaction_coefficient = interaction_coef,
    n_FDR_0.05 = sum(merged$interaction_FDR < 0.05, na.rm = TRUE),
    n_FDR_0.10 = sum(merged$interaction_FDR < 0.10, na.rm = TRUE),
    spearman_instability_abs_t =
      cor(merged$instability,
          abs(merged$interaction_t),
          method = "spearman",
          use = "complete.obs"),
    spearman_instability_neglog10p =
      cor(merged$instability,
          -log10(pmax(merged$interaction_p, .Machine$double.xmin)),
          method = "spearman",
          use = "complete.obs")
  )
}

uv_summary <- fit_two_by_two(
  "uv",
  c("short", "long"),
  uv_inst_file
)

des_summary <- fit_two_by_two(
  "des",
  c("fast", "slow"),
  des_inst_file
)

# ------------------------------------------------------------
# GAM temporal heterogeneity
#
# A treatment-by-time interaction is not identifiable because
# controls occur only at 00h and all later timepoints are treated.
# We therefore fit timepoint as a categorical factor and perform
# an omnibus moderated F-test for heterogeneity among the eight
# treated timepoints.
# ------------------------------------------------------------

gam <- meta[condition == "gam"]
gam_levels <- c("00h", "04h", "06h", "09h", "12h",
                "15h", "18h", "21h", "24h")

gam[, time := factor(timepoint, levels = gam_levels)]

xg <- expr[, gam$sample_id, drop = FALSE]

design_gam <- model.matrix(~ 0 + time, data = gam)

# Use syntactically valid coefficient names for limma contrasts.
# Original biological labels are retained through the T-prefix:
# 00h -> T00h, 04h -> T04h, ..., 24h -> T24h.
colnames(design_gam) <- paste0(
  "T",
  sub("^time", "", colnames(design_gam))
)

if (qr(design_gam)$rank != ncol(design_gam))
  stop("GAM: design matrix is not full rank")

fit_gam <- lmFit(xg, design_gam)

treated_times <- paste0("T", gam_levels[-1])

# Seven independent contrasts spanning temporal differences
# among the eight treated timepoints.
contrast_strings <- paste0(treated_times[-1], "-", treated_times[1])

C <- makeContrasts(
  contrasts = contrast_strings,
  levels = design_gam
)

fit_gam_temporal <- eBayes(contrasts.fit(fit_gam, C))

gam_tt <- topTable(
  fit_gam_temporal,
  coef = seq_len(ncol(C)),
  number = Inf,
  sort.by = "none",
  adjust.method = "BH"
)

gam_out <- data.table(
  GeneID = rownames(gam_tt),
  temporal_F = gam_tt$F,
  temporal_p = gam_tt$P.Value,
  temporal_FDR = gam_tt$adj.P.Val
)

gam_inst <- fread(gam_inst_file)
gam_gene_col <- intersect(c("GeneID", "feature", "gene", "gene_id"), names(gam_inst))

if (length(gam_gene_col) != 1L)
  stop("GAM: cannot uniquely identify gene column in instability table")

if (!"instability_score" %in% names(gam_inst))
  stop("GAM: instability_score column absent")

setnames(gam_inst, gam_gene_col, "GeneID")

gam_merged <- merge(
  gam_out,
  gam_inst[, .(GeneID, instability = instability_score)],
  by = "GeneID",
  all = FALSE,
  sort = FALSE
)

if (nrow(gam_merged) != nrow(gam_inst))
  stop(
    "GAM: formal-model/instability intersection does not match ",
    "the established GAM analytical gene set"
  )

if (anyNA(gam_merged$instability))
  stop("GAM: missing instability values after intersection")

fwrite(
  gam_merged,
  file.path(outdir, "gam_formal_temporal_heterogeneity.tsv"),
  sep = "\t"
)

gam_summary <- data.table(
  condition = "gam",
  n_samples = nrow(gam),
  n_genes = nrow(gam_merged),
  interaction_coefficient = "omnibus treated-timepoint heterogeneity",
  n_FDR_0.05 = sum(gam_merged$temporal_FDR < 0.05, na.rm = TRUE),
  n_FDR_0.10 = sum(gam_merged$temporal_FDR < 0.10, na.rm = TRUE),
  spearman_instability_abs_t =
    cor(gam_merged$instability,
        gam_merged$temporal_F,
        method = "spearman",
        use = "complete.obs"),
  spearman_instability_neglog10p =
    cor(gam_merged$instability,
        -log10(pmax(gam_merged$temporal_p, .Machine$double.xmin)),
        method = "spearman",
        use = "complete.obs")
)

summary_table <- rbind(
  uv_summary,
  des_summary,
  gam_summary,
  fill = TRUE
)

fwrite(
  summary_table,
  file.path(outdir, "formal_interaction_validation_summary.tsv"),
  sep = "\t"
)

cat("\n===== FORMAL INTERACTION / TEMPORAL VALIDATION =====\n")
print(summary_table)
cat("\nOutputs:", outdir, "\n")
