def get_hic_readfiles_by_direction(direction):
    """Get Hi-C read files filtered by direction (R1 or R2)"""
    return [
        Path("resources", "reads", filename)
        for filename, url in data_file_dict.items()
        if filename.endswith(".fastq.gz") and f"_{direction}_" in filename
    ]


rule concatenate_hic_reads:
    input:
        files=lambda wildcards: [
            rules.download_from_bpa.output[0].format(readfile=filename)
            for filename, url in data_file_dict.items()
            if filename.endswith(".fastq.gz")
            and f"_{wildcards.direction}_" in filename
        ],
    output:
        merged=temp(Path("resources", "reads", "hic_merged_{direction}.fastq.gz")),
    log:
        Path("logs", "concatenate_hic_reads_{direction}.log"),
    resources:
        runtime=lambda wildcards, attempt: int(60 * attempt),
    shell:
        "cat {input.files} > {output.merged} 2> {log}"


# Combine Hi-C reads as follows: contains the list (-reads) of the HiC reads in
# the indexed CRAM format. There is a suggested method here:
# https://pipelines.tol.sanger.ac.uk/curationpretext/1.0.1/usage
# (Current attempt: don't include the SAM tags. See details at URL.)
rule samtools_import:
    input:
        r1=rules.concatenate_hic_reads.output.merged.format(direction="R1"),
        r2=rules.concatenate_hic_reads.output.merged.format(direction="R2"),
    output:
        cram=add_bucket_to_path(Path(dataset_id, "results", "reads", "hic", "hic.cram")),
        index=add_bucket_to_path(
            Path(dataset_id, "results", "reads", "hic", "hic.cram.crai")
        ),
        flagstat=add_bucket_to_path(
            Path(dataset_id, "results", "reads", "hic", "hic.flagstat")
        ),
    params:
        # 
        prefix=dataset_id,
        sample_name=dataset_id,
        hic_kit="arima",  # FIXME
    log:
        Path("logs", "samtools_import.log"),
    resources:
        runtime=lambda wildcards, attempt: int(120 * attempt),
    container:
        get_container("samtools")
    shell:
        "samtools import "
        "-@{threads} "
        "{input.r1} "
        "{input.r2} "
        "-r ID:{params.prefix} "
        "-r CN:{params.hic_kit} "
        "-r PU:{params.prefix} "
        "-r SM:{params.sample_name} "
        "-o {output.cram} "
        "2> {log} "
        "&& "
        "samtools index "
        "{output.cram} "
        "2>> {log} "
        "&& "
        "samtools flagstat "
        "{output.cram} "
        "> {output.flagstat} "
        "2>> {log} "
