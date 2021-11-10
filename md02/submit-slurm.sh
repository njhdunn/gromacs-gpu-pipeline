#!/bin/bash
#SBATCH --ntasks=12
#SBATCH --time=24:00:00
#SBATCH --mem=10g
#SBATCH --tmp=10g
#SBATCH -p v100,k40
#SBATCH --gres=gpu:1
#SBATCH -J md02

cd $SLURM_SUBMIT_DIR

. ~/gmx-2021-3-bin/bin/GMXRC.bash

CALCNAME="md02"
KILLTIME="1435m"

MDP="md.mdp"

CPTFREQ=5
TOP=$(ls *.top)
MODEL=${TOP%.*}
INPDB=$(ls *.pdb)

# rate limiter to preven catastrophic failure from hurting scheduler
sleep 60s

# if we have a state file, continue from there
if [[ -f ${MODEL}.cpt  ]]; then

	# gromacs often fails to unlock the log file
	mv ${MODEL}.log ${MODEL}.log.prev
	cp ${MODEL}.log.prev ${MODEL}.log 

	# kill the gromacs job early so we can resubmit from checkpoint
	timeout -s 9 $KILLTIME gmx_mpi mdrun -v -deffnm $MODEL -cpi ${MODEL}.cpt -cpt $CPTFREQ

else

	# only grompp if we don't have the tpr to avoid excess files
	if [[ ! -f ${MODEL}.tpr ]]; then
		gmx_mpi grompp -f bench.mdp -c $INPDB -p ${MODEL}.top -o ${MODEL}.tpr
	fi

	# kill the gromacs job early so we can resubmit from checkpoint
	timeout -s 9 $KILLTIME gmx_mpi mdrun -v -deffnm $MODEL -s ${MODEL}.tpr -nb gpu -pme gpu -bonded gpu -pmefft gpu -cpt $CPTFREQ

fi

# run counter for job resubmission labeling
if [ -z ${RUN_COUNTER+x} ]; then
	export RUN_COUNTER=1
else
	export RUN_COUNTER=$((RUN_COUNTER + 1))
fi

# we know the job is done when it create the confout.gro file 
if [[ ! -f ${MODEL}.gro  ]]; then

	sbatch -J ${RUN_COUNTER}.${CALCNAME} submit-slurm.sh

fi
