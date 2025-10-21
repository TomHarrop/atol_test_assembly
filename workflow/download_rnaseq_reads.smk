#!/usr/bin/env Snakemake


rule download_rnaseq_reads:
    input:
        manifest="config/rnaseq_manifest.csv",
    output:
        outdir=directory("resources/reads/rnaseq"),
    log:
        "logs/download_rnaseq_reads.log"
    resources:
        runtime=lambda wildcards, attempt: int(180 * attempt),
    threads: 12
    container:
        "atol-genome-launcher---0.1.4--pyhdfd78af_0.sif"    # FIXME
    shell:
        "rnaseq-reads-downloader "
        "--parallel_downloads {threads} "
        "{input.manifest} "
        "{output.outdir} "
        "&> {log}"
