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

BiocManager::install(version = '3.11', ask = F, force = T)

setup(BiocManager::install, c(
  "DiffBind"
))
