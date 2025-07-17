#!/bin/bash

#SBATCH --job-name=atol_epict
#SBATCH --time=3-00
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --partition=long
#SBATCH --mem=32g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err

# Dependencies
module load python/3.11.6
# Waiting for pawsey to install newer version. In the meantime, manually
# installed in /software/projects/pawsey1132/tharrop/atol_test_assembly/bin
# module load nextflow/24.04.3
module load singularity/4.1.0-nohost

unset SBATCH_EXPORT

# Application specific commands:
set -eux

source /software/projects/pawsey1132/tharrop/atol_test_assembly/venv/bin/activate

printf "TMPDIR: %s\n" "${TMPDIR}"
printf "SLURM_CPUS_ON_NODE: %s\n" "${SLURM_CPUS_ON_NODE}"

# load the manual nextflow install
export PATH="${PATH}:/software/projects/pawsey1132/tharrop/atol_test_assembly/bin"
printf "nextflow: %s\n" "$(which nextflow)"

# set the NXF home for plugins etc
export NXF_HOME=/software/projects/pawsey1132/tharrop/atol_test_assembly/.nextflow

if [ -z "${SINGULARITY_CACHEDIR}" ]; then
	export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/tharrop/.singularity
	export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

export NXF_APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}/library"
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}/library"

PIPELINE_VERSION="a6f7cb6"

snakemake \
	--profile profiles/pawsey_v8 \
	--retries 0 \
	--keep-going \
	--cores 12 \
	--local-cores "${SLURM_CPUS_ON_NODE}" \
	config_target

# Pull the containers into the cache before trying to launch the workflow.
# Using the latest commit to dev because of issues with staging from s3 on
# release 0.10.0. See
# https://github.com/sanger-tol/genomeassembly/compare/0.10.0...dev. Also,
# Pawsey only has NF 24.04.3 so we can't use nf-schema@2.4.2. Commit 68331e7
# seems to be the last commit before this was added.
nextflow inspect \
	-concretize sanger-tol/genomeassembly \
	--input results/sangertol_genomeassembly_params.yaml \
	--outdir s3://pawsey1132.atol.testassembly/Emblema_pictum_247745/results/sanger_tol \
    --timestamp "v1" \
	--hifiasm_hic_on \
	--organelles_on \
	-profile singularity,pawsey \
	-r "${PIPELINE_VERSION}"

# Note, it's tempting to use the apptainer profile, but the nf-core (and some
# sanger-tol) pipelines have a conditional `workflow.containerEngine ==
# 'singularity'` that prevents using the right URL with apptainer.
nextflow \
	-log "nextflow_logs/nextflow.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
	run \
	sanger-tol/genomeassembly \
	--input results/sangertol_genomeassembly_params.yaml \
	--outdir s3://pawsey1132.atol.testassembly/Emblema_pictum_247745/results/sanger_tol \
    --timestamp "v2" \
	-resume \
	-profile singularity,pawsey \
	-r "${PIPELINE_VERSION}"

exit 0

# currently the assembly output is hard-coded
snakemake \
	--profile profiles/pawsey_v8 \
	--retries 0 \
	--keep-going \
	--cores 12 \
	--local-cores "${SLURM_CPUS_ON_NODE}" \
	rm_all
