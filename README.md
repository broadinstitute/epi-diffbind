## DiffBind Image

This repository contains scripts and a Dockerfile for a DiffBind pipeline used by Epigenomics platform.\
It also includes a WDL file and notebook for use in Terra.

### Overall inputs:
Sample sheet\
Summit width \[OPTIONAL, DEFAULT:200\] 

### Overall outputs:
DBA Object with raw counts, before normalization

Notebook contains code for normalization, setting up contrast, and differential binding affinity analysis as well as code for figure generation.

## Details
`getPaths.r` simply reads in the sample sheet and returns a list of the Google Cloud file paths for the input BAMs, peaks files, and control BAMs (if specified). This serves as an input to `DiffBind` task within the WDL in order to automatically localize the required files.

`diffBind.r` loads in the sample sheet and updates the paths to the files based on where they have been localized. Next, a DBA object is created, the greylist is generated and applied along with a blacklist, and counts the reads in the peaks. Due to issues with DiffBind's implementation of parallelization, it is disabled at all steps.

The Terra implementation exists here: [https://app.terra.bio/#workspaces/encode4-2019/Bioconductor_in_Terra](https://app.terra.bio/#workspaces/encode4-2019/Bioconductor_in_Terra)\
Currently, pushes to this repository trigger builds in Quay: [https://quay.io/repository/kdong2395/diffbind](https://quay.io/repository/kdong2395/diffbind)

## TODO
It would normally be built and deployed automatically through
[Google Container Builder](https://cloud.google.com/container-builder/docs/quickstart-docker)
according to [cloudbuild.yaml](cloudbuild.yaml).

Add `genome` as in input parameter. It is currently assumed to be GRCh37 (without the "chr" prefix). 
