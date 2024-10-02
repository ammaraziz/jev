# VIDRL repository for JEV virus phylogenetic pipelines

Created for the JEV Austrakka Portal.

This repository contains 3 snakemake workflows for the analysis of JEV virus data:

1. [`ingest/`](./ingest) - Download data from GenBank, clean and curate it
2. [`nextclade_data/`](./nextclade_data) - Create tree.json for nextclade dataset 
3. [`phylogenetic/`](./phylogenetic) - Make phylogenetic trees for each 
genotype

### Install dependencies:

```
mamba env create -f conda.yaml
conda activate jev-inp
```

### To run a workflow:

```
cd ingest
snakemake -j 8
```

There are three options:

1. **Full workflow:** Each pipeline must be run separately and generally in this order `ingest` -> 
`nextclade_data` -> `phylogenetic`. The output of the final pipeline is an 
annotated, ancestrally reconstructed (`.json`) phylotree for each JEV 
genotype. Use auspice.us to view the trees.

2. **Update Nextclade dataset**: A nextclade dataset was created by running `ingest` -> `nextclade_data` to generate a nextclade dataset for genotyping and qcing. Unless large amounts of genomic data (eg for JEV5) are uploaded, there is no need to rerun these steps. 

3. **Create Phylogenies with new (user) sequences**:
 - You only need to run the `phylogenetics` workflow. Put all your sequences into a single `.fasta` file including different JEV genotypes. The pipeline QC and genotype your data then split as required.

 - Modify the `austrakka` value in `phylogenetics/config/config.yaml` to point towards your new sequences. You will need 2 files: `all.fasta` and `all.tsv`. `all.tsv` needs to contain the following columns: `Seq_ID, date, region, Country, Host`. See `phylogenetics/resources/example/` for an example.

 ```
datasets:
  nextclade: "../nextclade_dataset/resources/nc_dataset/"
  backbone: "resources/backbone/"
  austrakka: "PATH/TO/SEQUENCES/" # <- change this value!
 ```
 - Activate conda env:
 ```
 conda activate jev-inp
 ```
 - enter the `phylogenetic` directory and run the snakemake workflow:
 ```
 snakemake -j 8
 ```
 - The output of the pipeline will be in `output/auspice/`:
 ```
 jev1.json
 jev1_root-sequence.json
 jev2.json
 jev2_root-sequence.json
 jev3.json
 jev3_root-sequence.json
 jev4.json
 jev4_root-sequence.json
 jev5.json
 jev5_root-sequence.json
 ```
 - Drag and drop any of the `.json` files into auspice.us (ignore the `root-sequence.json`.) to visualise.
 - If you need the `newick` format, it will be in `output/jev{genotype}/tree_jev{genotype}.nwk`

### Notes

- Some parts of the pipeline were written for the Austrakka platform.
- Phylogenetic trees are constructed using `HKY+G`
- Ancestral Reconstruction using TreeTime is done using the same settings as 
dengue.
- The `ingest` pipeline is designed to fetch only the latest data by checking when the last check was performed. For first time runs, set this date to `1900-01-01` in `ingest/resources/ncbi_date_last_checked.txt`.
- A nextclade dataset was generated using all high quality jev data as of May 2024. This can be found in `nextclade_dataset/resources/nc_dataset`.
- Clockrates (in `phylogenetics/config/config.yaml`) were extracted from this [paper](https://www.biorxiv.org/content/10.1101/2024.03.27.586903v2):
```
  gt1: "4.13e-4"
  gt2: "2.41e-4"
  gt3: "6.17e-5"
  gt4: "2.41e-4"
  gt5: "2.41e-4"
```
