###################
# Screens the input genomes for the pESI plasmid
# Inputs: 
#   * a directory of genomes (ending with gz for now)
# Params:
#   * run_name: a unique identifier for the run
# Outputs: 
#   * infantis_genome_pESI_genes.tsv: filtered bakta output for all pESI genes found in inputs
#   * pesi_presence.tsv: tsv of genomes, repA presence, # pESI genes found, and whether pESI is present
#   * genomes_with_pesi.tsv: a list of genomes that have the pESI plasmid
# Author: Paul Villanueva
###################

configfile: "workflow/config.yml"
include: "common.smk"

rule all:
    input:
        # Outputs for the pesi screen
        # Quick bakta annotations
        expand(
            "outputs/{run_name}/screen/{genome}.bakta/{genome}.tsv", 
            run_name=RUN_NAME, 
            genome=INPUT_GENOMES_NO_GZ
        ),

        expand(
            "outputs/{run_name}/screen/{screen_summary}",
            run_name=RUN_NAME,
            screen_summary=["pesi_presence.tsv", "genomes_with_pesi.tsv"]
        )

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
        outfile="outputs/{run_name}/screen/{genome}.bakta/{genome}.tsv", 
    params:
        light_db=config['bakta']['light_db'],
        pesi_reference=config['references']['annotated_pesi'],
        # input_dir=config['inputs']['input_directory']
    log:
        err="logs/{run_name}/screen/{genome}/quick_pesi_annotation.err",
        out="logs/{run_name}/screen/{genome}/quick_pesi_annotation.out"
    conda:
        "../envs/bakta.yml"
    threads: 2
    shell:
        # Using force command here because snakemake automatically creates the output directory
        # which causes bakta to not run
        """
        echo "{wildcards.run_name}: Running bakta on {wildcards.genome} against pESI genome"
        bakta --db {params.light_db} \
            --output outputs/{wildcards.run_name}/screen/{wildcards.genome}.bakta \
            --keep-contig-headers \
            --proteins {params.pesi_reference} \
            --skip-trna --skip-tmrna --skip-rrna --skip-ncrna --skip-ncrna-region --skip-crispr \
            --skip-pseudo --skip-sorf --skip-gap --skip-ori --skip-plot  --force \
            {input.input_genome} 1> {log.out} 2> {log.err} && \
        echo "Finished annotation"
        """

# Parses the bakta output of the pESI screen for the 6 genes associated with pESI
rule parse_bakta_output:
    input:
        bakta_files=expand(
            "outputs/{run_name}/screen/{genome}.bakta/{genome}.tsv",
            run_name=RUN_NAME,
            genome=INPUT_GENOMES_NO_GZ
        )
        # bakta_file="outputs/{run_name}/screen/{genome}.bakta/{genome}.tsv"
    output:
        pesi_gene_info="outputs/{run_name}/screen/pesi_presence.tsv",
        genomes_with_pesi="outputs/{run_name}/screen/genomes_with_pesi.tsv",
    params:
        # See config for the list of pESI genes that we're looking for
        pesi_search_string=r"\|".join(PESI_GENES)
    log:
        err="logs/{run_name}/screen/parse_bakta_output.err",
        out="logs/{run_name}/screen/parse_bakta_output.out"
    shell:
        """
        echo "Parsing bakta output for pESI genes"
        echo "Using string {params.pesi_search_string}"

        rm -f {output.pesi_gene_info}
        echo -e "genome\thas_repA\tpesi_gene_count\thas_pesi" > {output.pesi_gene_info}
        
        rm -f {output.genomes_with_pesi} && touch {output.genomes_with_pesi}

        for file in {input.bakta_files}
        do
            this_file=$(basename $file .tsv)
            echo -e "Parsing $file"
            echo -e "\tShortened form: $this_file"
            repA_present=$(grep -q "pESI RepA" $file 2> /dev/null; echo $?)
            echo -e "\tRepA present: $repA_present"

            pesi_gene_counts=$(grep -c "{params.pesi_search_string}" $file || true)
            echo -e "\tNumber of pESI genes found: $pesi_gene_counts"


            if [[ $repA_present -eq 0 && $pesi_gene_counts -ge 2 ]]; then
                echo "$this_file" >> {output.genomes_with_pesi}
                has_pesi="TRUE"
            else
                has_pesi="FALSE"
            fi

            echo -e "$this_file\t$has_pesi\t$pesi_gene_counts\t$has_pesi" >> {output.pesi_gene_info}

            echo -e "\tFinished parsing $file"
            
        done 
        """
