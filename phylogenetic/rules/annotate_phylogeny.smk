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
        tree = "results/tree_{genotype}.nwk",
        alignment = "results/aligned_{genotype}.fasta"
    output:
        node_data = "results/nt-muts_{genotype}.json"
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
        tree = "results/tree_{genotype}.nwk",
        node_data = "results/nt-muts_{genotype}.json",
        reference = "config/reference_dengue_{genotype}.gb"
    output:
        node_data = "results/aa-muts_{genotype}.json"
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
        tree = "results/tree_{genotype}.nwk",
        metadata = "data/metadata_{genotype}.tsv"
    output:
        node_data = "results/traits_{genotype}.json",
    params:
        columns = lambda wildcards: config['traits']['traits_columns'][wildcards.genotype],
        sampling_bias_correction = config['traits']['sampling_bias_correction'],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output {output.node_data} \
            --columns {params.columns} \
            --confidence \
            --sampling-bias-correction {params.sampling_bias_correction}
        """

rule clades:
    """Annotating genotypes / genotypes"""
    input:
        tree = "results/tree_{genotype}.nwk",
        nt_muts = "results/nt-muts_{genotype}.json",
        aa_muts = "results/aa-muts_{genotype}.json",
        clade_defs = lambda wildcards: config['clades']['clade_definitions'][wildcards.genotype],
    output:
        clades = "results/clades_{genotype}.json"
    shell:
        """
        augur clades \
            --tree {input.tree} \
            --mutations {input.nt_muts} {input.aa_muts} \
            --clades {input.clade_defs} \
            --output {output.clades}
        """
