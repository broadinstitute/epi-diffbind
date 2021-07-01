#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop("ERROR: User must supply sample sheet")
}
sample <- args[1]

sample <- read.csv(sample, sep=ifelse(grepl('.tsv', sample), '\t', ','))

files <- unique(c(sample$bamReads, sample$bamControl, sample$Peaks))

write.table(files, file='files.txt', col.names=F, row.names=F, quote=F)