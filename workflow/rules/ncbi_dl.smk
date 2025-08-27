filename = "SRR33206838"
pacbio_url = "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos8/sra-pub-run-834/SRR033/33206/SRR33206838/SRR33206838.1"


rule ncbi_dl_target:
    input:
        Path("resources", "reads", f"{filename}.fasta"),
    output:
        reads=Path("resources", "reads", "hifi", "ccs_reads.fasta.gz"),
    shell:
        "cp {input} {output} "


rule dump_srafile:
    input:
        srafile=Path("resources", "reads", "{filename}"),
    output:
        fasta=temp(Path("resources", "reads", "{filename}.fasta")),
    params:
        outdir=subpath(output.fasta, parent=True),
    log:
        Path("logs", "dump_srafile.{filename}.log"),
    threads: 2
    resources:
        runtime=lambda wildcards, attempt: int(120 * attempt),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/sra-tools:3.1.1--h4304569_0"
    shell:
        "ln -s {input.srafile} ./{wildcards.filename} && "
        "fasterq-dump "
        "--outfile {wildcards.filename} "
        "--threads {threads} "
        "--details "
        "--log-level 6 "
        "--verbose "
        "--fasta "
        "{wildcards.filename} "
        "&> {log} "
        "&& mv {wildcards.filename}* {params.outdir}/ "


rule download_srafile:
    output:
        srafile=Path("resources", "reads", "SRR33206838"),
    params:
        outdir=subpath(output[0], parent=True),
        pacbio_url=pacbio_url,
    log:
        Path("logs", "download_srafile.SRR33206838.log"),
    resources:
        runtime=lambda wildcards, attempt: int(120 * attempt),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget -O {output.srafile} {params.pacbio_url} &> {log}"
