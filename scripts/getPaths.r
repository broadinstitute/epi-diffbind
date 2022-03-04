#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop("ERROR: User must supply sample sheet and disk factor")
}
sample <- args[1]
diskFactor <- as.integer(args[2])

sample <- read.csv(sample, sep=ifelse(grepl('.tsv', sample), '\t', ','))

files <- unique(c(sample$bamReads, sample$bamControl, sample$Peaks))
write.table(files, file='files.txt', col.names=F, row.names=F, quote=F)

bams <- length(unique(c(sample$bamReads, sample$bamControl)))
est_size <- 1.1 * bams * diskFactor
write((est_size %/% 375 + 1)*375, file='disk.txt')

# Uses 8 cores, failure at 18 rows with 4G memory per core
# cores <- max(ceiling(nrow(sample) * 8/16 / 2) * 2, 8) # multiples of 2
# write(cores, file='core.txt')
# write(cores*4, file='mem.txt')