#!/usr/bin/bash

conda activate /usr/local/usrapps/lmquesad/chparada/env_snakemake
conda install -c bioconda pbccs
conda install -c bioconda bamtools
conda install -c bioconda bam2fastx
# for any new program to run with snakemake make sure to install it here!