#!/usr/bin/env python3


from jinja2 import Template
from pathlib import Path


def main():
    globals().update(snakemake.config)

    sanger_config_template = snakemake.input["sanger_config_template"]

    with open(sanger_config_template) as f:
        template = Template(f.read())
    rendered_yaml = template.render(
        dataset_id=dataset_id,
        hic_motif=hic_motif,
        busco_lineage=busco_lineage,
        mito_species=mito_species,
        mito_min_length=mito_min_length,
        mito_code=mito_code,
        pacbio_reads=snakemake.params["pacbio_reads"],
    )

    with open(snakemake.output["rendered_yaml"], "w") as f:
        f.write(rendered_yaml)


if __name__ == "__main__":
    main()
