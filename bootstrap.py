import os
import shutil
import subprocess
import sys
import importlib.util
from pathlib import Path

# --- CONFIGURATION ---
REQUIRED_COMMANDS = ["entr", "nvim", "zathura", "xdotool"]
# Map command names to actual package names if they differ by package manager
PKG_MAP = {
    "nvim": "neovim", 
    "entr": "entr",
    "zathura": "zathura-pdf-poppler",
    "xdotool": "xdotool",
}
# List of directories in the script folder to skip during sync
IGNORED_DIRS = {".git", "other", "__pycache__"}
# ---------------------

def install_and_import(package):
    """Ensures a python package is installed and imports it."""
    try:
        return importlib.import_module(package)
    except ImportError:
        print(f"Installing missing dependency: {package}...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            return importlib.import_module(package)
        except Exception as e:
            print(f"Failed to install {package}. Proceeding with basic detection. Error: {e}")
            return None

def ensure_installed():
    """Checks for required commands and installs them using the detected package manager."""
    distro = install_and_import('distro')
    os_id = distro.id() if (distro and os.name != 'nt') else ('windows' if os.name == 'nt' else 'linux')
    
    # Define package manager commands and flags
    # Format: { 'distro_id': (binary_to_check, [install_command_args], use_sudo) }
    managers = {
        "arch": ("pacman", ["pacman", "-S", "--needed", "--noconfirm"], True),
        "ubuntu": ("apt-get", ["apt-get", "install", "-y"], True),
        "debian": ("apt-get", ["apt-get", "install", "-y"], True),
        "fedora": ("dnf", ["dnf", "install", "-y"], True),
        "centos": ("yum", ["yum", "install", "-y"], True),
        "windows": ("winget", ["winget", "install", "--exact", "--silent"], False),
        "darwin": ("brew", ["brew", "install"], False),
    }

    missing = [cmd for cmd in REQUIRED_COMMANDS if shutil.which(cmd) is None]
    
    if not missing:
        print(f"✅ All required packages ({', '.join(REQUIRED_COMMANDS)}) are already installed.")
        return

    print(f"Missing commands: {missing}")
    
    # Identify the correct manager
    manager_info = managers.get(os_id)
    if not manager_info:
        # Fallback: find any known package manager binary on the PATH
        for info in managers.values():
            if shutil.which(info[0]):
                manager_info = info
                break
    
    if not manager_info:
        print("❌ Could not detect a supported package manager. Please install missing packages manually.")
        return

    bin_name, base_cmd, use_sudo = manager_info
    pkgs_to_install = [PKG_MAP.get(m, m) for m in missing]

    confirm = input(f"Detected {bin_name} on {os_id}. Install {pkgs_to_install}? (y/n): ").lower()
    if confirm != 'y':
        return

    try:
        full_cmd = (["sudo"] if use_sudo and os.name != 'nt' else []) + base_cmd + pkgs_to_install
        print(f"Running: {' '.join(full_cmd)}")
        subprocess.run(full_cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error during installation: {e}")

def sync_to_config():
    """Syncs local files to the ~/.config directory."""
    source_dir = Path(__file__).parent.absolute()
    dest_dir = Path.home() / ".config"
    script_name = Path(__file__).name
    
    dest_dir.mkdir(parents=True, exist_ok=True)
    print(f"Syncing from {source_dir} to {dest_dir}...")

    for item in source_dir.iterdir():
        if item.name == script_name or (item.is_dir() and item.name in IGNORED_DIRS):
            continue

        target_path = dest_dir / item.name
        try:
            if item.is_dir():
                shutil.copytree(item, target_path, dirs_exist_ok=True)
                print(f"Copied directory: {item.name}")
            else:
                shutil.copy2(item, target_path)
                print(f"Copied file: {item.name}")
        except Exception as e:
            print(f"Error copying {item.name}: {e}")

def main():
    # 1. Ask for Package Installation
    if input("Run ensure_installed() to check/install system packages? (y/n): ").lower() == 'y':
        ensure_installed()
    else:
        print("Skipped package installation.")

    # 2. Ask for Config Sync
    if input("Run sync_to_config() to copy files to ~/.config? (y/n): ").lower() == 'y':
        sync_to_config()
    else:
        print("Skipped config sync.")

if __name__ == "__main__":
    main()
