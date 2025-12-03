#!/bin/bash

# === CONFIGURACIÓN ===
ENV_PATH="/mnt/d/DOC_UNI/robotica/robotica/ejecutable.x86_64"
LOG_DIR="/mnt/d/DOC_UNI/robotica/robotica/logs/sac/model"
TIMESTEPS=500_000
N_PARALLEL=10
SCRIPT="sac_model.py"

source runTrain.sh
