#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop("User must supply sample sheet and summit parameter")
}
sample <- args[1]
interval <- as.integer(args[2])

options(echo=TRUE, warn=1)
library(DiffBind)

# Valid contrast attributes : DBA_ID, DBA_TISSUE, DBA_FACTOR, DBA_CONDITION, DBA_TREATMENT, DBA_REPLICATE, DBA_CALLER
# Infer input directory from sample csv directory
dir <- dirname(sample)
if (dir != '.'){
	sample <- read.table(sample, sep=',')
	sample$bamReads <- file.path(dir, basename(sample$bamReads))
	sample$bamControl <- file.path(dir, basename(sample$bamControl))
	sample$Peaks <- file.path(dir, basename(sample$Peaks))
}

# Create diffbind object
data <- dba(sampleSheet=sample)
date <- format(Sys.Date(), format="%Y-%m-%d")

# Plotting Commands
pdf("output.pdf", paper="a4")

plot(data, main="", sub = "")
dba.plotPCA(data,DBA_FACTOR,label=DBA_CONDITION)

dev.off()

if (interval == 0) {
	counted <- dba.count(data)
} else {
	counted <- dba.count(data, summits=interval)
}
diffs <- dba.analyze(dba.contrast(counted, categories=DBA_CONDITION, minMembers=2))

# save deseq results
deseq_results <- dba.report(diffs, method=DBA_DESEQ2, contrast = 1, th=1)
deseq_df <- as.data.frame(deseq_results)
write.table(file = 'deseq_results.tsv', x = deseq_df, col.names = TRUE, row.names = FALSE, sep = '\t', quote=F)

# # save edge_r results
# edger_results <- dba.report(diffs, method = DBA_EDGER, contrast = 1, th = 1)
# edger_df <- as.data.frame(edger_results)
# write.table(file = 'edger_results.tsv', x = edger_df, col.names = TRUE, row.names = FALSE, sep = '\t', quote=F)