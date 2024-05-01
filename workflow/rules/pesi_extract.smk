###################
# If pESI was determined to be present in pESI_screen.smk, we will extract the pESI
# contigs in this step
# Author: Paul Villanueva
###################

configfile: "workflow/config.yml"
include: "common.smk"

rule all:
    input:
        # expand(
        #     "outputs/{run_name}/pesi_extract/{genome}/blast_results.tsv",
        #     run_name=RUN_NAME,
        #     genome=INPUT_GENOMES_NO_GZ
        # ),
        # "extract_test.txt",
        # expand(
        #     "outputs/{run_name}/pesi_extract/{genome}/pesi_contigs_list.txt",
        #     run_name=RUN_NAME,
        #     genome=INPUT_GENOMES_NO_GZ
        # ),
        expand(
            "outputs/{run_name}/pesi_extract/{genome}/{genome}.pesi.fasta",
            run_name=RUN_NAME,
            genome=INPUT_GENOMES_NO_GZ
        )

rule test:
    output:
        outfile="extract_test.txt"
    params:
        snakedict=config,
        input_genomes=INPUT_GENOMES,
        input_genomes_no_gz=INPUT_GENOMES_NO_GZ,
        input_genomes_paths=INPUT_GENOMES_PATHS,
    script:
        "../scripts/tester.py"

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
        blast_results="outputs/{run_name}/pesi_extract/{genome}/blast_results.tsv"
    log:
        out="logs/{run_name}/pesi_extract/{genome}/blast_infantis_chromosome_pesi.out",
        err="logs/{run_name}/pesi_extract/{genome}/blast_infantis_chromosome_pesi.err",
    conda:
        "../envs/extract.yml"
    script:
        "../scripts/pesi_extract/blast_helper.sh"

rule filter_pesi_contigs:
    input:
        blast_results="outputs/{run_name}/pesi_extract/{genome}/blast_results.tsv"
    output:
        pesi_contigs_list="outputs/{run_name}/pesi_extract/{genome}/pesi_contigs_list.txt"
    log:
        out="logs/{run_name}/pesi_extract/{genome}/filter_pesi_contigs.out",
        err="logs/{run_name}/pesi_extract/{genome}/filter_pesi_contigs.err"
    params:
        this_genome=lambda wildcards: wildcards.get("genome"),
        # Set to TRUE if you need to debug the R session
        save_session="FALSE"
    conda:
        "../envs/r-pesica.yml"
    script:
        "../scripts/pesi_extract/filter_pesi_contigs.R"

rule extract_pesi_contigs:
    input:
        pesi_contigs_list="outputs/{run_name}/pesi_extract/{genome}/pesi_contigs_list.txt",
        fasta_file=lambda wildcards: os.path.join(
            config['inputs']['input_directory'],
            f"{wildcards.genome}.gz"
        )
    output:
        pesi_contigs="outputs/{run_name}/pesi_extract/{genome}/{genome}.pesi.fasta"
    log:
        out="logs/{run_name}/pesi_extract/{genome}/extract_pesi_contigs.out",
        err="logs/{run_name}/pesi_extract/{genome}/extract_pesi_contigs.err"
    conda:
        "../envs/extract.yml"
    shell:
        """
        seqtk subseq -l 0 {input.fasta_file} \
            {input.pesi_contigs_list} > {output.pesi_contigs}
        """

# # Parse the BLAST output from above to get only the contigs from the pESI genome, 
# # NOT the chromosome
# rule extract_pESI_contigs:
#     input:
#         blast_output="data/merged_data.csv"
#     output:
#         pESI_contigs="data/pESI_contigs.fasta"
#     log:
#         err="logs/pESI_extraction/extract_pESI_contigs.err",
#         out="logs/pESI_extraction/extract_pESI_contigs.out"
#     conda:
#         "../envs/bakta.yml"
#     shell:
#         """
#         echo "To be implemented"
#         """

# # Once we extract the pESI contigs from the input genome, reannoate the pESI contigs
# # against the pESI reference using the full bakta database
# rule complete_pESI_annotation:
#     input:
#         all_kmer_counts="data/all_kmer_counts.csv",
#     params:
#         target_column=config['phenotype']['target_column'],
#         chromsome_pesi_genome=config['blast']['infantis_pesi_genome_db']
#     output:
#         merged_data="data/merged_data.csv"
#     log:
#         err="logs/pESI_extraction/infantis_chromosome_pesi_annotation.err",
#         out="logs/pESI_extraction/infantis_chromosome_pesi_annotation.out"
#     conda:
#         "../envs/bakta.yml"
#     shell:
#         """
#         echo "To be implemented"
#         """
