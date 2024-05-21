"""
REQUIRED INPUTS:
    metadata    = data/metadata_all.tsv
    sequences   = results/sequences_{serotype}.fasta
    nextclade_datasets = ../nextclade_data/jev
OUTPUTS:
    metadata        = results/metadata_{genotype}.tsv
    nextclade       = results/nextclade_subtypes.tsv
"""

rule genotype:
    message: "Running Nextclade"
    input:
        sequences=OUTDIR / "results" / "sequences_all.fasta",
        dataset="resources/nc_dataset/",
    output:
        results=OUTDIR / "data" / "nextclade_results" / "nextclade.tsv",
    threads: 4
    params:
        min_seed_cover=config["nextclade"]["min_seed_cover"],
    shell:"""
    nextclade run \
        --input-dataset {input.dataset} \
        --jobs {threads} \
        --output-tsv {output.results} \
        --min-seed-cover {params.min_seed_cover} \
        --silent \
        {input.sequences}
    """

rule append_nextclade_columns:
    message: "Append the nextclade results to the metadata"
    input:
        metadata=OUTDIR / "results" / "metadata_all.tsv",
        nextclade_results=rules.genotype.output.results,
    output:
        metadata=OUTDIR / "results" / "metadata_final.tsv",
    params:
        id_field=config["curate"]["id_field"],
        nextclade_fields=config["nextclade"]["nextclade_fields"],
        nextclade_filter_fields="clade,qc.overallStatus"
    # cut clades, left-join with metadata, replace empty strings with NA using csvtk
    shell:"""
    csvtk -t cut \
        -f {params.nextclade_fields:q} \
        {input.nextclade_results} \
    | csvtk -t join \
        {input.metadata} - \
        --left-join \
        -f "1;1" \
    | csvtk -t replace \
        -f {params.nextclade_filter_fields:q} \
        -p "^$" \
        -r "Failed" \
    --out-file {output.metadata}
    """

rule split_metadata_by_genotype:
    message: "Split metadata by genotype"
    input:
        metadata=rules.append_nextclade_columns.output.metadata
    output:
        status = temp(OUTDIR / "results" / "split.status.txt")
    params:
        nextclade_clade_column="clade",
        split_out_directory=OUTDIR / "results" / "by_genotype",
        genotype_metadata=OUTDIR / "results" / "metadata_gt{genotype}.tsv",
        data_loc = OUTDIR / "results" / "by_genotype"
    shell:"""
    csvtk -t split \
        {input.metadata} \
        --fields {params.nextclade_clade_column} \
        --out-file {params.split_out_directory}
    
    for f in {params.data_loc}/*.tsv; do mv $f ${{f/_final-/_gt}}; done

    touch {output.status}
    """

rule split_sequences_by_genotype:
    """
    Split the data by genotype based on the NCBI metadata.
    """
    input:
        metadata = OUTDIR / "results" / "metadata_final.tsv",
        sequences = OUTDIR / "results" / "sequences_all.fasta"
    output:
        sequences = OUTDIR / "results" / "by_genotype" / "sequences_gt{genotype}.fasta"
    params:
        id_field="Seq_ID",
        filter_by = lambda w: "clade=='" + w.genotype + "'"
    log: OUTDIR / "logs" / "augur.{genotype}.log.txt"
    shell:"""
    augur filter \
        --sequences {input.sequences} \
        --metadata {input.metadata} \
        --metadata-id-columns {params.id_field} \
        --query "{params.filter_by}" \
        --output-sequences {output.sequences} > {log} 2>&1
    """