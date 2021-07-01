#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 4) {
  stop("ERROR: User must supply sample sheet, summit parameter, along with contrast and label variables")
}
sample <- args[1]
interval <- as.integer(args[2])

# Infer input directory from sample csv directory
dir <- dirname(sample)

# Check if input files are in current directory
if (dir != '.'){
	# Check if inputs have been localized by looking for first file
	sample <- read.csv(sample, sep=ifelse(grepl('tsv', sample), '\t', ','))
	# If input files exist in same folder as sample sheet, update all paths
	if(file.exists(file.path(dir, basename(sample$bamReads[1])))){
		sample$bamReads <- file.path(dir, basename(sample$bamReads))
		sample$bamControl <- file.path(dir, basename(sample$bamControl))
		sample$Peaks <- file.path(dir, basename(sample$Peaks))
	} else {
		# If files don't exist, assume we have gcp links and localize
		files <- c(sample$bamReads, sample$bamControl, sample$Peaks)
		write.table(unique(files), 'files.txt', row.names=F, col.names=F, quote=F)
		system('cat files.txt | gsutil -m cp -n -I .')
		sample$bamReads <- basename(sample$bamReads)
		sample$bamControl <- basename(sample$bamControl)
		sample$Peaks <- basename(sample$Peaks)
	}
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

message('Counting reads...')
if (interval == 0) {
	counted <- dba.count(data)
} else {
	counted <- dba.count(data, summits=interval)
}
message('Setting up contrasts...')
cont <- dba.contrast(counted, categories=contrast, minMembers=2)
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