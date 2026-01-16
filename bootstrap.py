import os
import shutil
from pathlib import Path

def sync_to_config():
    # Define source and destination
    source_dir = Path(__file__).parent.absolute()
    dest_dir = Path.home() / ".config"
    
    # Get the name of this script to exclude it
    script_name = Path(__file__).name
    
    # List of directories to ignore
    ignored_dirs = {".git", "other"}
    
    # Ensure destination exists
    dest_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Syncing from {source_dir} to {dest_dir}...")

    for item in source_dir.iterdir():
        # 1. Skip this script
        if item.name == script_name:
            continue
            
        # 2. Skip ignored directories
        if item.is_dir() and item.name in ignored_dirs:
            print(f"Skipping directory: {item.name}")
            continue

        target_path = dest_dir / item.name
        
        try:
            if item.is_dir():
                # Copy directory recursively
                # dirs_exist_ok=True allows updating existing folders (Python 3.8+)
                shutil.copytree(item, target_path, dirs_exist_ok=True)
                print(f"Copied directory: {item.name}")
            else:
                # Copy individual file
                shutil.copy2(item, target_path)
                print(f"Copied file: {item.name}")
        except Exception as e:
            print(f"Error copying {item.name}: {e}")

if __name__ == "__main__":
    sync_to_config()
