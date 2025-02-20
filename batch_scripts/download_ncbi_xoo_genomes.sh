#!/bin/bash
#SBATCH --partition=batch
#SBATCH --qos=240c-1h_batch
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=50G
#SBATCH --job-name="download_xoo_ncbi_genomes"
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

# Activate conda environment.
conda activate ncbi_datasets

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

## Flush the TMPDIR.
[ -d ${TMPDIR} ] && rm -rf ${TMPDIR} || echo "No tmp directory: ${TMPDIR}"

end_time=%(date +%s.%N)
echo "Finished on $(date)"
run_time=$(python -c "print(${end_time}-${start_time})")
echo "Total runtime (sec): ${run_time}"
