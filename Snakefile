configfile: "config.yaml"

rule all:
    input:
       expand("fasta/{sample}.ccs.fasta.gz", sample=config["samples"])

def get_extract_ccs_input_bams(wildcards):
    return config["samples"][wildcards.sample]

rule extract_ccs:
    input:
        get_extract_ccs_input_bams
    output:
        "ccs/{sample}.ccs.bam"
    log:
        "ccs/logs/{sample}.ccs.report.txt"
    conda:
        "envs/ccs_qc.yaml"
    threads: 16
    shell:
        "ccs -j {threads} --min-rq 0.9 --min-passes 3 --max-length 50000 --report-file {log} {input} {output}"

rule bam2fastq:
    input:
        "ccs/{sample}.ccs.bam"
    output:
        "fastq/{sample}.ccs.fastq"
    conda:
        "envs/ccs_qc.yaml"
    shell:
        "bamtools convert -format fastq -in {input} -out {output}"

rule bam2fasta:
    input:
        "ccs/{sample}.ccs.bam"
    output:
        "fasta/{sample}.ccs.fasta.gz"
    conda:
        "envs/ccs_qc.yaml"
    shell:
        "bam2fasta -o {output} {input}"
