#!/bin/bash
#SBATCH --partition=batch
#SBATCH --qos=240c-1h_batch
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=50G
#SBATCH --job-name="download_sra_xoo_long_reads"
#SBATCH --output="%x.out"
#SBATCH --requeue

## Set stack limit size to unliminted.
ulimit -s unlimited

## For benchmarking.
start_time=$(date +%s.%N)

## Print job parameters.
echo "Submitted on $(date)"
echo "JOB PARAMETERS"
echo "SLURM_JOB_ID          : ${SLURM_JOB_ID}"
echo "SLURM_JOB_NAME        : ${SLURM_JOB_NAME}"
echo "SLURM_JOB_NUM_NODES   : ${SLURM_JOB_NUM_NODES}"
echo "SLURM_JOB_NODELIST    : ${SLURM_JOB_NODELIST}"
echo "SLURM_NTASKS          : ${SLURM_NTASKS}"
echo "SLURM_NTASKS_PER_NODE : ${SLURM_NTASKS_PER_NODE}"
echo "SLURM_MEM_PER_NODE    : ${SLURM_MEM_PER_NODE}"

## Create a tmp directory.
use_tmpdir=false

if [ "$use_tmpdir" = true ]; then
  JOB_TMPDIR=/tmp/${USER}/${SLURM_JOB_ID}
  mkdir -p ${JOB_TMPDIR}
  export TMPDIR=${JOB_TMPDIR}
  echo "TMPDIR              : ${TMPDIR}"
fi

## Reset modules.
module purge

## Load modules here.
module load anaconda

## MAIN JOB. Run scripts here.
conda activate sra_tools

main() {
  # Directory for storing raw long reads.
  OUTDIR=data/reads
  mkdir -p ${OUTDIR}

  # Runinfo file.
  RUNINFO=metadata/xoo_long_reads_runinfo.csv

  # Exit if runinfo file does not exist.
  [ -f "${RUNINFO} ]" || exit -1;
  
  # Create directory for each bioproject.
  cat ${RUNINFO} | cut -d, -f8 | uniq | parallel --skip-first-line "mkdir -p ${OUTDIR}/{}"

  # Group FASTQ files by bioproject accession.
  cat ${RUNINFO} | parallel --colsep , --skip-first-line "fastq-dump --origfmt -O ${OUTDIR}/{8} {1}"  
}

main

## Flush the TMPDIR.
[ -d ${TMPDIR} ] && rm -rf ${TMPDIR} || echo "No tmp directory: ${TMPDIR}"

end_time=%(date +%s.%N)
echo "Finished on $(date)"
run_time=$(python -c "print(${end_time}-${start_time})")
echo "Total runtime (sec): ${run_time}"
