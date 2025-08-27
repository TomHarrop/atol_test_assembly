filename = "SRR33206838"
pacbio_url = "https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos8/sra-pub-run-834/SRR033/33206/SRR33206838/SRR33206838.1"


rule ncbi_dl_target:
    input:
        local(f"resources/ncbi/{filename}.fasta"),
    output:
        reads=Path("resources", "reads", "hifi", "ccs_reads.fasta.gz"),
    shell:
        "cp {input} {output} "


# can't use shadow rules or filesystems with sra-tools.
rule dump_srafile:
    input:
        srafile=local("resources/ncbi/{filename}.sra"),
    output:
        fasta=temp(local("resources/ncbi/{filename}.fasta")),
    params:
        outfile=subpath(output.fasta, basename=True),
        outdir=subpath(output.fasta, parent=True),
    log:
        local("logs/dump_srafile.{filename}.log"),
    threads: 2
    resources:
        runtime="12h",
        mem="128GB",
    container:
        "docker://quay.io/biocontainers/sra-tools:3.2.1--h4304569_1"
    shell:
        'tmpdir="$( mktemp -d )" && '
        "fasterq-dump "
        "--outfile {params.outfile} "
        "--outdir {params.outdir} "
        "--threads {threads} "
        "--details "
        "--log-level 6 "
        "--verbose "
        "--fasta "
        '--temp "${{tmpdir}}" '
        "{input.srafile} "
        "&> {log} "


rule download_srafile:
    output:
        srafile=local("resources/ncbi/SRR33206838.sra"),
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
