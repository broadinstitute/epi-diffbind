#!/usr/bin/env Rscript

# helper to install and load packages one by one
# to verify they were installed successfully;
# otherwise, R treats installation errors as warnings
setup <- function(installer, packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE)) {
      installer(pkg)
      library(pkg, character.only = TRUE)
    }
  }
}

setup(install.packages, c(
  "BiocManager"
))

bioc_version <- "3.11"

BiocManager::install(version = bioc_version)

setup_bioc <- function(installer, packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE)) {
      installer(pkg, version)
      library(pkg, character.only = TRUE)
    }
  }
}

setup_bioc(BiocManager::install, c(
  "DiffBind"
))
