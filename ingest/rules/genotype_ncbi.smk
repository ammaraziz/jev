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
        sequences=OUTDIR / "results" / "sequences.fasta",
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
        metadata=OUTDIR / "data" / "metadata_all.tsv",
        nextclade_results=rules.genotype.output.results,
    output:
        metadata=OUTDIR / "data" / "metadata_all_nc.tsv",
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
        --fields "1;1" \
    | csvtk -t replace \
        -f {params.nextclade_filter_fields:q} \
        -p "^$" \
        -r "Failed" \
    --out-file {output.metadata}
    """

rule append_countrycodes:
    input:
        metadata=rules.append_nextclade_columns.output.metadata,
        country=RESOURCES / "country_codes.tsv"
    output:
        metadata=OUTDIR / "results" / "metadata.tsv"
    shell:"""
    csvtk -t join \
        --left-join \
        {input.metadata} {input.country} \
        --fields "country" > {output.metadata}
    """

rule austrakka:
    message: "Formatting metadata for austrakka submission"
    input:
        metadata=rules.append_countrycodes.output.metadata
    output:
         metadata=OUTDIR / "results" / "austrakka.csv"
    params:
        cut="strain,date,genbank_accession_rev,country_short,host",
        rename="Seq_ID,Date_coll,Sample_ID,Country,Host"
    shell:"""
    csvtk -t cut \
    {input.metadata} \
    --fields {params.cut:q} | \
    csvtk -t rename \
    --fields {params.cut:q} \
    --names {params.rename:q} | \
    csvtk -t mutate2 --name "Species" --expression " 'JEV' " | \
    csvtk -t mutate2 --name "Owner_group" --expression " 'INSDC-Owner' " | \
    csvtk -t mutate2 --name "Shared_groups" --expression " 'JEV-Group' " | \
    csvtk -t mutate2 --name "Jurisdiction" --expression " '' " | \
    csvtk -t mutate2 --name "Age_group" --expression " '' " | \
    csvtk -t mutate2 --name "Date_onset" --expression " '' " | \
    csvtk -t mutate2 --name "Location_of_acquisition" --expression " '' " | \
    csvtk -t mutate2 --name "LGA" --expression " '' " | \
    csvtk -t mutate2 --name "Livestock_age_class" --expression " '' " | \
    csvtk -t mutate2 --name "Epidemiological_unit" --expression " '' " | \
    csvtk tab2csv \
    --out-file {output.metadata}
    """

# rule split_sequences_by_genotype:
#     """
#     Split the data by genotype based on the NCBI metadata.
#     """
#     input:
#         metadata = OUTDIR / "results" / "metadata_final.tsv",
#         sequences = OUTDIR / "results" / "sequences_all.fasta"
#     output:
#         sequences = OUTDIR / "results" / "by_genotype" / "jev_gt{genotype}.fasta",
#         metadata = OUTDIR / "results" / "by_genotype" / "jev_gt{genotype}.tsv"
#     params:
#         id_field="strain",
#         filter_by = lambda w: "clade==" + w.genotype + "    "
#     log: OUTDIR / "logs" / "augur.{genotype}.log.txt"
#     shell:"""
#     augur filter \
#         --sequences {input.sequences} \
#         --metadata {input.metadata} \
#         --metadata-id-columns {params.id_field} \
#         --query "{params.filter_by}" \
#         --empty-output-reporting silent \
#         --output-sequences {output.sequences} \
#         --output-metadata {output.metadata} > {log} 2>&1
#     """

# rule clean_empty_sequences:
#     """
#     Removing empty sequences
#     """
#     input:
#         sequences = OUTDIR / "results" / "by_genotype" / "jev_gt{genotype}.fasta"
#     output:
#         status = OUTDIR / "results" / "by_genotype" / "{genotype}.status"
#     params:
#         indir = OUTDIR / "results" / "by_genotype"
#     shell:"""
#     find {params.indir} -iname "*.txt" -type f -empty -delete
#     find {params.indir} -iname "*.fasta" -type f -empty -delete
#     touch {output.status}
#     """
