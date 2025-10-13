#!/usr/bin/env python3


def get_ont_readfiles(wildcards):
    filelist = [
        Path("resources", "reads", filename)
        for filename, url in data_file_dict.items()
        if filename.endswith("fastq_pass.tar")
    ]
    if len(filelist) > 1:
        raise NotImplementedError("TODO: handle multiple ONT files")
    return filelist


rule ont_qc:
    input:
        get_ont_readfiles,
    output:
        reads=Path("resources", "qc", "ont", "ont.fq.gz"),
        stats=Path("resources", "qc", "ont", "ont_stats.json"),
    params:
        min_length=5000,
    log:
        log=Path("logs", "ont_qc.log"),
        logdir=directory(Path("resources", "qc", "ont", "qc_logs")),
    benchmark:
        Path("logs", "ont_qc.benchmark.txt")
    threads: 66
    resources:
        runtime=lambda wildcards, attempt: int(150 * attempt),
        mem=lambda wildcards, attempt: f"{int(256)* attempt}GB",
        partitionFlag="--partition=highmem"
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/atol-qc-raw-ont:0.1.11--pyhdfd78af_0"
    shell:
        "atol-qc-raw-ont "
        "--threads {threads} "
        "--tarfile {input} "
        "--out {output.reads} "
        "--stats {output.stats} "
        "--logs {log.logdir} "
        "--min-length {params.min_length} "
        "&> {log.log}"
