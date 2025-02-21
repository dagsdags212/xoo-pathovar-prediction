#!/usr/bin/bash

# Exit on error.
set -eu

# Directory containing raw FASTQ files.
RAW_READS_DIR=data/reads

# Output directories.
FASTQC_OUT_RAW=results/fastqc_raw
MULTIQC_OUT_RAW=results/multiqc_raw

# Number of threads.
THREADS=8


# Returns formatted date.
fdate() {
  date +%Y%m%d%H%M
}

# Create target directories.
init() {
  [ -d "${FASTQC_OUT_RAW}" ] || mkdir -p ${FASTQC_OUT_RAW}
  [ -d "${MULTIQC_OUT_RAW}" ] || mkdir -p ${MULTIQC_OUT_RAW}
}

run_fastqc() {
  local reads_dir=$1
  local outdir=$2

  # Exit if reads directory does not exist.
  [ ! -d "${reads_dir}" ] && exit -1

  # Generate FASTQC reports.
  [ -d "${outdir}" ] || mkdir -p ${outdir}
  fastqc -o ${outdir} -t ${THREADS} ${reads_dir}/**/*.{fastq,fastq.gz,fq,fq.gz}
}

run_multiqc() {
  local fastqc_out_dir=$1
  local outdir=$2

  # Exit if fastqc output directory does not exist.
  [ ! -d "${fastqc_out_dir}" ] && exit -1

  # Generate multiqc report.
  [ -d "${outdir}" ] || mkdir -p ${outdir}
  multiqc -o ${outdir} ${fastqc_out_dir}
}

run_porechop() {
  local outdir=data/reads_trimmed
  porechop --discard_middle -v 2 -i  -o 
}

run_chopper() {}

main() {
  # Create output directories.
  init
  
  # Generate report for raw reads.
  run_fastqc ${RAW_READS_DIR} ${FASTQC_OUT_RAW}
  run_multiqc ${FASTQC_OUT_RAW} ${MULTIQC_OUT_RAW}
}

# Run script.
main
