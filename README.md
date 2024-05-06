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

## Usage

* Salmonella genome

## Workflow details

This is comprised of three subworkflows:

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

## FAQ

### I get "OSError: [Errno 39] Directory not empty: 'envs'" when I run the pipeline

This error appears to mostly occur when a dry-run is attempted (ie, `snakemake -np`). This error should not impact the actual runs of the pipeline.

