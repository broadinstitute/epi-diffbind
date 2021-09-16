#!/usr/bin/env Rscript
message(sprintf('Current working directory: %s', getwd()))

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 4) {
  stop("ERROR: User must supply sample sheet, summit parameter, along with contrast and label variables")
}
sample <- args[1]
interval <- as.integer(args[2])

# Infer input directory from sample csv directory
dir <- dirname(sample)

# Check if inputs have been localized by looking for each file
sample <- read.csv(sample, sep=ifelse(grepl('tsv', sample), '\t', ','))

updatePaths <- function(sample){
	.getNewPaths <- function(files){
		sapply(files, function(file){
			newPath <- system(sprintf('find . -name %s', basename(file)), intern=T)
			if(length(newPath) == 0){
				return(NA)
			}
			return(newPath)
		})
	}

	sample$bamReads <- .getNewPaths(sample$bamReads)
	sample$bamControl <- .getNewPaths(sample$bamControl)
	sample$Peaks <- .getNewPaths(sample$Peaks)

	return(sample)
}

sample <- updatePaths(sample)

# If any input file is missing, throw error
if(sum(is.na(c(sample$bamReads, sample$bamControl, sample$Peaks))) > 0){
	stop("ERROR: Not all input files found")
}

options(echo=TRUE, warn=1)
library(DiffBind)

# Create diffbind object
message('Creating DBA object from sample sheet...')
data <- dba(sampleSheet=sample)
# date <- format(Sys.Date(), format="%Y-%m-%d")

# Check contrast variable against list of acceptable inputs
# Valid contrast attributes : DBA_ID, DBA_TISSUE, DBA_FACTOR, DBA_CONDITION, DBA_TREATMENT, DBA_REPLICATE, DBA_CALLER
contrast <- toupper(args[3])
valid_contrast <- c('DBA_ID', 'DBA_TISSUE', 'DBA_FACTOR', 'DBA_CONDITION', 'DBA_TREATMENT', 'DBA_REPLICATE', 'DBA_CALLER')
contrast_check <- grepl(contrast, valid_contrast)
if (sum(contrast_check) != 1){
	stop(sprintf("ERROR: Please supply valid contrast variable.\nMust be one of: {%s}", paste0(valid_contrast, collapse=', ')))
}
contrast <- eval(parse(text=valid_contrast[contrast_check]))

# Check label variable against list of acceptable inputs
label <- toupper(args[4])
label_check <- grepl(label, valid_contrast)
if (sum(label_check) != 1){
	stop(sprintf("ERROR: Please supply valid label variable.\nMust be one of: {%s}", paste0(valid_contrast, collapse=', ')))
}
label <- eval(parse(text=valid_contrast[label_check]))

# Plotting Commands
message('Generating plots...')
pdf("output.pdf", paper="a4")

plot(data, main="", sub = "")
dba.plotPCA(data, attributes=contrast, label=label)

dev.off()

message('Generating greylist...')
greyed <- dba.blacklist(data)

message('Counting reads...')
if (interval == 0) {
	counted <- dba.count(greyed, bUseSummarizeOverlaps=F)
} else {
	counted <- dba.count(greyed, summits=interval, bUseSummarizeOverlaps=F)
}

message('Normalizing')
normalized <- dba.normalize(counted)

message('Setting up contrasts...')
cont <- dba.contrast(normalized, categories=contrast, minMembers=2)

message('Performing differential binding analysis...')
diffs <- dba.analyze(cont)

# save deseq results
message('Saving results...')
deseq_results <- dba.report(diffs, method=DBA_DESEQ2, contrast = 1, th=1)
deseq_df <- as.data.frame(deseq_results)
write.table(file = 'deseq_results.tsv', x = deseq_df, col.names = TRUE, row.names = FALSE, sep = '\t', quote=F)
message('Results successfully saved!')

# # save edge_r results
# edger_results <- dba.report(diffs, method = DBA_EDGER, contrast = 1, th = 1)
# edger_df <- as.data.frame(edger_results)
# write.table(file = 'edger_results.tsv', x = edger_df, col.names = TRUE, row.names = FALSE, sep = '\t', quote=F)