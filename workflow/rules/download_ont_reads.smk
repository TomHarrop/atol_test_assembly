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
        logs=directory(Path("resources", "qc", "ont", "qc_logs")),
    params:
        min_length=5000,
    log:
        Path("logs", "ont_qc.log"),
    benchmark:
        Path("logs", "ont_qc.benchmark.txt")
    threads: 32
    resources:
        runtime=lambda wildcards, attempt: int(120 * attempt),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/atol-qc-raw-ont:0.1.2--pyhdfd78af_0"
    shell:
        "atol-qc-raw-ont "
        "--threads {threads} "
        "--tarfile {input} "
        "--out {output.reads} "
        "--stats {output.stats} "
        "--logs {output.logs} "
        "--min_length {params.min_length} "
        "&>{log}"
