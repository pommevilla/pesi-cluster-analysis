#!/usr/bin/env Rscript
###################
# Filter pESI contigs from BLAST results
# Inputs:
#   * pesi_extract/{genome}/blast_results.txt - BLAST results from genome against the chromosomal/pESI genomic data
# Outputs:
#   * pesi_extract/{genome}/pESI_contigs.txt - list of pESI contigs from BLAST results
# Author: Paul Villanueva
###################

library(tidyverse)

blast_results <- read_tsv(
    # "outputs/test_run/pesi_extract/GCA_003733365.1_PDT000396410.1_genomic.fna/blast_results.tsv",
    snakemake@input[["blast_results"]],
    show_col_types = FALSE,
    c(
        "qseqid",
        "qlen",
        "sseqid",
        "slen",
        "pident",
        "length",
        "mismatch",
        "gapopen",
        "qstart",
        "qend",
        "sstart",
        "send",
        "evalue",
        "bitscore",
        "qcovs",
        "salltitles"
    )
)

# Get different matches when filter before and after the pident/qcovs filter...
# From Chris
blast_results %>%
    mutate(qseqid = as.character(qseqid)) %>%
    mutate(target_type = ifelse(slen > 4000000, "chromosome", "pESI")) %>%
    filter(pident >= 95 & qcovs >= 70) %>%
    group_by(qseqid) %>%
    slice_max(order_by = bitscore, n = 1, with_ties = TRUE) %>%
    ungroup() %>%
    filter(target_type == "pESI") %>%
    select(qseqid) %>%
    distinct()


# Modified
pesi_contigs <- blast_results %>%
    filter(pident >= 95 & qcovs >= 70) %>%
    group_by(qseqid) %>%
    slice_max(order_by = bitscore, n = 1, with_ties = TRUE) %>%
    filter(slen < 4000000) %>%
    select(qseqid) %>%
    distinct() %>%
    ungroup()

# TODO: Configure to use genome wildcard
if (snakemake@params[["save_session"]]) {
    # this_genome <- snakemake@params[["this_genome"]]
    # filename <- paste0(
    #     "workflow/images/extract/filter_pesi_contigs_",
    #     this_genome,
    #     ".RData"
    # )
    save.image(
        file = "workflow/images/extract/filter_pesi_contigs.RData"
    )
}

pesi_contigs %>%
    write_tsv(
        snakemake@output[["pesi_contigs_list"]],
        col_names = FALSE
    )
