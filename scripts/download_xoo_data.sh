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

## Reset modules.
module purge

## Load modules here.
module load anaconda

## MAIN JOB. Run scripts here.

download_xoo_long_reads() {
  conda activate sra_tools

  # Directory for storing raw long reads.
  OUTDIR=data/reads
  mkdir -p ${OUTDIR}

  # Runinfo file.
  RUNINFO=metadata/xoo_long_reads_runinfo.csv

  # Exit if runinfo file does not exist.
  [[ -f "${RUNINFO}" ]] || exit -1;
  
  # Create directory for each bioproject.
  cat ${RUNINFO} | cut -d, -f8 | uniq | parallel --skip-first-line "mkdir -p ${OUTDIR}/{}"

  # Group FASTQ files by bioproject accession.
  cat ${RUNINFO} | parallel --colsep , --skip-first-line "fastq-dump --origfmt -O ${OUTDIR}/{8} {1}"  

  conda deactivate
}

download_xoo_assemblies() {
  conda activate ncbi_datasets

  # List of assembly ids.
  ACC_LIST=metadata/asm_accessions.txt

  # Target file
  TARGET=data/xoo_assemblies.zip

  # Download all listed assemblies, along with their annotations.
  datasets download genome accession --inputfile ${ACC_LIST} --include genome,gff3 --filename ${TARGET}

  # Unzip genome directory.
  unzip ${TARGET} -d ${TARGET%.zip}

  conda deactivate
}

download_xoo_reference() {
  conda activate ncbi_datasets

  # Assembly accession.
  REF=GCA_000019585.2

  # Target file.
  TARGET=data/PXO99A.zip

  # Download reference FASTA file and annotation.
  datasets download genome accession ${REF} --include genome,gff3 --filename ${TARGET}

  # Unzip genome directory.
  unzip ${TARGET} -d ${TARGET%.zip}
  rm -f ${TARGET}

  conda deactivate
}

main {
  echo "Downloading Xoo reference file from NCBI..."
  download_xoo_reference

  echo "Downloading Xoo assemblies from NCBI..."
  download_xoo_assemblies

  echo "Downloading Xoo long reads from SRA..."
  download_xoo_long_reads
}


end_time=%(date +%s.%N)
echo "Finished on $(date)"
run_time=$(python -c "print(${end_time}-${start_time})")
echo "Total runtime (sec): ${run_time}"
