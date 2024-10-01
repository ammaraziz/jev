"""
This part of the workflow creates additonal annotations for the phylogenetic tree.
REQUIRED INPUTS:
    metadata            = data/metadata_all.tsv
    prepared_sequences  = results/aligned.fasta
    tree                = results/tree.nwk
OUTPUTS:
    node_data = results/*.json
    There are no required outputs for this part of the workflow as it depends
    on which annotations are created. All outputs are expected to be node data
    JSON files that can be fed into `augur export`.
    See Nextstrain's data format docs for more details on node data JSONs:
    https://docs.nextstrain.org/page/reference/data-formats.html
This part of the workflow usually includes the following steps:
    - augur traits
    - augur ancestral
    - augur translate
    - augur clades
See Augur's usage docs for these commands for more details.
Custom node data files can also be produced by build-specific scripts in addition
to the ones produced by Augur commands.
"""

rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree = OUTDIR / "results" / "tree_jev{genotype}.nwk",
        alignment = OUTDIR / "results" / "aligned_jev{genotype}.fasta"
    output:
        node_data = OUTDIR / "results" / "nt-muts_jev{genotype}.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    """Translating amino acid sequences"""
    input:
        tree = OUTDIR / "results" / "tree_jev{genotype}.nwk",
        node_data = OUTDIR / "results" / "nt-muts_jev{genotype}.json",
        reference = Path("resources") / "references" / "jev_gt{genotype}.gb"
    output:
        node_data = OUTDIR / "results" / "aa-muts_jev{genotype}.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data} \
        """

rule traits:
    """
    Inferring ancestral traits for {params.columns!s}
      - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
    """
    input:
        tree = rules.refine.output.tree,
        metadata = rules.filter.output.metadata,
    output:
        node_data = OUTDIR / "results" / "traits_jev_gt{genotype}.json",
    params:
        columns = lambda w: config['traits']['traits_columns'][f"gt{w.genotype}"],
        sampling_bias_correction = config['traits']['sampling_bias_correction'],
        strain_id = config.get("strain_id_field", "strain"),
    shell:"""
    augur traits \
        --tree {input.tree} \
        --metadata {input.metadata} \
        --metadata-id-columns {params.strain_id} \
        --output {output.node_data} \
        --columns {params.columns} \
        --confidence \
        --sampling-bias-correction {params.sampling_bias_correction}
    """