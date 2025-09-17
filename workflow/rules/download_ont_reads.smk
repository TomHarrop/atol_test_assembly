#!/usr/bin/env python3


def get_ont_readfiles(wildcards):
    return [
        Path("resources", "reads", filename)
        for filename, url in data_file_dict.items()
        if filename.endswith("fastq_pass.tar")
    ]


rule ont_tar_to_fastq:
    input:
        get_ont_readfiles,
    output:
        reads=Path("resources", "reads", "ont", "ont.fq.gz"),
    log:
        Path("logs", "ont_tar_to_fastq.log"),
    threads: 8
    resources:
        runtime=lambda wildcards, attempt: int(120 * attempt),
    container:
        get_container("samtools")
    shell:
        "cp {input} {output.reads}"
