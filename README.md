# README

<aside>
⚠️ This a pipeline to produce RenSeq assemblies using snakemake.

</aside>

### Requirements:

- [ ]  git
- [ ]  conda
- [ ]  snakemake
- [ ]  At least 15 cores CPU

### To run this pipeline:

1. Clone this repository in the machine that will be providing the hardware. You need to have `git` installed in this machine:
    
    ```bash
    git --version
    git clone https://github.com/cahuparo/renseq_assembly_snakemake.git
    ```
    
2. Create the conda environment to makesure that all tools/packages are installed:
    
    ```bash
    conda create --prefix /path/to/the/working/directory/env_renseq_assembly
    conda activate /path/to/the/working/directory/env_renseq_assembly
    conda install -c bioconda snakemake
    conda install -c bioconda pbccs
    conda install -c bioconda bamtools
    conda install -c bioconda bam2fastx
    conda install -c bioconda cutadapt
    conda install -c bioconda blasr
    conda install -c bioconda biopython
    conda install -c bioconda canu
    conda deactivate
    ```
    
3. Gather raw data (bam file) for each genotype and place it in a directory labeled `bam`
    
    ```bash
    mkdir bam
    #cp or scp bam files ---> to the bam directory
    ```
    





3. Then create a screen session
    
    ```bash
    screen
    ```
    
4. Activate conda environment
    
    ```bash
    conda activate /path/to/the/working/directory/env_renseq_assembly
    ```
    
5. Run `snakemake` and monitor after `control + AD`
    
    ```bash
    snakemake --latency-wait 120 --cores 32
    ```
    