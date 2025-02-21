#!/bin/bash 
#SBATCH --partition=batch 

#SBATCH --qos=240c-1h_batch  
#SBATCH --nodes=1 
#SBATCH --ntasks=12
#SBATCH --mem=20G
#SBATCH --job-name="parsnp_run"
#SBATCH --output="logs/%x.out"

#SBATCH --error="logs/%x.err"
#SBATCH --mail-user=dalepinili@rocketmail.com 
#SBATCH --mail-type=ALL 
#SBATCH --requeue 
 
echo "SLURM_JOBID="$SLURM_JOBID 
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST 
echo "SLURM_NNODES"=$SLURM_NNODES 
echo "SLURMTMPDIR="$SLURMTMPDIR 
echo "working directory = "$SLURM_SUBMIT_DIR 
 
# Place commands to load environment modules here 
module load anaconda

conda activate parsnp2

# Set stack size to unlimited 
ulimit -s unlimited 
 
# MAIN 

# Thread count.
THREADS=12

# Set output folder.
OUTDIR="parsnp_out" 
mkdir -p ${OUTDIR}

# Reference with TALEs.
REF1=data/refs/PXO99A.fna

# Reference without TALEs.
REF2=data/refs/3384-Xo_X11-5A.fasta

# Directory containing Xoo assemblies.
ASM_DIR=data/all_assemblies

# Output directories.
OUT_PXO99A=${OUTDIR}/PXO99A
OUT_X115A=${OUTDIR}/X115A

run_parsnp() {
  local ref=$1
  local outdir=$2

  parsnp -r ${ref} -d ${ASM_DIR} -o ${outdir} -p ${THREADS}
}

main() {
  # Run parsnp with PXO99A as reference.
  mkdir -p ${OUT_PXO99A}
  run_parsnp ${REF1} ${OUT_PXO99A}

  # Run parsnp with X11-5A as reference.
  mkdir -p ${OUT_X115A}
  run_parsnp ${REF2} ${OUT_X115A}
}

main
