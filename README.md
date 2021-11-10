This calculation is set up to submit long-running (1 microsecond, ~7-10 days walltime) gromacs simulations to SLURM partitions with GPU compute capabilities.
Since the walltime limitation for these partitions is only 24h and these 4 jobs will run for over a week, it would be effort-intensive to repeatedly resubmit a job that was killed due to running up against the walltime limit.
This would also be somewhat inefficient, as jobs that were killed overnight would need to wait until morning to be resubmitted, potentially increasing the time to completion of these calculations significantly.

As a result, this workflow uses the following 'trick' to keep the calculation running: jobs will end themselves 5m earlier than the walltime limit using the `timeout` command, and submit a follow-up job that will continue where it left off.
This makes use of the gromacs checkpoint (cpt) functionality to cleanly restart the simulation. 
The `submit-slurm.sh` file in each md directory has comments with specific details.

This calculation can be started via:

```
for C in md0*; do cd $C; sbatch submit-slurm.sh; cd ../; done
```

the calculations should then run on their own until completion, as determined by the creation of the appropriate `confout.gro` file at the end of each simulation. \
The submitting user will get email notifications each time a job segment ends and submits its follow-up, and the calculations will be done when a notification comes through for a segment completing without a corresponding submission notification.
As usual the progress of the jobs can also be tracked using `squeue -u <username>`, where jobs will appear with names prefixed by how many times they have resubmitted themselves.

For this calculation the v100 partition is targeted first, with the k40 partition used as backup if there are no v100 nodes available.

The specific calculation implemented here requires a special forcefield to be installed, from `supplemental_files/mygaff.ff`.
This also requires a user-writeable installation of gromacs, which is assumed to be located at `~/gmx-2021-3-bin`.


