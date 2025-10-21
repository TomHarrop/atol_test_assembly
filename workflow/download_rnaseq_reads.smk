#!/usr/bin/env Snakemake

import os

manifest = "config/rnaseq_manifest.csv"


def get_target(wildcards):
    readdir = checkpoints.download_rnaseq_reads.get().output["outdir"]
    all_samples = glob_wildcards(os.path.join(readdir, "{sample}.r1.fq.gz")).sample
    target_files = expand(
        "resources/reads/qc/rnaseq/{sample}.r{r}.fq.gz",
        sample=all_samples,
        r=["1", "2"],
    )

    raise ValueError(target_files)


rule target:
    input:
        get_target,


rule rnaseq_read_prep:
    input:
        r1="resources/reads/rnaseq/{sample}.r1.fq.gz",
        r2="resources/reads/rnaseq/{sample}.r2.fq.gz",
    output:
        r1="resources/reads/qc/rnaseq/{sample}.r1.fq.gz",
        r2="resources/reads/qc/rnaseq/{sample}.r2.fq.gz",
        stats="resources/reads/qc/rnaseq/stats/{sample}.json",
    log:
        log="logs/rnaseq_read_prep/{sample}.log",
        logdir=directory("resources/reads/qc/rnaseq/logs/{sample}"),
    threads: 8
    resources:
        runtime=lambda wildcards, attempt: int(30 * attempt),
        mem=lambda wildcards, attempt: f"{int(16)* attempt}GiB",
    container:
        "docker://quay.io/biocontainers/atol-qc-raw-shortread:0.1.6--pyhdfd78af_0"
    shell:
        "atol-qc-raw-shortread "
        "--threads {threads} "
        "--in {input.r1} "
        "--in2 {input.r2} "
        "--out {output.r1} "
        "--out2 {output.r2} "
        "--stats {output.stats} "
        "--logs {log.logdir} "
        "&> {log.log}"


checkpoint download_rnaseq_reads:
    input:
        manifest=manifest,
    output:
        outdir=local(directory("resources/reads/rnaseq")),
    log:
        "logs/download_rnaseq_reads.log",
    resources:
        runtime=lambda wildcards, attempt: int(180 * attempt),
    threads: 12
    container:
        "atol-genome-launcher---0.1.5--pyhdfd78af_0.sif"  # FIXME
    shell:
        "rnaseq-reads-downloader "
        "--parallel_downloads {threads} "
        "{input.manifest} "
        "{output.outdir} "
        "&> {log}"
