#!/usr/bin/env Rscript
# ---------------------------
# Parses collected bakta output
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

############ Setup ############
library(tidyverse)

gene_presence_list <- read_tsv(
    "outputs/test_run/pesi_screen/infantis_genome_pESI_genes.tsv",
    show_col_types = FALSE,
    col_names = c(
        "genome_name",
        "contig_name",
        "type",
        "start",
        "stop",
        "strand",
        "locus",
        "gene_id",
        "product",
        "db_xrefs"
    )
)

pesi_presence_table <- gene_presence_list %>%
    group_by(genome_name) %>%
    summarise(
        repA_present = any(gene_id == "repA"),
        num_pesi_genes = n(),
        has_pESI = (repA_present & num_pesi_genes >= 3)
    )

genomes_with_pesi <- pesi_presence_table %>%
    filter(has_pESI) %>%
    select(genome_name)

if (snakemake@params[["save_session"]]) {
    save.image(
        file = "determince_pesi_presence.RData"
    )
}

pesi_presence_table %>%
    write_tsv(
        snakemake@output[["pesi_presence_absence"]]
    )

genomes_with_pesi %>%
    write_tsv(
        snakemake@output[["genomes_with_pesi"]],
        col_names = FALSE
    )
