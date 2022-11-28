#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --job-name=openflamingo
#SBATCH --nodes 2
#SBATCH --ntasks-per-node 8
#SBATCH --cpus-per-gpu=6
#SBATCH --gres=gpu:8
#SBATCH --output=%x_%j.out
#SBATCH --comment=laion
#SBATCH --open-mode=append
#SBATCH --exclude=gpu-st-p4d-24xlarge-77
#SBATCH --exclusive

module load intelmpi
source /opt/intel/mpi/latest/env/vars.sh

export PYTHONFAULTHANDLER=1
export CUDA_LAUNCH_BLOCKING=0
# sent to sub script
export HOSTNAMES=`scontrol show hostnames "$SLURM_JOB_NODELIST"`
export MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export MASTER_PORT=12802
export COUNT_NODE=`scontrol show hostnames "$SLURM_JOB_NODELIST" | wc -l`

echo go $COUNT_NODE
echo $HOSTNAMES

cd /fsx/home-mitchellw/open_flamingo/src
export PYTHONPATH="$PYTHONPATH:/fsx/home-mitchellw/open_flamingo/src"

EXP_NAME="run1-opt1b-vit-l-laion2b-2node-v4"

# torchrun --nnodes=1 --nproc_per_node=2 train.py --run_name test-debug --batch_size 50 --shards "pipe:aws s3 cp s3://s-datasets/laion5b/laion2B-data/{000000..231349}.tar -" --dataset_resampled --train_num_samples 10000 --precision amp_bfloat16

/opt/slurm/sbin/srun --comment laion --cpu_bind=v --accel-bind=gn python train.py \
    --shards="pipe:aws s3 cp s3://s-datasets/laion5b/laion2B-data/{000000..231349}.tar -" \
    --dataset_resampled \
    --batch_size=50 \
    --workers=2 \
    --report_to_wandb \
    --wandb_project open_flamingo \
    --wandb_entity dogml \
    --run_name ${EXP_NAME} \
    --train_num_samples 1000000 \
    --num_epochs 500000



