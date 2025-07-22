#!/bin/bash

# Application specific commands:
set -eux

snakemake \
	--profile profiles/local \
	rm_all