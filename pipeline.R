#!/usr/bin/env Rscript

options(echo=TRUE, warn=1)

library(DiffBind)

samples <- read.csv("input.csv")
data <- dba(sampleSheet="input.csv")

pdf("input.v1.pdf")
plot(data, main="", sub="")
title(main="input", cex.main=1)
title(sub="2017-12-20-CBE", cex.sub=0.5)
dev.off()

pdf("PCA-FACTOR.v1.pdf")
dba.plotPCA(data, DBA_FACTOR, label=DBA_CONDITION)
dev.off()

data.0 <- dba.count(data)
data.0.contrast <- dba.contrast(data.0, categories=DBA_CONDITION, minMembers=2)
data.0.diffs <- dba.analyze(data.0.contrast)

pdf("contrast.pdf")
plot(data.0.diffs, contrast=1)
dev.off()

pdf("diffs.PCA-CONDITION.pdf")
dba.plotPCA(data.0.diffs, contrast=1, label=DBA_FACTOR)
dev.off()

data.0.peaks <- dba.report(data.0.diffs)

peaks_df <- as(data.0.peaks,"data.frame")
write.csv(peaks_df, file="contrast-loci.df.csv")

pdf("peaks-histogram.pdf")
hist(peaks_df$Fold, breaks=100)
dev.off()

pdf("MA.pdf")
dba.plotMA(data.0.diffs)
dev.off()

pdf("Volcano.pdf")
dba.plotVolcano(data.0.diffs)
dev.off()

pdf("Heatmap2.pdf")
corvals <- dba.plotHeatmap(data.0.diffs, contrast=1, correlations=FALSE)
dev.off()
