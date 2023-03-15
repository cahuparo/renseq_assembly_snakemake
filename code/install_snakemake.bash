#!/usr/bin/bash

conda create --prefix /data/run/chparada/renseq_assembly_snakemake/env_renseq_assembly
conda activate /data/run/chparada/renseq_assembly_snakemake/env_renseq_assembly
conda install -c bioconda snakemake
conda install -c bioconda pbccs
conda install -c bioconda bamtools
conda install -c bioconda bam2fastx
conda install -c bioconda cutadapt
conda install -c bioconda blasr
conda install -c bioconda biopython
conda install -c bioconda canu
conda deactivate
