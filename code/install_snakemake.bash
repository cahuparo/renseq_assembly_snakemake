#!/usr/bin/bash

conda env create --prefix /data/run/chparada/renseq_assembly_snakemake/env_snakemake -f dependencies.yaml
conda create --prefix /data/run/chparada/renseq_assembly_snakemake/env_snakemake
conda activate /data/run/chparada/renseq_assembly_snakemake/env_snakemake
conda install -c bioconda snakemake
conda deactivate