#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop("ERROR: User must supply sample sheet")
}
sample <- args[1]

sample <- read.csv(sample, sep=ifelse(grepl('.tsv', sample), '\t', ','))

files <- unique(c(sample$bamReads, sample$bamControl, sample$Peaks))

write.table(files, file='files.txt', col.names=F, row.names=F, quote=F)

# Uses 8 cores, failure at 12 rows with 4G memory per core
write(ceiling(nrow(sample)*4/10)*8, file='mem.txt')