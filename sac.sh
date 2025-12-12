#!/bin/bash

# === CONFIGURACIÓN ===
ENV_PATH="/mnt/d/robotica/robotica/ejecutable.x86_64"
LOG_DIR="/mnt/d/robotica/robotica/logs/sac/model"
TIMESTEPS=1_500_000
N_PARALLEL=20
SCRIPT="sac_model.py"

source runTrain.sh
