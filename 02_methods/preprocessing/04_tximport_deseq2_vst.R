#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(tximport);library(DESeq2);library(readr);library(tibble)})
a<-commandArgs(trailingOnly=TRUE); if(length(a)!=4) stop('Usage: metadata.csv quant_dir tx2gene.tsv out_dir')
meta<-read.csv(a[1],stringsAsFactors=FALSE,check.names=FALSE); req<-c('sample_id','condition','group_type','timepoint'); if(!all(req%in%names(meta))) stop('metadata missing required columns')
meta$sample_id<-trimws(meta$sample_id); if(nrow(meta)!=111||length(unique(meta$sample_id))!=111) stop('Authoritative preprocessing requires exactly 111 unique samples')
meta$condition<-factor(tolower(trimws(meta$condition))); meta$group_type<-factor(tolower(trimws(meta$group_type))); meta$timepoint<-factor(tolower(trimws(meta$timepoint))); rownames(meta)<-meta$sample_id
files<-file.path(a[2],paste0(meta$sample_id,'_salmon'),'quant.sf'); names(files)<-meta$sample_id; if(any(!file.exists(files))) stop('Missing quant.sf: ',paste(names(files)[!file.exists(files)],collapse=', '))
tx2<-read_tsv(a[3],col_names=c('TXNAME','GENEID'),show_col_types=FALSE); dir.create(a[4],recursive=TRUE,showWarnings=FALSE)
txi<-tximport(files,type='salmon',tx2gene=tx2,countsFromAbundance='lengthScaledTPM'); saveRDS(txi,file.path(a[4],'txi_genelevel.rds'))
write.csv(as.data.frame(txi$counts)|>rownames_to_column('GeneID'),file.path(a[4],'x_count.csv'),row.names=FALSE)
dds<-DESeqDataSetFromTximport(txi,colData=meta,design=~condition+group_type); keep<-rowSums(counts(dds))>=10; dds<-dds[keep,]; saveRDS(dds,file.path(a[4],'dds_all_preview.rds'))
vsd<-vst(dds,blind=TRUE); m<-assay(vsd); write_tsv(as.data.frame(m)|>rownames_to_column('GeneID'),file.path(a[4],'vst_counts_all_groups.tsv'))
writeLines(capture.output(sessionInfo()),file.path(a[4],'R_sessionInfo.txt')); cat(sprintf('PASS: tximport=%d genes; VST=%d genes x %d samples\n',nrow(txi$counts),nrow(m),ncol(m)))
