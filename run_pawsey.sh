#!/bin/bash

#SBATCH --job-name=atol_taxid168868
#SBATCH --time=0-01
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --mem=32g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err
## SBATCH --partition=long

# Dependencies
module load python/3.11.6
# Waiting for pawsey to install newer version. In the meantime, manually
# installed in /software/projects/pawsey1132/tharrop/atol_test_assembly/bin
# module load nextflow/24.04.3
module load singularity/4.1.0-nohost

unset SBATCH_EXPORT

# Application specific commands:
set -eux

# SLURM runner info
printf "TMPDIR: %s\n" "${TMPDIR}"
printf "SLURM_CPUS_ON_NODE: %s\n" "${SLURM_CPUS_ON_NODE}"

# parameters
PIPELINE_VERSION="1.1.0"
SOURCE_DIRNAME="atol_test_assembly-taxid168868"
RESULT_DIRNAME="taxid168868"
RESULT_VERSION="v0"

PIPELINE_PARAMS=(
	"--input" "results/config/nfcore-genomeassembler.config.csv"
	"--outdir" "results/${RESULT_DIRNAME}/results/genomeassembler"
	"-profile" "singularity,pawsey,ont_flye"
	"-r" "${PIPELINE_VERSION}"
)

# run-specific venv
source "/software/projects/pawsey1132/tharrop/${SOURCE_DIRNAME}/venv/bin/activate"

# apptainer setup
if [ -z "${SINGULARITY_CACHEDIR}" ]; then
	export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/tharrop/.singularity
	export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

export NXF_APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}/library"
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}/library"

# load the manual nextflow install
export PATH="${PATH}:/software/projects/pawsey1132/tharrop/${SOURCE_DIRNAME}/bin"
printf "nextflow: %s\n" "$( readlink -f $( which nextflow ) )"

# set the NXF home for plugins etc
export NXF_HOME="/software/projects/pawsey1132/tharrop/${SOURCE_DIRNAME}/.nextflow"
export NXF_CACHE_DIR="/scratch/pawsey1132/tharrop/${SOURCE_DIRNAME}/.nextflow"
export NXF_WORK="${NXF_CACHE_DIR}/work"

printf "NXF_HOME: %s\n" "${NXF_HOME}"
printf "NXF_WORK: %s\n" "${NXF_WORK}"

# Download the reads from BPA
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
nextflow \
	-log "nextflow_logs/nextflow_inspect.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
	inspect \
	-concretize nf-core/genomeassembler \
	"${PIPELINE_PARAMS[@]}"

# Note, it's tempting to use the apptainer profile, but the nf-core (and some
# sanger-tol) pipelines have a conditional `workflow.containerEngine ==
# 'singularity'` that prevents using the right URL with apptainer.
nextflow \
	-log "nextflow_logs/nextflow_run.$(date +"%Y%m%d%H%M%S").${RANDOM}.log" \
	run \
	nf-core/genomeassembler \
	"${PIPELINE_PARAMS[@]}" \
	-resume 
