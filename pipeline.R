#!/usr/bin/env Rscript


args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop("One argument must be supplied (the interval size)")
}
interval <- args[1]

options(echo=TRUE, warn=1)
library(DiffBind)
data <- dba(sampleSheet="input.csv")
date <- format(Sys.Date(), format="%Y-%m-%d")


pdf("input.pdf", paper="a4")
plot(data, main="", sub="")
# need to look into this to see if the data can be fit to the page

title(main="input.pdf", cex.main=1)
title(sub=date, cex.sub=0.5) 
dev.off()


pdf("PCA-FACTOR.pdf", paper="a4")
dba.plotPCA(data, DBA_FACTOR, label=DBA_CONDITION)
dev.off()


if (is.na(as.integer(interval))) {
	stop("Interval must be an integer")
}

interval <- as.integer(interval)
if (interval == 0) {
	counted <- dba.count(data)
} else {
	counted <- dba.count(data, summits=interval)
}
diffs <- dba.analyze(dba.contrast(counted, categories=DBA_CONDITION, minMembers=2))



pdf("contrast.pdf", paper="a4")
plot(diffs, contrast=1)
dev.off()

pdf("PCA-CONDITION-diffs.pdf", paper="a4")
dba.plotPCA(diffs, contrast=1, label=DBA_FACTOR)
dev.off()

peaks <- dba.report(diffs)
peaks_df <- as(peaks,"data.frame")
write.csv(peaks_df, file="contrast-loci.df.csv")

pdf("peaks-histogram.pdf", paper="a4")
hist(peaks_df$Fold, breaks=100)
dev.off()

pdf("MA.pdf", paper="a4")
dba.plotMA(diffs)
dev.off()

pdf("Volcano.pdf", paper="a4")
dba.plotVolcano(diffs)
dev.off()

pdf("Heatmap2.pdf", paper="a4")
dba.plotHeatmap(diffs, contrast=1, correlations=FALSE)
dev.off()
