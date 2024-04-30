###################
# Rules related to annotating data
# Author: Paul Villanueva
###################


# Use bakta to annotate the input data against a pESI genome
rule quick_pesi_annotation:
    input:
        # Looking for the version.json just to ensure the db is there
        # TODO: Maybe detect the correct version?
        light_db=os.path.join(config['bakta']['light_db'], "version.json"),
        input_genome=lambda wildcards: os.path.join(
            config['inputs']['input_directory'],
            f"{wildcards.genome}.gz"
        )
    output:
        outfile="outputs/{run_name}/pesi_screen/{genome}.bakta/{genome}.tsv", 
    params:
        light_db=config['bakta']['light_db'],
        pesi_reference=config['references']['annotated_pesi'],
        # input_dir=config['inputs']['input_directory']
    log:
        err="logs/{run_name}/pesi_screen/{genome}/quick_pesi_annotation.err",
        out="logs/{run_name}/pesi_screen/{genome}/quick_pesi_annotation.out"
    conda:
        "../envs/bakta.yml"
    threads: 2
    shell:
        # Using force command here because snakemake automatically creates the output directory
        # which causes bakta to not run
        """
        echo "{wildcards.run_name}: Running bakta on {wildcards.genome} against pESI genome"
        bakta --db {params.light_db} \
            --output outputs/{wildcards.run_name}/pesi_screen/{wildcards.genome}.bakta \
            --keep-contig-headers \
            --proteins {params.pesi_reference} \
            --skip-trna --skip-tmrna --skip-rrna --skip-ncrna --skip-ncrna-region --skip-crispr \
            --skip-pseudo --skip-sorf --skip-gap --skip-ori --skip-plot  --force \
            {input.input_genome} 1> {log.out} 2> {log.err} && \
        echo "Finished annotation"
        """

# Parses the bakta output of the pESI screen for the 6 genes associated with pESI
# TODO: change to an RScript
rule parse_bakta_output:
    input:
        bakta_files=expand(
            "outputs/{run_name}/pesi_screen/{genome}.bakta/{genome}.tsv",
            run_name=RUN_NAME,
            genome=INPUT_GENOMES_NO_GZ
        )
    output:
        gene_counts="outputs/{run_name}/pesi_screen/infantis_genome_pESI_genes.tsv"
    params:
        # See config for the list of pESI genes that we're looking for
        pesi_search_string=r"\|".join(PESI_GENES)
    # log:
    #     err="logs/{run_name}/pesi_screen/parse_bakta_output.err",
    #     out="logs/{run_name}/pesi_screen/parse_bakta_output.out"
    shell:
        """
        echo "Parsing bakta output for pESI genes"
        echo "Using string {params.pesi_search_string}"
        for file in {input.bakta_files}
        do
            this_file=$(basename $file .tsv)
            echo "Parsing $file"
            echo "Shortened form: $this_file"
            grep "{params.pesi_search_string}" $file | sed "s/^/$this_file\t/" >> {output.gene_counts}
        done 
        """

rule determine_pesi_presence:
    input:
        gene_counts="outputs/{run_name}/pesi_screen/infantis_genome_pESI_genes.tsv"
    output:
        pesi_presence_absence="outputs/{run_name}/pesi_screen/pesi_presence.tsv",
        genomes_with_pesi="outputs/{run_name}/pesi_screen/genomes_with_pesi.tsv",
    params:
        # Set to TRUE if you need to debug the R session
        save_session="FALSE"
    log:
        out="logs/{run_name}/pesi_screen/determine_pesi_presence.out",
        err="logs/{run_name}/pesi_screen/determine_pesi_presence.err"
    conda:
        "../envs/r-pesica.yml"
    script:
        "../scripts/pesi_screen/determine_pesi_presence.R"
