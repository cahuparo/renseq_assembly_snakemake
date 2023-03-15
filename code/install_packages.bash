#!/usr/bin/bash
#here we used conda to install the software into the env_snakemake. This allows us to make sure that everyone that is using this snakemake scripts can easily run the pipeline.
conda activate /usr/local/usrapps/lmquesad/chparada/env_snakemake
conda env update -n env_snakemake --file dependencies.yaml

# for any new program to run with snakemake make sure to install it here!