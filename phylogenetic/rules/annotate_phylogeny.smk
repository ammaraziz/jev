"""
This part of the workflow creates additonal annotations for the phylogenetic tree.
OUTPUTS:
    node_data = results/*.json
    There are no required outputs for this part of the workflow as it depends
    on which annotations are created. All outputs are expected to be node data
    JSON files that can be fed into `augur export`.
    See Nextstrain's data format docs for more details on node data JSONs:
    https://docs.nextstrain.org/page/reference/data-formats.html
"""

rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree = OUTDIR / "jev{genotype}" / "tree_jev{genotype}.nwk",
        alignment = OUTDIR / "jev{genotype}" / "aligned_jev{genotype}.fasta"
    output:
        node_data = OUTDIR / "jev{genotype}" / "nt-muts_jev{genotype}.json"
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
        tree = OUTDIR / "jev{genotype}" / "tree_jev{genotype}.nwk",
        node_data = OUTDIR / "jev{genotype}" / "nt-muts_jev{genotype}.json",
        reference = Path("resources") / "references" / "jev_gt{genotype}.gb"
    output:
        node_data = OUTDIR / "jev{genotype}" / "aa-muts_jev{genotype}.json"
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
        node_data = OUTDIR / "jev{genotype}" / "traits_jev_gt{genotype}.json",
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