#!/bin/bash

# === CONFIGURACIÓN ===
ENV_PATH="/mnt/d/robotica/robotica/ejecutable.x86_64"
LOG_DIR="/mnt/d/robotica/robotica/logs/ppo/model"
TIMESTEPS=2_000_000
N_PARALLEL=15
SCRIPT="stable_baselines3_example.py"

source runTrain.sh