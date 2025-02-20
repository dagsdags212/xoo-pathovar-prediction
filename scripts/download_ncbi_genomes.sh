#!/usr/bin/env bash

set -eu

# GO to project root.
cd ~/work

# Load secrets.
source .env

# Flat file containing filtered assembly metadata.
METADATA=metadata/assembly_metadata_filtered.tbl

# Directory path for storing raw genomes.
DATA_DIR=data/genomes
mkdir -p ${DATA_DIR}

# Directory path containing links to all FASTA genomes for analysis.
GENOME_DIR=data/xoo_genomes
mkdir -p ${GENOME_DIR}


download_and_extract_asm() {
  local asm=$1
  local basename=${asm%.*}
  local filename=${DATA_DIR}/${basename}.zip

  # Download FASTA and GFF3 files.
  datasets download genome accession ${asm} --include genome,gff3 --filename ${filename} --api-key ${NCBI_API_KEY}

  # Decompress within the same directory.
  unzip ${filename} -d ${DATA_DIR}/${basename}

  # Create a symbolic link to GENOME_DIR.
  local abspath=$(realpath ${DATA_DIR}/${basename}/ncbi_dataset/data/**/*.fna)
  ln -fs ${abspath} ${GENOME_DIR}/${basename}.fna
}

# Download and extract all assembly files in FASTA format.
main() {
  for asm in $(awk '{ print $2 }' ${METADATA})
  do
    download_and_extract_asm ${asm}
  done
}

# Run script.
main
