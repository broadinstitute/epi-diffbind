#!/usr/bin/env Rscript
message(sprintf('Current working directory: %s', getwd()))

# First check that inputs are valid
# Expected arguments:
# 1) Sample sheet path
# 2) Interval width
# 3) Contrast variable
# 4) Label variable
# 5) Mode [pcaOnly]
args = commandArgs(trailingOnly=TRUE)
if (length(args) < 4 | length(args) > 5) {
  stop("ERROR: User must supply sample sheet, summit parameter, along with contrast and label variables, and (optional) mode")
}
sample <- args[1]
interval <- as.integer(args[2])
modeFlag <- args[5]

# Infer input directory from sample csv directory
dir <- dirname(sample)

# Check if inputs have been localized by looking for each file
sample <- read.csv(sample, sep=ifelse(grepl('tsv', sample), '\t', ','))
controlPresent <- !is.null(sample$bamControl)

updatePaths <- function(sample, controlPresent){
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
	# Optional
	if(controlPresent){
		sample$bamControl <- .getNewPaths(sample$bamControl)
	}
	sample$Peaks <- .getNewPaths(sample$Peaks)

	return(sample)
}

sample <- updatePaths(sample, controlPresent)

# If any input file is missing, throw error
if(sum(is.na(c(sample$bamReads, sample$bamControl, sample$Peaks))) > 0){
	stop("ERROR: Not all input files found")
}

options(echo=TRUE, warn=1)
library(DiffBind)
library(GreyListChIP)

# Create diffbind object
message('Creating DBA object from sample sheet...')
data <- dba(sampleSheet=sample)
# date <- format(Sys.Date(), format="%Y-%m-%d")

# Reduce yieldSize
# data$config$yieldSize <- 2500000
message(sprintf('Cores detected: %s', data$config$cores))

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

# if(exists(modeFlag)){
# 	if(modeFlag == 'pcaOnly'){
# 		file.create('deseq_results.tsv')
# 		quit(save='no')
# 	}
# }

# TODO: soft-code genome selection
message('Generating greylist...')
load(system.file("extra/ktypes.rda", package="DiffBind"), envir = environment())


# makeGreyList <- function(data, karyotype){
# 	noControls_ <- function(controls) {
# 		if(sum(is.na(controls))==length(controls)) {
# 			return(TRUE)
# 		} else {
# 			if(length(unique(controls))==1 && controls[1]=="") {
# 			return(TRUE)        
# 			}
# 		}
# 		return(FALSE)
# 	}

# 	controls <- data$class['bamControl',]

# 	if(noControls_(controls)){
# 		return(FALSE)
# 	}

# 	whichcontrols <- !duplicated(controls)
# 	whichcontrols <- whichcontrols & !is.na(controls)
# 	whichcontrols <- whichcontrols & controls != ""
# 	controls      <- controls[whichcontrols]
# 	controlnames  <- data$class['Control', whichcontrols]
# 	gl_template <- new("GreyList",karyotype=karyotype)

# 	getGreylist_ <- function(gl, bamfile, pval, usecores){
# 		gl <- GreyListChIP::countReads(gl, bamfile)
# 		gl <- GreyListChIP::calcThreshold(gl,p=pval,cores=usecores)
# 		gl <- GreyListChIP::makeGreyList(gl)
# 		return(gl@regions)
# 	}

# 	usecores <- 4#data$config$cores
# 	pval=.999

# 	controllist <- vector(mode='list', length(controls))
# 	for (i in seq_along(controls)){
# 		controllist[[i]] <- getGreylist_(gl_template, controls[i], pval, usecores)
# 	}
# 	names(controllist) <- controlnames

# 	controllist <- GRangesList(controllist)
# 	greylist <- list(master=Reduce(union, controllist),controls=controllist)

# 	return(greylist)
# }

# greylist <- makeGreyList(data, dba.ktypes$BSgenome.Hsapiens.1000genomes.hs37d5)

# Make greylist if controls exist
if(controlPresent){
	controls <- data$class['bamControl',]

	# Find unique, non-NA, non-empty controls
	whichcontrols <- !duplicated(controls)
	whichcontrols <- whichcontrols & !is.na(controls)
	whichcontrols <- whichcontrols & controls != ""
	controls      <- controls[whichcontrols]
	controlnames  <- data$class['Control', whichcontrols]
	gl_template <- new("GreyList",karyotype=dba.ktypes$BSgenome.Hsapiens.1000genomes.hs37d5)

	getGreylist <- function(gl, bamfile, pval, usecores){
		gl <- GreyListChIP::countReads(gl, bamfile)
		gl <- GreyListChIP::calcThreshold(gl,p=pval,cores=usecores)
		gl <- GreyListChIP::makeGreyList(gl)
		return(gl@regions)
	}

	usecores <- 4#data$config$cores
	pval=.999

	controllist <- vector(mode='list', length(controls))
	for (i in seq_along(controls)){
		controllist[[i]] <- getGreylist(gl_template, controls[i], pval, usecores)
	}
	names(controllist) <- controlnames

	controllist <- GRangesList(controllist)
	greylist <- list(master=Reduce(union, controllist),controls=controllist)

	greyed <- dba.blacklist(data, blacklist=DBA_BLACKLIST_GRCH37, greylist=greylist)
} else {
	greyed <- dba.blacklist(data, blacklist=DBA_BLACKLIST_GRCH37, greylist=F)
}

saveRDS(greyed, 'tmp1_blacklisted.rds')

message('Counting reads...')
if (interval == 0) {
	counted <- dba.count(greyed, bUseSummarizeOverlaps=F, bParallel=F)
} else {
	counted <- dba.count(greyed, summits=interval, bUseSummarizeOverlaps=F, bParallel=F)
}

saveRDS(counted, 'tmp2_counted.rds')

message('Normalizing')
normalized <- dba.normalize(counted)

saveRDS(normalized, 'tmp3_normalized.rds')

message('Setting up contrasts...')
cont <- dba.contrast(normalized, categories=contrast, minMembers=2)

saveRDS(cont, 'tmp4_contrasted.rds')


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

# Plotting Commands
message('Generating plots...')
pdf("output.pdf", paper="a4")

plot(data, main="", sub = "")
dba.plotPCA(data, attributes=contrast, label=label)

dev.off()