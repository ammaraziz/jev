# Create Nextclade dataset for JEV

### Input

1. `genotypes.tsv`: Created manually from E gene phylogenetic tree.
2. `metadata_all.tsv`: Metadata of sequences, output of `ingest` pipeline.
3. `sequences_all.fasta`: NCBI sequences, output of `ingest` pipeline.

### Process

1. Filter with `seqkit` to remove gaps and odd viruses
2. Prealign with `Nextclade`
3. Align with `augur align`
4. Create phylotree with `augur tree`
5. Refine
6. Ancestral reconstruction
7. Amino acid translation of mutations
8. Infer traits: `region country clade_membership`
9. Finally export the `auspice` tree for Nextclade

Grab the output for `output/nc_dataset/` for the snakemake phylogenetic pipeline.