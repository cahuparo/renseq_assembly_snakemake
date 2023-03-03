#!/usr/bin/bash

conda activate

conda create --prefix /usr/local/usrapps/lmquesad/chparada/env_snakemake
conda create --prefix /usr/local/usrapps/lmquesad/chparada/env_funGAP

conda activate /usr/local/usrapps/lmquesad/chparada/env_snakemake
conda install -c bioconda snakemake
conda deactivate
