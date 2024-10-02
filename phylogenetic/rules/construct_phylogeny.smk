"""
This part of the workflow constructs the phylogenetic tree.
REQUIRED INPUTS:
    metadata            = data/metadata_all.tsv
    prepared_sequences  = results/aligned_genotype.fasta
"""

rule tree:
    """Building tree"""
    input:
        alignment = rules.align.output.alignment
    output:
        tree = OUTDIR / "jev{genotype}" / "tree-raw_jev{genotype}.nwk"
    params:
        substitution = config['iqtree_model']
    threads: config['threads']['tree']
    shell:"""
    augur tree \
        --alignment {input.alignment} \
        --output {output.tree} \
        --nthreads {threads} \
        --override-default-args \
        --substitution-model {params.substitution}
    """

rule refine:
    """
    Refining tree
      - estimate timetree
      - use {params.coalescent} coalescent timescale
      - estimate {params.date_inference} node dates
      - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
    """
    input:
        tree = rules.tree.output.tree,
        alignment = rules.align.output.alignment,
        metadata = rules.conglomerate.output.all_metadata
    output:
        tree = OUTDIR / "jev{genotype}" / "tree_jev{genotype}.nwk",
        node_data = OUTDIR / "jev{genotype}" / "branch-lengths_jev{genotype}.json",
    params:
        coalescent = "const",
        date_inference = "marginal",
        strain_id = "strain",
        clockrate = lambda w: config['clockrate'][f"gt{w.genotype}"],
        divergence_units = "mutations-per-site",
    shell:"""
    augur refine \
        --tree {input.tree} \
        --alignment {input.alignment} \
        --metadata {input.metadata} \
        --metadata-id-columns {params.strain_id} \
        --output-tree {output.tree} \
        --output-node-data {output.node_data} \
        --timetree \
        --stochastic-resolve \
        --clock-rate {params.clockrate} \
        --coalescent {params.coalescent} \
        --date-confidence \
        --date-inference {params.date_inference}
        """