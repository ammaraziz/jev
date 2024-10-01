"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

Your sequences should be be in input/sequences.fasta
Include a input/metadata.tsv with at minimum these headings: 
 - strain
 - date
 - country
 - host 
"""

OUTDIR = Path("output")
INDIR = Path("input")

# you must be logged into the server to run this pipeline or this step fails
# checks if config variable austrakka is sset

rule nextclade:
    message: "Running nextclade to genotype and qc input sequences"
    input:
        sequences = INDIR / "sequences"
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
        --output-tsv - | \
        csvtk -t cut \
        -f 'seqName,clade,qc.overallStatus' > {output.tsv}
    """

rule create_metadata:
    input:
        clades = rules.nextclade.output.tsv,
        metadata = INDIR / "metadata.tsv",
    output:
        metadata = OUTDIR / "metadata.tsv",
    shell:"""
    csvtk -t join \
        --left-join \
        --fields "1;1" \
        {input.clades} {input.metadata} > {output.metadata}
    """

rule filter:
    """
    Filtering to
      - {params.sequences_per_group} sequence(s) per {params.group_by!s}
      - excluding strains in {input.exclude}
      - minimum genome length of {params.min_length}
    """
    input:
        sequences = INDIR / "sequences.fasta",
        metadata = rules.create_metadata.output.metadata,
    output:
        sequences = "results/filtered_{genotype}.fasta"
    params:
        group_by = config['filter']['group_by'],
        min_length = config['filter']['min_length'],
        strain_id = config.get("strain_id_field", "strain"),
        exclude = config["filter"]["exclude"],
    shell:"""
    augur filter \
        --sequences {input.sequences} \
        --metadata {input.metadata} \
        --metadata-id-columns {params.strain_id} \
        --exclude {input.exclude} \
        --output {output.sequences} \
        --group-by {params.group_by} \
        --sequences-per-group {params.sequences_per_group} \
        --min-length {params.min_length} \
        --exclude-where country=? region=? date=?
        """

rule conglomerate:
    input:
        at_seq = rules.get_austrakka_sequences.output.sequence,
        at_meta = rules.get_austrakka_sequences.output.metadata,
        ncbi_seq = rules.get_ncbi_data.output.sequence,
        ncbi_meta = rules.get_ncbi_data.output.metadata,
    output:
        sequences = OUTDIR / "data" / "sequences.all.fasta",
        metadata = OUTDIR / "data" / "metadata.all.tsv"
    shell:"""
    cp {at_seq} {ncbi_seq} > {output.sequences}
    csvtk -t concat {at_metadata} {ncbi_metadata} > {output.metadata}
    """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/filtered_{genotype}.fasta",
        reference = "config/reference_dengue_{genotype}.gb"
    output:
        alignment = "results/aligned_{genotype}.fasta"
    shell:"""
    augur align \
        --sequences {input.sequences} \
        --reference-sequence {input.reference} \
        --output {output.alignment} \
        --fill-gaps \
        --remove-reference \
        --nthreads 1
        """
