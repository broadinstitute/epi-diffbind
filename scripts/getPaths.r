#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop("ERROR: User must supply sample sheet")
}
sample <- args[1]

sample <- read.csv(sample, sep=ifelse(grepl('.tsv', sample), '\t', ','))

files <- unique(c(sample$bamReads, sample$bamControl, sample$Peaks))

write.table(files, file='files.txt', col.names=F, row.names=F, quote=F)

# Uses 8 cores, failure at 18 rows with 4G memory per core
cores <- ceiling(nrow(sample) * 8/16 / 2) * 2 # multiples of 2
write(cores, file='core.txt')
write(cores*4*2, file='mem.txt')