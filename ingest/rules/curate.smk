"""
This part of the workflow handles curating the data into standardized
formats and expects input file

    sequences_ndjson = "data/sequences.ndjson"

This will produce output files as

    metadata = "results/metadata_all.tsv"
    sequences = "results/sequences_all.fasta"

Parameters are expected to be defined in `config.curate`.
"""

rule fetch_general_geolocation_rules:
    output:
        general_geolocation_rules= OUTDIR / "data" / "general-geolocation-rules.tsv",
    params:
        geolocation_rules_url=config["curate"]["geolocation_rules_url"]
    log: OUTDIR / "logs" / "curl.txt"
    shell:"""
    curl {params.geolocation_rules_url} > {output.general_geolocation_rules} 2> {log}
    """

rule concat_geolocation_rules:
    input:
        general_geolocation_rules=OUTDIR / "data" / "general-geolocation-rules.tsv",
        local_geolocation_rules=config["curate"]["local_geolocation_rules"],
    output:
        all_geolocation_rules=OUTDIR / "data" / "all-geolocation-rules.tsv",
    shell:"""
    cat {input.general_geolocation_rules} {input.local_geolocation_rules} >> {output.all_geolocation_rules}
    """

def format_field_map(field_map: dict[str, str]) -> str:
    """
    Format dict to `"key1"="value1" "key2"="value2"...` for use in shell commands.
    """
    return " ".join([f'"{key}"="{value}"' for key, value in field_map.items()])

rule curate:
    input:
        sequences_ndjson=OUTDIR / "data" / "sequences.ndjson",
        all_geolocation_rules=OUTDIR / "data" / "all-geolocation-rules.tsv",
        annotations=config["curate"]["annotations"],
    output:
        metadata=OUTDIR / "data" / "metadata_all.tsv",
        sequences=OUTDIR / "results" / "sequences.fasta",
    log: OUTDIR / "logs" / "curate.txt",
    params:
        field_map=format_field_map(config["curate"]["field_map"]),
        strain_regex=config["curate"]["strain_regex"],
        strain_backup_fields=config["curate"]["strain_backup_fields"],
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
        articles=config["curate"]["titlecase"]["articles"],
        abbreviations=config["curate"]["titlecase"]["abbreviations"],
        titlecase_fields=config["curate"]["titlecase"]["fields"],
        authors_field=config["curate"]["authors_field"],
        authors_default_value=config["curate"]["authors_default_value"],
        abbr_authors_field=config["curate"]["abbr_authors_field"],
        annotations_id=config["curate"]["annotations_id"],
        metadata_columns=config["curate"]["metadata_columns"],
        id_field=config["curate"]["id_field"],
        sequence_field=config["curate"]["sequence_field"],
    shell:"""
    (cat {input.sequences_ndjson} \
        | ./vendored/transform-field-names \
            --field-map {params.field_map} \
        | augur curate normalize-strings \
        | ./vendored/transform-strain-names \
            --strain-regex {params.strain_regex} \
            --backup-fields {params.strain_backup_fields} \
        | augur curate format-dates \
            --date-fields {params.date_fields} \
            --expected-date-formats {params.expected_date_formats} \
        | ./vendored/transform-genbank-location \
        | augur curate titlecase \
            --titlecase-fields {params.titlecase_fields} \
            --articles {params.articles} \
            --abbreviations {params.abbreviations} \
        | ./vendored/transform-authors \
            --authors-field {params.authors_field} \
            --default-value {params.authors_default_value} \
            --abbr-authors-field {params.abbr_authors_field} \
        | ./vendored/apply-geolocation-rules \
            --geolocation-rules {input.all_geolocation_rules} \
        | ./vendored/merge-user-metadata \
            --annotations {input.annotations} \
            --id-field {params.annotations_id} \
        | ./bin/ndjson-to-tsv-and-fasta \
            --metadata-columns {params.metadata_columns} \
            --metadata {output.metadata} \
            --fasta {output.sequences} \
            --id-field {params.id_field} \
            --sequence-field {params.sequence_field} ) 2>> {log}
    """
