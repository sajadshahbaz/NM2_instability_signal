#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(tibble)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
  stop(
    "Usage: 06_apply_nm2_expression_filter.R ",
    "vst_counts_all_groups.tsv x_count.csv out_dir"
  )
}

vst_file   <- args[1]
count_file <- args[2]
out_dir    <- args[3]

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# -------------------------------------------------------------------------
# Load VST matrix produced after the DESeq2 total-count eligibility filter.
# Expected historical dimensions: 19,270 genes x 111 samples.
# -------------------------------------------------------------------------

vst_df <- read_tsv(
  vst_file,
  show_col_types = FALSE,
  progress = FALSE
)

if (!"GeneID" %in% names(vst_df)) {
  stop("VST matrix must contain a GeneID column")
}

gene_id <- as.character(vst_df$GeneID)
vst <- as.matrix(vst_df[, setdiff(names(vst_df), "GeneID")])
rownames(vst) <- gene_id
storage.mode(vst) <- "double"

if (anyDuplicated(rownames(vst))) {
  stop("Duplicated GeneIDs detected in VST matrix")
}

# -------------------------------------------------------------------------
# QC eligibility.
#
# Historical reconstruction showed that all 19,270 genes passed both
# finite-value and non-zero-variance checks. These checks are retained
# explicitly because they were part of the filtering procedure.
# -------------------------------------------------------------------------

finite_ok <- apply(vst, 1, function(x) all(is.finite(x)))
sd_ok <- apply(vst, 1, function(x) sd(x) > 0)

qc_ok <- finite_ok & sd_ok

# -------------------------------------------------------------------------
# NM2 expression-prevalence filter.
#
# Retain genes with VST-transformed expression >= 5 in at least 20% of
# analytical samples.
# -------------------------------------------------------------------------

prevalence <- rowMeans(vst >= 5)
retain <- qc_ok & prevalence >= 0.20

retained_genes <- rownames(vst)[retain]
vst_filtered <- vst[retain, , drop = FALSE]

# Historical NM2 result: exactly 15,187 retained genes.
if (nrow(vst_filtered) != 15187) {
  stop(
    "Unexpected number of retained genes: ",
    nrow(vst_filtered),
    " (expected 15187)"
  )
}

# -------------------------------------------------------------------------
# Apply the identical retained GeneID set to the gene-level abundance matrix.
# x_count.csv contains the complete 19,495-gene tximport abundance matrix.
# -------------------------------------------------------------------------

count_df <- read.csv(
  count_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

if (!"GeneID" %in% names(count_df)) {
  stop("Count matrix must contain a GeneID column")
}

if (anyDuplicated(count_df$GeneID)) {
  stop("Duplicated GeneIDs detected in count matrix")
}

missing_counts <- setdiff(retained_genes, count_df$GeneID)

if (length(missing_counts) > 0) {
  stop(
    "Retained VST genes absent from count matrix: ",
    paste(head(missing_counts, 20), collapse = ", ")
  )
}

idx <- match(retained_genes, count_df$GeneID)
count_filtered <- count_df[idx, , drop = FALSE]

if (!identical(
  as.character(count_filtered$GeneID),
  retained_genes
)) {
  stop("Filtered count GeneID order does not match filtered VST GeneID order")
}

# -------------------------------------------------------------------------
# Write manuscript analytical inputs.
# -------------------------------------------------------------------------

write_tsv(
  as.data.frame(vst_filtered) |>
    rownames_to_column("GeneID"),
  file.path(out_dir, "vst_counts_filtered.tsv")
)

write.csv(
  count_filtered,
  file.path(out_dir, "x_count_filt.csv"),
  row.names = FALSE
)

filter_summary <- data.frame(
  stage = c(
    "input_vst",
    "finite_values",
    "nonzero_variance",
    "vst_ge_5_in_ge_20pct_samples"
  ),
  genes = c(
    nrow(vst),
    sum(finite_ok),
    sum(qc_ok),
    length(retained_genes)
  )
)

write_tsv(
  filter_summary,
  file.path(out_dir, "nm2_expression_filter_summary.tsv")
)

cat(
  sprintf(
    paste0(
      "PASS: NM2 expression filter retained %d/%d genes; ",
      "threshold VST >= 5 in >= 20%% of samples; ",
      "filtered count and VST GeneIDs are identical.\n"
    ),
    length(retained_genes),
    nrow(vst)
  )
)
