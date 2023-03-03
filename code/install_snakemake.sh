#!/bin/bash

conda activate

conda create --prefix /usr/local/usrapps/lmquesad/kxketzes/renseq_assembly_snakemake/env_snakemake
conda create --prefix /usr/local/usrapps/lmquesad/kxketzes/renseq_assembly_snakemake/env_funGAP

conda activate /usr/local/usrapps/lmquesad/kxketzes/renseq_assembly_snakemake/env_snakemake
conda install -c bioconda snakemake
conda deactivate
