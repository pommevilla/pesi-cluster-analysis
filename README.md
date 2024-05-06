# pesica: *S. Infantis* <ins>pESI</ins> <ins>C</ins>luster <ins>A</ins>nalysis

Pesica is a collection of tools to detect and extract pESI plasmid contigs from *Salmonella Infantis* genomes, and to assign them to clusters based on presence/absence of genes in an existing pangenome. There are three steps in the pipeline:

* Screening: Detect the presence of marker genes in the input genomes that indicate the presence of the pESI plasmid
* Extraction: If pESI is detected in the previous step, extract the plasmid contigs from the input genomes and annotate them
* Ordination: Given a plasmid genome, insert it into an existing pangenome and cluster it into that pangenome.

## Contents

- [Setup](#setup)
- [Usage](#usage)
- [Workflow details](#workflow-details)
    - [Screen](#screen)
    - [Extract](#extract)
    - [Ordinate](#ordinate)
- [Programs and tools](#programs-and-tools)
- [FAQ](#faq)

## Setup

Pesica is a collection of snakemake workflows collected together with a command line interface. It is required to use `conda` (and recommended to use `mamba`) to use the pipeline in order to manage the various virtual environments.

* Create the pesica conda environment: `conda/mamba env create -f env.yml`
* Install the light and full dbs from bakta
    * See the [database download](https://github.com/oschwengers/bakta/blob/main/README.md#database-download) section of the Bakta README for instructions 
    * If you already have an existing bakta database, you can skip this step
* Edit `workflow/config.yml`. For basic uses of the workflow, you'll only need to edit the following:
    * `input_directory` is the directory that contains the genomes that you would like to run the pipeline on. 
        * For now, the pipeline has only been tested on `gzipped` files (ie, those ending in `gz`, *not* `tar.gz`). It should work for uncompressed fastas, but this hasn't been tested.
    * `run_name` can be whatever name you choose to help organize the workflow products inside the `outputs` directory. 
    * Edit the `light_db` and `full_db` paths in the `bakta` section with the path where you downloaded the bakta directories to. The `light_db` and `full_db` values should be absolute paths ending in `db-light` and `db`.
        * Example `shared/databases/db-light` or `shared/databases/db`
* Activate the virtual environment: `conda activate pesica`

## Example usage

After setting the config values and activating the `pesica` virtual environment as described above, you should be able to run `pesica` using:

```bash
python pesica <subcommand> <options>
```

Here, `subcommand` is one of `screen`, `extract`, or `ordinate` (Note: for now, only `screen` and `extract` is implemented). Each subcommand (and `pesica` itself) as a `help` page that you can access with `--help` or `-h`:

```bash
python pesica --help
# To get help on the screen command:
python pesica screen -h
```

### Screening the input genomes for the pESI plasmid

To get started, run the `screen` command in `dry-run` mode by doing:

```bash
python pesica screen --dry-run 
# Alternatively:
python pesica screen -n
```

This will run the `screen` workflow in dry-run mode, which will show you the result of running the pipeline on the inputs without actually running it. If this exits without error, you can then run the pipeline by repeating the command without the dry run flag:

```bash
python pesica screen
```

Assuming everything completes correctly, you should see an output directory `outputs/<run_name>/screen`, where `run_name` is the name that was set in the `config.yml` file. This directory contains the following files:

* `<genome_name>.bakta` - A directory containing `bakta` outputs for each input genome. In particular, it contains `<genome_name>.tsv`, the gene annotations from `bakta` that will be parsed downstream
* `pesi_presence.tsv` - a tsv with a row for each input genome, with columns:
    * `genome` - the name of the genome
    * `has_repA` - whether or not the pESI repA gene was detected in the genome
    * `pesi_gene_count` - the number of pESI marker genes detected in the genome
    * `has_pesi` - whether or not the genome is predicted to contain pESI. This value is True if pESI repA was detected in the genome and there were at least 2 pESI marker genes detected in the genome
* `genomes_with_pesi.txt` - a list of the genomes that were predicted to contain pESI

### Extracting pESI plasmid genomes

After running this first step, we can now extract the plasmid genomes from the input genomes where pESI was detected with the `extract` subcommand. We first check that all the required files are present with a dry-run:

```bash
python pesica extract --dry-run
```

After checking for errors, we can run it with:

```bash
python pesica extract
```

This will output several files that are detailed in the [extract subcommand details](#extract), but the most important ones for the next steps are:

* `outputs/<run_name>/pesi_genomes` - a directory containing the plasmid genomes extracted from the input genomes
* `outputs/<run_name>/pesi_annotations` - directories containing the `bakta` annotations for the extracted plasmid genomes, which will be used in the `ordinate` step.

### Assigning the extracted pESI genome to a cluster

To be implemented.

### Notes

* Since these are just snakemake workflows with a basic CLI, the pipeline needs to be run from inside this directory.
* If you are familiar with snakemake, you can skip the CLI and run the workflow directly with your own commands and options. The commands should look something like `snakemake --use-conda --snakefile workflow/rules/<subcommand>.smk`, but you can add whatever options you want besides that.
* The `screen` step isn't too resource intensive, but the `extract` step can be. It is recommended to run it with more cores, such as through an interactive session (eg, `salloc -n 32`). Job submission to slurm will be added later.



## Workflow details

### Screen

Searches input sequences for pESI contigs.

### Extract

For those sequences found to contain pESI, the plasmid-only contigs will be extracted

### Ordinate

After extracting the pESI plasmid DNA, ordinate them into the existing clusters found in the paper

* Pull pESI out
* Annotate pESI with bakta
* Add pESI into existing pangenome
    * This creates a gene presence absence vector
* Figure out n nearest neighbors in pangenome space
* In tSNE space, average the coordinates of those nearest neighbors
* After putting it into tSNE space, assign cluster number based on tSNE nearest neighbors

## Programs and tools

* [Snakemake](https://snakemake.readthedocs.io/en/stable/) - workflow management
* [Click](https://click.palletsprojects.com/en/8.1.x/) - command line interface
* [Bakta](https://bakta.readthedocs.io/en/latest/index.html) - gene annotation
* [BLAST](https://www.ncbi.nlm.nih.gov/books/NBK279690/) - pESI gene search
* [Panaroo](https://github.com/gtonkinhill/panaroo) - pangenome insertion and clustering


## Upcoming features

* Documentation site
* HPC/Slurm support

## FAQ

### I get "OSError: [Errno 39] Directory not empty: 'envs'" when I run the pipeline

This error appears to mostly occur when a dry-run is attempted (ie, `snakemake -np`). This error should not impact the actual runs of the pipeline.

