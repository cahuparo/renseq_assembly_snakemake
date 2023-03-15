#!/usr/bin/env python
#python-2.7.9
#biopython-1.66

import sys
from Bio import SeqIO

fasta_file=(sys.argv[1]) # 65bp trimmed cutadapt FASTA output file
exclude_file=(sys.argv[2]) # BLASR m4 file highlighting reads still containing adapters
result_file=(sys.argv[3]) # Output FASTA file


wanted = set()

with open(exclude_file) as f:
    for i in f:
        i=i.split()
        wanted.add(str(i[0]))

fasta_sequences = SeqIO.parse(open(fasta_file),'fasta')
with open(result_file, "w") as f:
    for seq in fasta_sequences:
        if seq.id in wanted:
            print(seq.id)
        else:
            SeqIO.write([seq], f, "fasta")

print("Finished")