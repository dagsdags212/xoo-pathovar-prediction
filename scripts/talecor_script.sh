#!/bin/bash 
#SBATCH --partition=batch 

#SBATCH --qos=240c-1h_batch  
#SBATCH --nodes=1 
#SBATCH --ntasks=12
#SBATCH --mem=16G
#SBATCH --job-name="talc_run"
#SBATCH --output="%x.out"

#SBATCH --error="%x.err"
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
#/3-2023.07-2

conda activate talecorrect

# Set stack size to unlimited 
ulimit -s unlimited 
 
# MAIN 

# Set output folder.
OUTDIR="talc_out" 

mkdir -p ${OUTDIR}

# Run this script, if you want to correct TALEs in ONT assemblies.
# You can run correction of the example genome or uncomment parameters OUTDIR=$1 (line 7) and uncorrectedAssembly=$2 (line 11) to correct your own assembly. Please change the pathToHMMs="HMMs/Xoo/" to the matching HMM pathovar.


#set path to uncorrected ONT assembly
#uncorrectedAssembly="inputTest/uncorrectedAssembly.fasta" 
#uncorrectedAssembly=$2

#set path to TALEcorrection.jar
pathToTALECorrection="/home/doy.pinili/scratch2/_Jan/xoo-pathovar-prediction/bin/TALEcorrection.jar"

#set path to folder with TALE HMMs
pathToHMMs="/home/doy.pinili/scratch2/_Jan/xoo-pathovar-prediction/data/hmms/Xoo"

# TALECorrrection executable.
TCEXE="java -jar ${pathToTALECorrection}"

# Takes a FASTA file as first argument
run_correction() {
  # Path to FASTA file to be corrected.
  local fastaFile=$1
  local fastaRoot=$(basename ${fastaFile})
  fastaRoot=${fastaRoot%%.*}

  # Name of corrected FASTA file.
  local outputName=$2

  # Exit if FASTA file does not exist.
  [[ -f "${fastaFile}" ]] || exit -1;

  # Run nhmmer.
  echo "Running nhmmer on ${fastaFile}..."

  parts=("N-terminus.10bpRepeat1" "repeat" "C-terminus")
  for p in ${parts[@]}; do        
    local hmmFile=${pathToHMMs}/${p}.hmm
    local outputFile=${OUTDIR}/out_nhmmer_${fastaRoot}.${p}.txt

    nhmmer ${hmmFile} ${fastaFile} > ${outputFile}
  done

  # Apply correction.
  echo "Start correction of TALEs: ${fastaFile}"
  java -jar ${pathToTALECorrection} correct s=${fastaFile} n=${OUTDIR}/out_nhmmer_${fastaRoot}.${parts[0]}.txt r=${OUTDIR}/out_nhmmer_${fastaRoot}.${parts[1]}.txt c=${OUTDIR}/out_nhmmer_${fastaRoot}.${parts[2]}.txt outdir=${OUTDIR}

  mv ${OUTDIR}/correctedTALEs.fa ${OUTDIR}/cor_${outputName}.fna

  echo "TALE correction for ${fastaFile} done."
}

main() {
  for fna in $(find data/xoo_assemblies/ncbi_dataset/data -type f -name "*.fna"); do
    local basename=$(basename ${fna})
    local acc=${basename%%_ASM*}
    run_correction ${fna} ${acc}
  done
}

# Run TALE correction script.
main

