#!/bin/bash
# Obtener el último archivo run_XXX.zip
LAST_MODEL=$(ls ${LOG_DIR}/run_*.zip 2>/dev/null | sort -V | tail -n 1)

if [ -z "$LAST_MODEL" ]; then
    echo "No se encontraron modelos previos, iniciando desde cero."
    LAST_NUM=-1
    RESUME_PATH=""
else
    echo "Último modelo encontrado: $LAST_MODEL"
    LAST_NUM=$(echo "$LAST_MODEL" | grep -oE '[0-9]+' | tail -1)
    RESUME_PATH="$LAST_MODEL"
fi

# === CALCULAR SIGUIENTE NÚMERO ===
NEXT_NUM=$((LAST_NUM + 1))
NEXT_MODEL=$(printf "run_%03d.zip" "$NEXT_NUM")
SAVE_PATH="$LOG_DIR/$NEXT_MODEL"

echo "-> Guardando nuevo modelo como: $NEXT_MODEL"

# === CONSTRUIR COMANDO ===
CMD=(python3 "$SCRIPT" \
     --env_path "$ENV_PATH" \
     --timesteps "$TIMESTEPS" \
     #--save_model_path "$SAVE_PATH" \
    # --n_parallel "$N_PARALLEL"\
    --viz
    --inference
     )

# Agregar resume_model_path si existe
if [ -n "$RESUME_PATH" ]; then
    CMD+=(--resume_model_path "$RESUME_PATH")
fi



# Mostrar el comando
echo "Ejecutando entrenamiento:"
echo "${CMD[@]}"

# Ejecutar el comando
"${CMD[@]}"
