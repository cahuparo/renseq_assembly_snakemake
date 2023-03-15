#!/usr/bin/bash

conda create --prefix /data/run/chparada/renseq_assembly_snakemake/env_snakemake
conda activate /data/run/chparada/renseq_assembly_snakemake/env_snakemake
conda install -c bioconda snakemake
conda deactivate
somethinh