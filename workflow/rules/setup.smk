###################
# Sets up the pipeline by downloading all virtual environments,
# setting up the blast db, and downloading the bakta dbs
# Outputs: 
#   * resources/dbs/complete_infantis_chrom_and_pesi_db/* - the decompressed BLAST db
# Author: Paul Villanueva
###################

configfile: "workflow/config.yml"
include: "common.smk"

rule all:
    input:
        # Uncompressed BLAST db
        expand(
            "resources/dbs/complete_infantis_chrom_and_pesi_db/complete_infantis_chrom_and_pESI.fasta.{ext}",
            ext=BLAST_DB_SUFFIXES
        ),
        # directory("resources/dbs/complete_infantis_chrom_and_pesi_db"),


# Decompress the included BLAST database
rule decompress_blast_db:
    input:
        blast_db_archive="resources/dbs/complete_infantis_chrom_and_pesi_db.tar.gz"
    output:
        expand(
            "resources/dbs/complete_infantis_chrom_and_pesi_db/complete_infantis_chrom_and_pESI.fasta.{ext}",
            ext=BLAST_DB_SUFFIXES
        ),
        "something"
    shell:
        """
        tar -xzf resources/dbs/complete_infantis_chrom_and_pesi_db.tar.gz -C resources/dbs
        """
