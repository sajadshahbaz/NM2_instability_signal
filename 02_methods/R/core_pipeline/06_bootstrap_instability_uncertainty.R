#!/usr/bin/env Rscript
# NM2 final-framework bootstrap uncertainty analysis
# Purpose: uncertainty of masked-gene fractions under the FINAL manuscript definitions.
# This is a validation layer; it does not alter the frozen observed-data core pipeline.

suppressPackageStartupMessages(library(data.table))

B_PRIMARY <- 500L
B_CHECK   <- 200L
SEED      <- 1L
EPS       <- 1e-6

root <- Sys.getenv("NM2_ROOT")
if (root == "") stop("NM2_ROOT is not set")

vst_file  <- file.path(root, "01_data", "processed", "vst_counts_filtered.tsv")
meta_file <- file.path(root, "01_data", "metadata", "Simplified_Metadata_Table.core.csv")
out_dir   <- file.path(root, "04_results", "validation", "bootstrap_uncertainty")
dir.create(out_dir, recursive=TRUE, showWarnings=FALSE)

vst <- fread(vst_file)
genes <- vst[[1]]
X <- as.matrix(vst[, -1])
mode(X) <- "numeric"
rownames(X) <- genes
colnames(X) <- names(vst)[-1]

meta <- fread(meta_file)
for (z in c("sample_id","condition","group_type","timepoint","baseline_block"))
  set(meta, j=z, value=tolower(trimws(as.character(meta[[z]]))))
# restore sample IDs to exact VST column spelling
sid_map <- setNames(colnames(X), tolower(colnames(X)))
meta[, sample_id := sid_map[sample_id]]

mean_effect <- function(tids, cids) {
  rowMeans(X[, tids, drop=FALSE]) - rowMeans(X[, cids, drop=FALSE])
}
rs <- function(ids) sample(ids, length(ids), replace=TRUE)

boot_subgroup <- function(cond, subs) {
  m <- meta[condition == cond]
  d <- list(); sampled_t <- character(); sampled_c <- character(); n <- numeric()
  for (k in seq_along(subs)) {
    mm <- m[baseline_block == subs[k]]
    t0 <- mm[group_type=="treatment", sample_id]
    c0 <- mm[group_type=="control", sample_id]
    tt <- rs(t0); cc <- rs(c0)
    d[[k]] <- mean_effect(tt, cc)
    sampled_t <- c(sampled_t, tt); sampled_c <- c(sampled_c, cc)
    n[k] <- length(t0)+length(c0)
  }
  dpool <- mean_effect(sampled_t, sampled_c)
  dstrat <- (n[1]*d[[1]] + n[2]*d[[2]]) / sum(n)
  inst <- abs(d[[1]]-d[[2]]) + abs(dpool-dstrat)
  list(pool=dpool, inst=inst)
}

boot_gam <- function() {
  m <- meta[condition=="gam"]
  ctrl0 <- m[group_type=="control", sample_id]
  cc <- rs(ctrl0)  # shared resampled baseline within replicate
  cm <- rowMeans(X[, cc, drop=FALSE])
  tps <- sort(unique(m[group_type=="treatment", timepoint]))
  E <- sapply(tps, function(tp) {
    ids <- m[group_type=="treatment" & timepoint==tp, sample_id]
    rowMeans(X[, rs(ids), drop=FALSE]) - cm
  })
  dpool <- rowMeans(E)
  D <- apply(E,1,max)-apply(E,1,min)
  C <- rowMeans(sign(E) != sign(dpool))
  list(pool=dpool, inst=abs(D)*(1+C))
}

# Fixed LT pseudo-partition reference, matching the manuscript's homogeneous-reference logic.
make_lt_reference <- function(Bnull=200L, seed=1L) {
  set.seed(seed)
  m <- meta[condition=="lt"]
  t0 <- m[group_type=="treatment", sample_id]
  c0 <- m[group_type=="control", sample_id]
  dpool <- mean_effect(t0,c0)
  H <- matrix(NA_real_, nrow(X), Bnull)
  P <- matrix(NA_real_, nrow(X), Bnull)
  for (b in seq_len(Bnull)) {
    tt <- sample(t0, length(t0), replace=FALSE)
    cc <- sample(c0, length(c0), replace=FALSE)
    nt1 <- floor(length(tt)/2); nc1 <- floor(length(cc)/2)
    t1 <- tt[seq_len(nt1)]; t2 <- tt[(nt1+1):length(tt)]
    c1 <- cc[seq_len(nc1)]; c2 <- cc[(nc1+1):length(cc)]
    d1 <- mean_effect(t1,c1); d2 <- mean_effect(t2,c2)
    n1 <- length(t1)+length(c1); n2 <- length(t2)+length(c2)
    ds <- (n1*d1+n2*d2)/(n1+n2)
    H[,b] <- abs(d1-d2)
    P[,b] <- abs(dpool-ds)
  }
  list(pool=dpool, inst=rowMeans(H)+rowMeans(P))
}

lt <- make_lt_reference(200L, SEED)

run_boot <- function(B, seed=SEED) {
  set.seed(seed)
  ans <- vector("list", B)
  for (b in seq_len(B)) {
    uv  <- boot_subgroup("uv",  c("long","short"))
    des <- boot_subgroup("des", c("fast","slow"))
    gam <- boot_gam()

    q25 <- quantile(abs(c(uv$pool,des$pool,gam$pool,lt$pool)), .25, names=FALSE)
    q90 <- quantile(c(uv$inst,des$inst,gam$inst,lt$inst), .90, names=FALSE)

    ans[[b]] <- data.table(
      replicate=b,
      global_q25_abs_delta_pool=q25,
      global_q90_instability=q90,
      UV=mean(abs(uv$pool)<q25 & uv$inst>=q90),
      DES=mean(abs(des$pool)<q25 & des$inst>=q90),
      GAM=mean(abs(gam$pool)<q25 & gam$inst>=q90)
    )
  }
  rbindlist(ans)
}

r500 <- run_boot(B_PRIMARY, SEED)
r200 <- r500[1:B_CHECK]  # convergence check uses the same seeded sequence

fwrite(r200, file.path(out_dir, "NM2_final_bootstrap_masked_fraction_B200_replicates.tsv"), sep="\t")
fwrite(r500, file.path(out_dir, "NM2_final_bootstrap_masked_fraction_B500_replicates.tsv"), sep="\t")

summ <- rbindlist(lapply(c(200L,500L), function(B) {
  rr <- if (B==200L) r200 else r500
  rbindlist(lapply(c("UV","DES","GAM"), function(cond) {
    x <- rr[[cond]]
    data.table(B=B, condition=cond,
               bootstrap_mean_fraction=mean(x),
               bootstrap_sd_fraction=sd(x),
               bootstrap_mean_percent=100*mean(x),
               bootstrap_sd_percent=100*sd(x),
               q2.5_fraction=quantile(x,.025,names=FALSE),
               q97.5_fraction=quantile(x,.975,names=FALSE))
  }))
}))
fwrite(summ, file.path(out_dir, "NM2_final_bootstrap_masked_fraction_summary.tsv"), sep="\t")
print(summ)
