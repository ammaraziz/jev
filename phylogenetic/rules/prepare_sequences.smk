"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

Your sequences should be be in input/sequences_{genotype}.fasta
Include a input/metadata_{genotype}.tsv with at minimum these headings: 
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
