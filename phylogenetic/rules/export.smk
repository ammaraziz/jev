"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.
REQUIRED INPUTS:
    metadata        = data/metadata_all.tsv
    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json
    node_data       = results/*.json
OUTPUTS:
    auspice_json = auspice/${build_name}.json
    There are optional sidecar JSON files that can be exported as part of the dataset.
    See Nextstrain's data format docs for more details on sidecar files:
    https://docs.nextstrain.org/page/reference/data-formats.html
This part of the workflow usually includes the following steps:
    - augur export v2
    - augur frequencies
See Augur's usage docs for these commands for more details.
"""

rule export:
    """Exporting data files for auspice"""
    input:
        tree = "results/tree_{genotype}.nwk",
        metadata = "data/metadata_{genotype}.tsv",
        branch_lengths = "results/branch-lengths_{genotype}.json",
        traits = "results/traits_{genotype}.json",
        clades = "results/clades_{genotype}.json",
        nt_muts = "results/nt-muts_{genotype}.json",
        aa_muts = "results/aa-muts_{genotype}.json",
        auspice_config = "config/auspice_config_{genotype}.json",
    output:
        auspice_json = "results/raw_dengue_{genotype}.json",
        root_sequence = "results/raw_dengue_{genotype}_root-sequence.json",
    params:
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --node-data {input.branch_lengths} {input.traits} {input.clades} {input.nt_muts} {input.aa_muts} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """

rule final_strain_name:
    input:
        auspice_json="results/raw_dengue_{genotype}.json",
        metadata="data/metadata_{genotype}.tsv",
        root_sequence="results/raw_dengue_{genotype}_root-sequence.json",
    output:
        auspice_json="auspice/dengue_{genotype}.json",
        root_sequence="auspice/dengue_{genotype}_root-sequence.json",
    params:
        strain_id=config.get("strain_id_field", "strain"),
        display_strain_field=config.get("display_strain_field", "strain"),
    shell:
        """
        python3 bin/set_final_strain_name.py \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --input-auspice-json {input.auspice_json} \
            --display-strain-name {params.display_strain_field} \
            --output {output.auspice_json}
        cp {input.root_sequence} {output.root_sequence}
        """
