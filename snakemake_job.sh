#!/bin/csh

##CCS, extract fasta/fastq

#BSUB -o out.%J
#BSUB -e err.%J
#BSUB -W 96:00
#BSUB -n 32
#BSUB -x
#BSUB -J snakemake1

conda activate /usr/local/usrapps/lmquesad/chparada/env_snakemake

snakemake --use-envmodules --cores 32

