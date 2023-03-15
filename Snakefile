configfile: "config.yaml"

rule all:
	input:
		expand("blasr/{sample}_blasr_out.fasta", sample=config["samples"])

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
		"renseq_assembly.yml"
	threads: 15
	shell:
		"ccs -j {threads} --min-rq 0.9 --min-passes 3 --max-length 50000 --report-file {log} {input} {output}"

rule bam2fasta:
	input:
		"ccs/{sample}.ccs.bam"
	output:
		"fasta/{sample}.ccs.fasta.gz"
	conda:
		"renseq_assembly.yml"
	shell:
		"bam2fasta -o {output} {input}"

rule gunzip:
	input: 
		"fasta/{sample}.ccs.fasta.gz"
	output: 
		"fasta/{sample}.ccs.fasta"
	conda:
		"renseq_assembly.yml"
	shell: "gunzip {input}"

rule cutadapt1:
	input:
		"fasta/{sample}.ccs.fasta"
	output:
		"cutadapt/trimmed65_{sample}.ccs.fasta"
	conda:
		"renseq_assembly.yml"
	shell:
		"cutadapt -u 65 -u - 65 -o {output} {input}"

rule cutadapt2:
	input:
		"cutadapt/trimmed65_{sample}.ccs.fasta"
	output:
		"cutadapt/trimmed_{sample}.fasta"
	conda:
		"renseq_assembly.yml"
	shell:
		"cutadapt -b file:extra_files/adapters.fasta -e 0.05 -m 150 -o {output} {input}"

rule blasr:
	input:
		"cutadapt/trimmed_{sample}.fasta"
	output:
		"blasr/{sample}_blasr_out.m4"
	conda:
		"renseq_assembly.yml"
	shell:
		"blasr extra_files/adapters.fasta -m 1 --bestn 10 --out {output} {input} | sed 's,ccs/,ccs,g'"

rule filter_m4_output:
	input:
		"cutadapt/trimmed_{sample}.fasta",
		"blasr/{sample}_blasr_out.m4"
	output:
		"blasr/{sample}_blasr_out.fasta"
	conda:
		"renseq_assembly.yml"
	shell:
		"python extra_files/PacBio-filter.py {input} {output} "

rule canu:
	input:
		"blasr/{sample}_blasr_out.fasta"
	output:
		"canu/{sample}_assembly"
	conda:
		"renseq_assembly.yml"
	threads: 15
	shell:
		"canu -assemble -p {output} -d {output}_e1_1m genomeSize=1m correctedErrorRate=0.010 -pacbio-corrected {input} -minOverlapLength=350 -trimReadsCoverage=1 -minReadLength=1000 -maxMemory=32 -maxThreads={threads} usegrid=0"
