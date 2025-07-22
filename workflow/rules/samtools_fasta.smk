def get_hifi_readfiles(wildcards):
    return [
        Path("resources", "reads", filename)
        for filename, url in data_file_dict.items()
        if (filename.endswith(".hifi_reads.bam") or filename.endswith(".ccs.bam"))
    ]


# Combine HiFi reads as follows:
# contains the list (-reads) of the HiFi reads in FASTA (or gzipped FASTA)
# format in. The pipeline implementation is based on an assumption that reads
# have gone through adapter/barcode checks.
rule samtools_fasta:
    input:
        get_hifi_readfiles,
    output:
        reads=add_bucket_to_path(
            Path(dataset_id, "results", "reads", "hifi", "ccs_reads.fasta.gz")
        ),
    log:
        Path("logs", "samtools_fasta.log"),
    threads: 8
    resources:
        runtime=lambda wildcards, attempt: int(120 * attempt),
    container:
        get_container("samtools")
    shell:
        "samtools cat "
        "{input} "
        "| "
        "samtools fasta "
        "-@{threads} "
        "-0 {output} "
        "2> {log}"
