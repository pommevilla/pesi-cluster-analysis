# pesica: *S. Infantis* <u>pESI</u> <u>C</u>luster <u>A</u>nalysis

Given a Salmonella genome, this workflow will determine if infantis pESI is present in the genome, and, if so, will ordinate it into an existing cluster.

## Using the pipeline

* Install the light and full dbs from bakta
* Create a snakemake environment.
* Edit the config.yml
    * In particular....
* Run the steps of the pipeline

## Inputs

* Salmonella genome

## Workflow

This is comprised of three subworkflows:

### pESI screen

Searches input sequences for pESI contigs.

### pESI extraction

For those sequences found to contain pESI, the plasmid-only contigs will be extracted

### Cluster assignment

After extracting the pESI plasmid DNA, ordinate them into the existing clusters found in the paper

* Pull pESI out
* Annotate pESI with bakta
* Add pESI into existing pangenome
    * This creates a gene presence absence vector
* Figure out n nearest neighbors in pangenome space
* In tSNE space, average the coordinates of those nearest neighbors
* After putting it into tSNE space, assign cluster number based on tSNE nearest neighbors

## Troubleshooting

* Output of CheckM2
* Output of SeqSero2
* Do you have the full/light bakta dbs installed?

## FAQ

### I get "OSError: [Errno 39] Directory not empty: 'envs'" when I run the pipeline

This error appears to mostly occur when a dry-run is attempted (ie, `snakemake -np`). This error should not impact the actual runs of the pipeline
