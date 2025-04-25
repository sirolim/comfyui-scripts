import os
import subprocess
import sys

def activate_venv(venv_path):
    """Activate the virtual environment by updating PATH and VIRTUAL_ENV."""
    activate_script = os.path.join(venv_path, "Scripts", "activate.bat")
    if not os.path.exists(activate_script):
        print(f"Error: Virtual environment not found at {venv_path}")
        sys.exit(1)
    
    venv_bin = os.path.join(venv_path, "Scripts")
    os.environ["PATH"] = f"{venv_bin};{os.environ['PATH']}"
    os.environ["VIRTUAL_ENV"] = venv_path
    print(f"Activated virtual environment: {venv_path}")

def install_requirements(custom_nodes_dir):
    """Install requirements.txt from each custom node directory."""
    if not os.path.exists(custom_nodes_dir):
        print(f"Error: Custom nodes directory not found at {custom_nodes_dir}")
        sys.exit(1)

    for node_dir in os.listdir(custom_nodes_dir):
        node_path = os.path.join(custom_nodes_dir, node_dir)
        if os.path.isdir(node_path):
            requirements_file = os.path.join(node_path, "requirements.txt")
            if os.path.exists(requirements_file):
                print(f"Found requirements.txt in {node_dir}. Installing...")
                try:
                    result = subprocess.run(
                        [sys.executable, "-m", "pip", "install", "-r", requirements_file],
                        capture_output=True,
                        text=True,
                        check=True
                    )
                    print(f"Successfully installed requirements for {node_dir}")
                    print(result.stdout)
                except subprocess.CalledProcessError as e:
                    print(f"Error installing requirements for {node_dir}:")
                    print(e.stderr)
            else:
                print(f"No requirements.txt found in {node_dir}")

def main():
    comfyui_dir = r"C:\Tools\Comfy-Portable\ComfyUI"
    venv_path = os.path.join(comfyui_dir, "venv")
    custom_nodes_dir = os.path.join(comfyui_dir, "custom_nodes")

    activate_venv(venv_path)
    install_requirements(custom_nodes_dir)

if __name__ == "__main__":
    main()