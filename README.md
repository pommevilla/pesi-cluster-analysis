# pESI Cluster Analysis

Given a Salmonella genome, this workflow will determine if infantis pESI is present in the genome, and, if so, will ordinate it into an existing cluster.


## Inputs

* Salmonella genome

## Outputs

* 

## Workflow

* Pull pESI out
* Annotate pESI with bakta
* Add pESI into existing pangenome
    * This creates a gene presence absence vector
* Figure out n nearest neighbors in pangenome space
* In tSNE space, average the coordinates of those nearest neighbors
* After putting it into tSNE space, assign cluster number based on tSNE nearest neighbors
