#!/usr/bin/env bash

set -eu

# Directory for storing raw long reads.
OUTDIR=data/reads
mkdir -p ${OUTDIR}

# Number of spots.
N=1000

# Download all reads from a list of SRA accessions.
fetch_reads() {
  local file=$1
  local target=$2
  cat ${file} | parallel --progress --delay 2 "fastq-dump --origfmt -X ${N} -v -v -O ${target} {}"
}

# Iterate over all accession lists and download associated reads.
for file in $(find metadata/accessions -type f)
do
  # Create directory for each bioproject.
  root=$(basename ${file})
  target=${OUTDIR}/${root%_*}
  mkdir -p ${target}

  # Download associated reads within bioproject directory.
  fetch_reads ${file} ${target}
done
