#!/bin/bash
###################
# Helper script to run blastn on genomes, checking first for compression
# Author: Paul Villanueva
###################

INPUT_GENOME=${snakemake_input[input_genome]}

# Helper function for blastn
run_blast() {
    blastn -subject_besthit \
        -db ${snakemake_params[blast_db]} \
        -query $1 \
        -outfmt '6 qseqid qlen sseqid slen pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs salltitles' \
        -num_threads 4 \
        -out ${snakemake_output[blast_results]}
}

# If the file is a gz, decompress it to an intermediate file, blast against it, then remove the intermediate file
# I feel like this is faster/less memory intensive than using zcat | blastn
# TODO: Check for .tar
if [[ $INPUT_GENOME == *.gz ]]; then
    gunzip -k $INPUT_GENOME
    run_blast ${INPUT_GENOME%.gz}
    rm ${INPUT_GENOME%.gz}
else
    run_blast $INPUT_GENOME
fi
