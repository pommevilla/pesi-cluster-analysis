###################
# Extracts pESI contigs from input genomes
# Author: Paul Villanueva
###################

configfile: "workflow/config.yml"
include: "common.smk"

rule all:
    input:
        # expand(
        #     "outputs/{run_name}/extract/{genome}/blast_results.tsv",
        #     run_name=RUN_NAME,
        #     genome=INPUT_GENOMES_NO_GZ
        # ),
        # "extract_test.txt",
        # expand(
        #     "outputs/{run_name}/extract/{genome}/pesi_contigs_list.txt",
        #     run_name=RUN_NAME,
        #     genome=INPUT_GENOMES_NO_GZ
        # ),
        expand(
            "outputs/{run_name}/extract/{genome}/{genome}.pesi.fasta",
            run_name=RUN_NAME,
            genome=INPUT_GENOMES_NO_GZ
        )

# Annotate the input sequence against the complete Infantis chromosomal and pESI genome
rule blast_infantis_chromosome_pesi:
    input:
        input_genome=lambda wildcards: os.path.join(
            config['inputs']['input_directory'],
            f"{wildcards.genome}.gz"
        )
    params:
        blast_db=config['blast']['infantis_pesi_genome_db'],
    output:
        blast_results="outputs/{run_name}/extract/{genome}/blast_results.tsv"
    log:
        out="logs/{run_name}/extract/{genome}/blast_infantis_chromosome_pesi.out",
        err="logs/{run_name}/extract/{genome}/blast_infantis_chromosome_pesi.err",
    conda:
        "../envs/extract.yml"
    script:
        "../scripts/extract/blast_helper.sh"

# Parse the BLAST results for only the pESI contigs
rule filter_pesi_contigs:
    input:
        blast_results="outputs/{run_name}/extract/{genome}/blast_results.tsv"
    output:
        pesi_contigs_list="outputs/{run_name}/extract/{genome}/pesi_contigs_list.txt"
    log:
        out="logs/{run_name}/extract/{genome}/filter_pesi_contigs.out",
        err="logs/{run_name}/extract/{genome}/filter_pesi_contigs.err"
    params:
        this_genome=lambda wildcards: wildcards.get("genome"),
        # Set to TRUE if you need to debug the R session
        save_session="FALSE"
    conda:
        "../envs/r-pesica.yml"
    script:
        "../scripts/extract/filter_pesi_contigs.R"

# Extract the pESI contigs from the input genome
rule extract_pesi_contigs:
    input:
        pesi_contigs_list="outputs/{run_name}/extract/{genome}/pesi_contigs_list.txt",
        fasta_file=lambda wildcards: os.path.join(
            config['inputs']['input_directory'],
            f"{wildcards.genome}.gz"
        )
    output:
        pesi_contigs="outputs/{run_name}/extract/{genome}/{genome}.pesi.fasta"
    log:
        out="logs/{run_name}/extract/{genome}/extract_pesi_contigs.out",
        err="logs/{run_name}/extract/{genome}/extract_pesi_contigs.err"
    conda:
        "../envs/extract.yml"
    shell:
        """
        seqtk subseq -l 0 {input.fasta_file} \
            {input.pesi_contigs_list} > {output.pesi_contigs}
        """
