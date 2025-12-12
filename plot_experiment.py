import os
import argparse
import glob
from tensorboard.backend.event_processing import event_accumulator
import matplotlib.pyplot as plt


def find_event_file(path_pattern):
    """Recibe un patrón (event*) y devuelve el archivo más reciente."""
    files = glob.glob(path_pattern)

    if not files:
        raise FileNotFoundError(f"No se encontraron archivos para: {path_pattern}")

    # Ordenar por fecha (más reciente primero)
    files.sort(key=os.path.getmtime, reverse=True)

    print(f"✔ Archivo encontrado: {files[0]}")
    return files[0]


def load_events(file_path):
    print(f"Cargando archivo: {file_path}")

    ea = event_accumulator.EventAccumulator(
        file_path,
        size_guidance={event_accumulator.SCALARS: 0},
    )
    ea.Reload()
    return ea


def plot_scalar(ea, tag, output):
    events = ea.Scalars(tag)
    steps = [e.step for e in events]
    values = [e.value for e in events]

    plt.figure(figsize=(10, 5))
    plt.plot(steps, values)
    plt.xlabel("Step")
    plt.ylabel(tag)
    plt.title(tag)
    plt.grid(True)

    out_path = os.path.join(output, tag.replace("/", "_") + ".png")
    plt.savefig(out_path)
    plt.close()

    print(f"✔ Guardado: {out_path}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True, help="Ruta o patrón al archivo events.out")
    parser.add_argument("--out", default="plots", help="Carpeta donde guardar las gráficas")
    args = parser.parse_args()

    os.makedirs(args.out, exist_ok=True)

    # Expande wildcard y obtiene el archivo correcto
    event_file = find_event_file(args.file)

    ea = load_events(event_file)

    tags = ea.Tags()["scalars"]
    print("\n=== MÉTRICAS ENCONTRADAS ===")
    for t in tags:
        print("  -", t)
    print()

    for tag in tags:
        plot_scalar(ea, tag, args.out)

    print("\n✔ Listo. Todas las gráficas fueron generadas.")


if __name__ == "__main__":
    main()
