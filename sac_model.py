import argparse
import os
import pathlib
from typing import Callable

from stable_baselines3 import SAC
from stable_baselines3.common.callbacks import CheckpointCallback
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor

from godot_rl.core.utils import can_import
from godot_rl.wrappers.onnx.stable_baselines_export import export_model_as_onnx
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

if can_import("ray"):
    print("WARNING: stable-baselines3 and ray[rllib] are not fully compatible.")

# ---------------------- Argumentos ----------------------
parser = argparse.ArgumentParser(allow_abbrev=False)
parser.add_argument("--env_path", default=None, type=str)
parser.add_argument("--experiment_dir", default="logs/sac/experiment", type=str)
parser.add_argument("--experiment_name", default="experiment", type=str)
parser.add_argument("--seed", type=int, default=0)
parser.add_argument("--resume_model_path", default=None, type=str)
parser.add_argument("--save_model_path", default=None, type=str)
parser.add_argument("--save_checkpoint_frequency", default=None, type=int)
parser.add_argument("--onnx_export_path", default=None, type=str)
parser.add_argument("--timesteps", default=1_000_000, type=int)
parser.add_argument("--inference", default=False, action="store_true")
parser.add_argument("--linear_lr_schedule", default=False, action="store_true")
parser.add_argument("--viz", action="store_true", default=False)
parser.add_argument("--speedup", default=1, type=int)
parser.add_argument("--n_parallel", default=1, type=int)
args, extras = parser.parse_known_args()

# ---------------------- Funciones útiles ----------------------
def linear_schedule(initial_value: float) -> Callable[[float], float]:
    """Linear learning rate schedule."""
    def func(progress_remaining: float) -> float:
        return progress_remaining * initial_value
    return func

def handle_onnx_export():
    if args.onnx_export_path is not None:
        path_onnx = pathlib.Path(args.onnx_export_path).with_suffix(".onnx")
        print(f"Exporting ONNX model to: {os.path.abspath(path_onnx)}")
        export_model_as_onnx(model, str(path_onnx))

def handle_model_save():
    if args.save_model_path is not None:
        zip_save_path = pathlib.Path(args.save_model_path).with_suffix(".zip")
        print(f"Saving model to: {os.path.abspath(zip_save_path)}")
        model.save(zip_save_path)

def close_env():
    try:
        env.close()
        print("Environment closed successfully.")
    except Exception as e:
        print("Error closing environment:", e)

def cleanup():
    handle_onnx_export()
    handle_model_save()
    close_env()

# ---------------------- Preparar checkpoint ----------------------
path_checkpoint = os.path.join(args.experiment_dir, args.experiment_name + "_checkpoints")
abs_path_checkpoint = os.path.abspath(path_checkpoint)
if args.save_checkpoint_frequency and os.path.isdir(path_checkpoint) and args.resume_model_path is None:
    raise RuntimeError(
        f"{abs_path_checkpoint} already exists. Use a different experiment name/dir or remove it."
    )

# ---------------------- Preparar entorno ----------------------
if args.env_path and not os.path.isabs(args.env_path):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    args.env_path = os.path.join(script_dir, args.env_path)

env = StableBaselinesGodotEnv(
    env_path=args.env_path,
    show_window=args.viz,
    seed=args.seed,
    n_parallel=args.n_parallel,
    speedup=args.speedup,
    use_obs_array=True,
)
env = VecMonitor(env)

# ---------------------- Crear modelo ----------------------
if args.resume_model_path is None:
    lr = 0.0003 if not args.linear_lr_schedule else linear_schedule(0.0003)
    model = SAC(
        "MultiInputPolicy",
        env,
        learning_rate=lr,
        buffer_size=500_000,
        batch_size=512,
        tau=0.005,
        gamma=0.99,
        train_freq=(1, "step"),
        gradient_steps=1,
        learning_starts=10_000,
        ent_coef="auto",
        verbose=2,
        tensorboard_log=args.experiment_dir,
        device="cuda" if os.environ.get("CUDA_VISIBLE_DEVICES") else "cpu",
    )
else:
    path_zip = pathlib.Path(args.resume_model_path)
    print(f"Loading model from: {os.path.abspath(path_zip)}")
    model = SAC.load(path_zip, env=env, tensorboard_log=args.experiment_dir)

# ---------------------- Entrenamiento o inferencia ----------------------
if args.inference:
    obs = env.reset()
    for _ in range(args.timesteps):
        action, _ = model.predict(obs, deterministic=True)
        obs, reward, done, info = env.step(action)
else:
    learn_kwargs = dict(total_timesteps=args.timesteps, tb_log_name=args.experiment_name)
    if args.save_checkpoint_frequency:
        checkpoint_callback = CheckpointCallback(
            save_freq=(args.save_checkpoint_frequency // env.num_envs),
            save_path=path_checkpoint,
            name_prefix=args.experiment_name,
        )
        learn_kwargs["callback"] = checkpoint_callback
        print(f"Checkpoints enabled at: {abs_path_checkpoint}")

    try:
        model.learn(**learn_kwargs)
    except (KeyboardInterrupt, ConnectionError, ConnectionResetError):
        print("Training interrupted. Cleaning up...")
    finally:
        cleanup()
