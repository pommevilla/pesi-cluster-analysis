###################
# Extracts pESI contigs from the input genomes that pESI was found in
# Inputs: 
#   * a directory of genomes (ending with gz for now)
#   * outputs/{run_name}/screen/genomes_with_pesi.txt
#       * the list of genomes that have the pESI plasmid
# Outputs: 
#   * outputs/{run_name}:
#       * pesi_genomes/ - the pESI contigs extracted from the input genomes
#       * pesi_annotations/ - output from running full bakta annotation on the pesi_genomes
# Author: Paul Villanueva
###################

configfile: "workflow/config.yml"
include: "common.smk"

# Getting the list of genomes with pESI in it
genomes_with_pesi_list = os.path.join(
    "outputs",
    RUN_NAME,
    "screen",
    "genomes_with_pesi.txt"
)
GENOMES_WITH_PESI = [fname.strip() for fname in open(genomes_with_pesi_list).readlines()]

rule all:
    input:
        # FASTA files containing only the pESI contigs within that genome
        expand(
            "outputs/{run_name}/pesi_genomes/{genome}.pesi.fasta",
            run_name=RUN_NAME,
            genome=GENOMES_WITH_PESI
        ),

        # The full BAKTA annotations of the above contigs
        expand(
            "outputs/{run_name}/pesi_annotations/{genome}.pesi/{genome}.pesi.tsv",
            run_name=RUN_NAME,
            genome=GENOMES_WITH_PESI
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
# TODO: Convert to a shell script
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
        pesi_contigs="outputs/{run_name}/pesi_genomes/{genome}.pesi.fasta"
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

# Full bakta annotation on the pESI contig files extracted above
rule full_bakta_annotation:
    input:
        pesi_contigs="outputs/{run_name}/pesi_genomes/{genome}.pesi.fasta"
    output:
        full_pesi_annotations="outputs/{run_name}/pesi_annotations/{genome}.pesi/{genome}.pesi.tsv"
    log:
        out="logs/{run_name}/pesi_annotations/{genome}.full_bakta_annotation.out",
        err="logs/{run_name}/pesi_annotations/{genome}.full_bakta_annotation.err"
    params:
        full_db=config['bakta']['full_db'],
        pesi_reference=config['references']['annotated_pesi'],
    conda:
        "../envs/bakta.yml"
    threads: 12
    shell:
        """
        echo "{wildcards.run_name}: Running bakta on {wildcards.genome} against pESI genome"
        bakta --db {params.full_db} \
            --output outputs/{wildcards.run_name}/pesi_annotations/{wildcards.genome}.pesi \
            --skip-plot \
            --keep-contig-headers \
            --threads {threads} \
            --proteins {params.pesi_reference} \
            --force \
            {input.pesi_contigs} 1> {log.out} 2> {log.err} && \
        echo "Finished annotation"
        """
