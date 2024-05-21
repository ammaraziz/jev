"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.
REQUIRED INPUTS:
    metadata_url    = url to metadata.tsv.zst
    sequences_url   = url to sequences.fasta.zst
    reference   = path to reference sequence or genbank
OUTPUTS:
    prepared_sequences = results/aligned.fasta
"""

OUTDIR = Path("output")
INDIR = Path("indir")

# you must be logged into the server to run this pipeline or this step fails
rule get_austrakka_sequences:
    message:"Retreiving Austrakka data"
    input:
        sequences = Path(config['austrakka']['data_location']) / "all.fasta"
        metadata = Path(config['austrakka']['data_location']) / "all.tsv"
    output:
        sequences = INDIR / "data" / "austrakka_sequences_raw.fasta",
        metadata = INDIR / "data" / "metadata_all.tsv"
    shell:
        """
        cp {input.sequences} {output.sequences}
        cp {out.metadata} {out.metadata}
        """

# new rule to genotype and qc sequences ?????
# maybe this should be in ingest???
rule qc:
    message: "Running nextclade to genotype and qc sequences"
    input:
        sequences = rules.get_austrakka_sequences.output.sequences
    output:
        tsv = OUTDIR / "nextclade" / "nextclade.tsv"
    params:
        nextclade_dataset = config['nextclade']['dataset_location']
    threads: config['threads']['nextclade']
    shell:"""
    nextclade3 run \
        --input-dataset {params.nextclade_dataset} \
        --jobs {threads} \
        {input.sequences} \
        --retry-reverse-complement \
        --gap-alignment-side left \
        --output-tsv {output.tsv} \
    """
# new rule filter_len+split by genotype to create JEV1/2/3/4/5


# rule decompress:
#     """Parsing fasta into sequences and metadata"""
#     input:
#         sequences = "data/sequences_{serotype}.fasta.zst",
#         metadata = "data/metadata_{serotype}.tsv.zst"
#     output:
#         sequences = "data/sequences_{serotype}.fasta",
#         metadata = "data/metadata_{serotype}.tsv"
#     shell:
#         """
#         zstd -d -c {input.sequences} > {output.sequences}
#         zstd -d -c {input.metadata} > {output.metadata}
#         """

# remove all filtering apart from sequence length
rule filter:
    """
    Filtering to
      - {params.sequences_per_group} sequence(s) per {params.group_by!s}
      - excluding strains in {input.exclude}
      - minimum genome length of {params.min_length}
      - excluding strains with missing region, country or date metadata
    """
    input:
        sequences = "data/sequences_{serotype}.fasta",
        metadata = "data/metadata_{serotype}.tsv",
        exclude = config["filter"]["exclude"],
    output:
        sequences = "results/filtered_{serotype}.fasta"
    params:
        group_by = config['filter']['group_by'],
        sequences_per_group = lambda wildcards: config['filter']['sequences_per_group'][wildcards.serotype],
        min_length = config['filter']['min_length'],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --exclude {input.exclude} \
            --output {output.sequences} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group} \
            --min-length {params.min_length} \
            --exclude-where country=? region=? date=? \
        """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/filtered_{serotype}.fasta",
        reference = "config/reference_dengue_{serotype}.gb"
    output:
        alignment = "results/aligned_{serotype}.fasta"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --fill-gaps \
            --remove-reference \
            --nthreads 1
        """
