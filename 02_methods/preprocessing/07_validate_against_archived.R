#!/usr/bin/env Rscript
a<-commandArgs(trailingOnly=TRUE); if(length(a)!=4) stop('Usage: new_x_count.csv archived_x_count.csv new_vst.tsv archived_vst.tsv')
rd<-function(p){x<-if(grepl('csv$',p,ignore.case=TRUE)) read.csv(p,check.names=FALSE) else read.delim(p,check.names=FALSE); rn<-as.character(x[[1]]); x<-as.matrix(x[,-1,drop=FALSE]); rownames(x)<-rn; storage.mode(x)<-'double'; x}
cmp<-function(n,o,label){cat('\n==',label,'==\n');cat('new',dim(n),'archived',dim(o),'\n');cat('sample set',setequal(colnames(n),colnames(o)),'order',identical(colnames(n),colnames(o)),'\n'); miss<-setdiff(rownames(o),rownames(n));cat('archived genes absent from new',length(miss),'\n'); if(!length(miss)&&setequal(colnames(n),colnames(o))){z<-n[rownames(o),colnames(o),drop=FALSE]; dd<-abs(z-o);cat('max_abs_diff',max(dd,na.rm=TRUE),'mean_abs_diff',mean(dd,na.rm=TRUE),'pearson',cor(as.vector(z),as.vector(o),use='complete.obs'),'\n')}}
cmp(rd(a[1]),rd(a[2]),'X_COUNT'); cmp(rd(a[3]),rd(a[4]),'VST')
