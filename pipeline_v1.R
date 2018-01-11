#!/usr/bin/env Rscript

#options(echo=TRUE, warn=1)

#version <- readline(prompt="Please enter the version number: ")
#initials <- readline(prompt="Please enter your initials: ")
#interval <- readline(prompt="Please enter the desired interval size: ")

cat("Please enter the version number: ")
version <- readLines(con="stdin", 1)
cat("Please enter your initials: ")
initials <- readLines(con="stdin", 1)
cat("Please enter the desired interval size: ")
interval <- readLines(con="stdin", 1)

options(echo=TRUE, warn=1)


library(DiffBind)

samples <- read.csv("input.csv")
data <- dba(sampleSheet="input.csv")


today <- Sys.Date()
date <- format(today, format="%Y-%m-%d")
header <- paste(date, initials, sep="-")

input <- paste("input.v", version, ".pdf", sep="")
pdf(input) #eg. input.v1.pdf
plot(data, main="", sub="")
# need to look into this to see if the data can be fit to the page

# the 1 and 0.5 in the two lines below might change depending on what
# we eventually do with the resizing issue referenced above
title(main=input, cex.main=1)
title(sub=header, cex.sub=0.5) 
dev.off()

pca_factor <- paste("PCA-FACTOR.v", version,".pdf", sep="")
pdf("PCA-FACTOR.v1.pdf")
dba.plotPCA(data, DBA_FACTOR, label=DBA_CONDITION)
dev.off()


counted <- dba.count(data)
contrast <- dba.contrast(counted, categories=DBA_CONDITION, minMembers=2)
diffs <- dba.analyze(contrast)
# the above three lines of code can be consolidated as followed, if preferred:
# diffs <- dba.analyze(dba.contrast(dba.count(data), categories=DBA_CONDITION, minMembers=2))



constrast_filename <- paste("constrast", interval, ".pdf", sep="")
pdf(constrast_filename)
plot(diffs, contrast=1)
dev.off()

pca_condition <- paste("PCA-CONDITION", interval, "diffs.pdf", sep="")
pdf(pca_condition)
dba.plotPCA(diffs, contrast=1, label=DBA_FACTOR)
dev.off()

peaks <- dba.report(diffs)

peaks_df <- as(peaks,"data.frame")
loci_filename <- paste("constrast-loci", interval, ".df.csv", sep="")
write.csv(peaks_df, file=loci_filename)

histogram <- paste("peaks-histogram", interval, ".pdf", sep="")
pdf(histogram)
hist(peaks_df$Fold, breaks=100)
dev.off()

ma <- paste("MA", interval, ".pdf", sep="")
pdf(ma)
dba.plotMA(diffs)
dev.off()

volcano <- paste("Volcano", interval, ".pdf", sep="")
pdf(volcano)
dba.plotVolcano(diffs)
dev.off()

heatmap <- paste("Heatmap2.", interval, ".pdf", sep="")
pdf(heatmap)
corvals <- dba.plotHeatmap(diffs, contrast=1, correlations=FALSE)
dev.off()
