#!/usr/bin/env bash

set -eu

# Thread count.
THREADS=12

# Micromamba environment.
ENV=thesis

# Run within environment.
RUN="micromamba run -n ${ENV}"

# Path to reference assembly.
REF=data/PXO99A_reference/GCF_000019585.2_ASM1958v2_genomic.fna

# Path to directory containing Xoo assemblies to include in analysis.
ASM_DIR=data/xoo_genomes

# Output directory.
OUTDIR=results/parsnp_out_$(date +%y%m%d%H%M%S)

# Run parsnp.
${RUN} parsnp -r ${REF} -d ${ASM_DIR}/*.fna -o ${OUTDIR} -p ${THREADS}

