"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.
"""

INDIR = Path("input")
OUTDIR = Path("output")

# you must be logged into the server to run this pipeline or this step fails
rule get_austrakka:
    message:"Retreiving Austrakka data"
    input:
        sequences = Path(config['datasets']['austrakka']) / "all.fasta",
        metadata = Path(config['datasets']['austrakka']) / "all.tsv",
    output:
        sequences = OUTDIR / "data" / "austrakka_sequences_raw.fasta",
        metadata = OUTDIR / "data" / "metadata_all.tsv",
    shell:"""
        cp {input.sequences} {output.sequences}
        cp {input.metadata} {output.metadata}
    """

rule nextclade:
    message: "Running nextclade to genotype and nextclade sequences"
    input:
        sequences = rules.get_austrakka.output.sequences,
    output:
        tsv = OUTDIR / "nextclade" / "nextclade.tsv",
    params:
        nextclade_dataset = config['datasets']['nextclade'],
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
        at_metadata = rules.get_austrakka.output.metadata,
        nextclade = rules.nextclade.output.tsv,
    output:
        metadata = OUTDIR / "metadata.tsv",
    shell:"""
    csvtk -t join --left-join \
    --fields "1;1" \
    {input.at_metadata} {input.nextclade} > {output.metadata}
    """

rule filter:
    input:
        metadata = rules.create_metadata.output.metadata,
        sequences = rules.get_austrakka.output.sequences,
    output:
        metadata = OUTDIR / "jev{genotype}" / "jev_gt{genotype}.tsv",
        sequences = OUTDIR / "jev{genotype}" / "jev_gt{genotype}.fasta",
    params:
        min_length = config['filter']['min_length'],
        strain_id = config.get("strain_id_field", "strain"),
        genotype_query = lambda w: "clade==" + w.genotype
    shell:"""
    augur filter \
        --sequences {input.sequences} \
        --metadata {input.metadata} \
        --metadata-id-columns {params.strain_id} \
        --query "{params.genotype_query}" \
        --output {output.sequences} \
        --output-metadata {output.metadata} \
        --min-length {params.min_length}
        """

rule conglomerate:
    input:
        input_seq = rules.filter.output.sequences,
        input_metadata = rules.filter.output.metadata,
        backbone_seq = Path("resources") / "backbone" / "jev_gt{genotype}.fasta",
        backbone_metadata = Path("resources") / "backbone" / "jev_gt{genotype}.tsv",
    output:
        all_seq = OUTDIR / "jev{genotype}" / "all.fasta",
        all_metadata = OUTDIR / "jev{genotype}" / "all.tsv",
    shell:"""
    seqkit seq {input.input_seq} {input.backbone_seq} > {output.all_seq}
    csvtk -t concat {input.backbone_metadata} {input.input_metadata} > {output.all_metadata}
    """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = rules.conglomerate.output.all_seq,
        reference = Path("resources") / "references" / "jev_gt{genotype}.gb"
    output:
        alignment = OUTDIR / "results" / "aligned_jev{genotype}.fasta"
    threads: 8
    shell:"""
    augur align \
        --sequences {input.sequences} \
        --reference-sequence {input.reference} \
        --output {output.alignment} \
        --fill-gaps \
        --remove-reference \
        --nthreads {threads}
    """