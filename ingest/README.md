# JEV NCBI Ingest Pipeline

This is the ingest pipeline for JEV virus sequences. Amended from Nextstrain Dengue Ingest pipeline.

## Usage

All workflows are expected to the be run from the top level pathogen repo directory.
The default ingest workflow should be run with

This will produce 10 files (within the `ingest` directory):

A pair of files with all the dengue sequences:

- `ingest/results/metadata_all.tsv`
- `ingest/results/sequences_all.fasta`

A pair of files for each dengue serotype (denv1 - denv4)

- `ingest/results/metadata_denv1.tsv`
- `ingest/results/sequences_denv1.fasta`
- `ingest/results/metadata_denv2.tsv`
- `ingest/results/sequences_denv2.fasta`
- `ingest/results/metadata_denv3.tsv`
- `ingest/results/sequences_denv3.fasta`
- `ingest/results/metadata_denv4.tsv`
- `ingest/results/sequences_denv4.fasta`


### Adding new sequences not from GenBank

#### Static Files

Do the following to include sequences from static FASTA files.

1. Convert the FASTA files to NDJSON files with:

    ```sh
    ./ingest/bin/fasta-to-ndjson \
        --fasta {path-to-fasta-file} \
        --fields {fasta-header-field-names} \
        --separator {field-separator-in-header} \
        --exclude {fields-to-exclude-in-output} \
        > ingest/data/{file-name}.ndjson
    ```

2. Add the following to the `.gitignore` to allow the file to be included in the repo:

    ```gitignore
    !ingest/data/{file-name}.ndjson
    ```

3. Add the `file-name` (without the `.ndjson` extension) as a source to `ingest/defaults/config.yaml`. This will tell the ingest pipeline to concatenate the records to the GenBank sequences and run them through the same transform pipeline.

## Configuration

Configuration takes place in `defaults/config.yaml` by default.
Optional configs for uploading files are in `build-configs/nextstrain-automation/config.yaml`.

## Input data

### GenBank data

GenBank sequences and metadata are fetched via [NCBI datasets](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/).

## `ingest/vendored`

This repository uses [`git subrepo`](https://github.com/ingydotnet/git-subrepo) to manage copies of ingest scripts in [ingest/vendored](./vendored), from [nextstrain/ingest](https://github.com/nextstrain/ingest).

See [vendored/README.md](vendored/README.md#vendoring) for instructions on how to update
the vendored scripts.
