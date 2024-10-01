"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.
"""

rule export:
    """Exporting data files for auspice"""
    input:
        tree = rules.refine.output.tree,
        metadata = rules.filter.output.metadata,
        branch_lengths = rules.refine.output.node_data,
        traits = rules.traits.output.node_data,
        nt_muts = rules.ancestral.output.node_data,
        aa_muts = rules.translate.output.node_data,
        auspice_config = Path("config") / "auspice_config_all.json",
    output:
        auspice_json = OUTDIR / "auspice" / "jev{genotype}.json",
        root_sequence = OUTDIR / "auspice" / "jev{genotype}_root-sequence.json",
    params:
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """
