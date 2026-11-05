#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(ggplot2);library(pheatmap)})
a<-commandArgs(trailingOnly=TRUE); if(length(a)!=3) stop('Usage: dds_all_preview.rds metadata.csv out_dir')
dds<-readRDS(a[1]); meta<-read.csv(a[2],stringsAsFactors=FALSE); dir.create(a[3],recursive=TRUE,showWarnings=FALSE); vsd<-vst(dds,blind=TRUE); m<-assay(vsd)
pc<-prcomp(t(m),center=TRUE,scale.=TRUE); pv<-100*(pc$sdev^2/sum(pc$sdev^2)); d<-as.data.frame(pc$x[,1:3]); d$sample_id<-rownames(d); d<-merge(d,meta,by='sample_id',all.x=TRUE,sort=FALSE); write.csv(d,file.path(a[3],'PCA_coordinates.csv'),row.names=FALSE)
p<-ggplot(d,aes(PC1,PC2,color=condition,shape=group_type))+geom_point(size=2.5)+theme_minimal()+labs(x=sprintf('PC1 (%.1f%%)',pv[1]),y=sprintf('PC2 (%.1f%%)',pv[2])); ggsave(file.path(a[3],'PCA.pdf'),p,width=8,height=6)
dm<-as.matrix(dist(t(m))); pheatmap(dm,filename=file.path(a[3],'sample_distance_heatmap.pdf'),width=9,height=8); cat('PASS: expression QC generated\n')
