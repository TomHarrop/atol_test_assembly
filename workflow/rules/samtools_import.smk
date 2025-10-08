def get_raw_shortread_files(wildcards):
    # hard code for now, need a method for sorting files
    r1_file = Path(
        "resources", "reads", "606210_IPM_BRF_AAGWH2JM5_GCAGGTTC_S1_R1_001.fastq.gz"
    )
    r2_file = Path(
        "resources", "reads", "606210_IPM_BRF_AAGWH2JM5_GCAGGTTC_S1_R2_001.fastq.gz"
    )
    return {"r1": r1_file, "r2": r2_file}


rule shortread_qc:
    input:
        unpack(get_raw_shortread_files),
    output:
        r1=Path("resources", "qc", "hic", "r1.fq.gz"),
        r2=Path("resources", "qc", "hic", "r2.fq.gz"),
        stats=Path("resources", "qc", "hic", "hic_stats.json"),
    params:
        # shipped in container
        adaptors="/usr/local/opt/bbmap-38.95-1/resources/adapters.fa",
    log:
        log=Path("logs", "shortread_qc.log"),
        logdir=directory(Path("resources", "qc", "hic", "qc_logs")),
    benchmark:
        Path("logs", "shortread_qc.benchmark.txt")
    threads: 32
    resources:
        runtime=lambda wildcards, attempt: int(480 * attempt),
        mem=lambda wildcards, attempt: f"{int(32)* attempt}GiB",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/atol-qc-raw-shortread:0.1.3--pyhdfd78af_0"
    shell:
        "atol-qc-raw-shortread "
        "--threads {threads} "
        "--in {input.r1} "
        "--in2 {input.r2} "
        "--out {output.r1} "
        "--out2 {output.r2} "
        "-a {params.adaptors} "
        "--stats {output.stats} "
        "--logs {log.logdir} "
        "&> {log.log}"


# Combine Hi-C reads as follows: contains the list (-reads) of the HiC reads in
# the indexed CRAM format. There is a suggested method here:
# https://pipelines.tol.sanger.ac.uk/curationpretext/1.0.1/usage
# (Current attempt: don't include the SAM tags. See details at URL.)
rule samtools_import:
    input:
        r1=Path("resources", "qc", "hic", "r1.fq.gz"),
        r2=Path("resources", "qc", "hic", "r2.fq.gz"),
    output:
        cram=Path("resources", "reads", "hic", "hic.cram"),
        index=Path("resources", "reads", "hic", "hic.cram.crai"),
        flagstat=Path("resources", "reads", "hic", "hic.flagstat"),
    params:
        prefix=dataset_id,
        sample_name=dataset_id,
        hic_kit="arima",  # FIXME
    log:
        Path("logs", "samtools_import.log"),
    resources:
        runtime=lambda wildcards, attempt: int(480 * attempt),
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
