# VIDRL repository for JEV virus phylogenetic pipelines

Created for the JEV Austrakka Portal.

This repository contains 3 workflows for the analysis of JEV virus data:

1. [`ingest/`](./ingest) - Download data from GenBank, clean and curate it
2. [`nextclade_data/`](./nextclade_data) - Create tree.json for nextclade data 
3. [`phylogenetic/`](./phylogenetic) - Make phylogenetic trees for each 
genotype

Each folder contains a README.md with more information.

### Install dependencies:

```
mamba env create -f conda.yaml
conda activate ev-inp
```

### To run a pipelines:

```
cd ingest
snakemake -j 8
```

Each pipeline must be run separately and in order `ingest` -> 
`nextclade_data` -> `phylogenetic`. The output of the final pipeline is an 
annotated, ancestrally reconstructed (`.json`) phylotree for each JEV 
genotype. Use `auspice.us` to view the trees. 

A nextclade dataset was created by running `ingest` -> `nextclade_data` to generate a nextclade dataset for genotyping and qcing. Remember to reset the date checked (see below).

`nextclade_data` can be skipped if you're only interested in phylogenetic analysis.


### Notes

- Some parts of the pipeline were written for the Austrakka platform.
- Phylogenetic trees are constructed using `HKY+G`
- Ancestral Reconstruction using TreeTime is done using the same settings as 
dengue.
- The `ingest` pipeline is designed to fetch only the latest data by checking when the last check was performed. For first time runs, set this date to `1900-01-01` in `ingest/resources/ncbi_date_last_checked.txt`.
- A nextclade dataset was generated using all high quality jev data as of May 2024. This can be found in `nextclade_dataset/resources/nc_dataset`.

