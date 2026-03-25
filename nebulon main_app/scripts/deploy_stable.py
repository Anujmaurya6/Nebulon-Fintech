import os
import hashlib
import sys
import json
import time

PROJECT_ROOT = "C:/project hackathon/nebulon main_app"
LOCK_FILE = os.path.join(PROJECT_ROOT, ".deploy.lock")
HASH_FILE = os.path.join(PROJECT_ROOT, ".last_deploy_hash")
VERSION_FILE = os.path.join(PROJECT_ROOT, "VERSION")

def get_project_hash():
    """Calculate hash of the lib directory to detect changes."""
    sha256_hash = hashlib.sha256()
    lib_path = os.path.join(PROJECT_ROOT, "lib")
    for root, dirs, files in os.walk(lib_path):
        for file in sorted(files):
            file_path = os.path.join(root, file)
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def get_current_version():
    if not os.path.exists(VERSION_FILE):
        return "v1.0.0 (Build 0)"
    with open(VERSION_FILE, "r") as f:
        return f.read().strip()

def update_version():
    current = get_current_version()
    # Simple increment logic for Build number
    if "(Build " in current:
        base, build_part = current.split("(Build ")
        build_num = int(build_part.replace(")", ""))
        new_version = f"{base.strip()} (Build {build_num + 1})"
    else:
        new_version = f"{current} (Build 1)"
    
    with open(VERSION_FILE, "w") as f:
        f.write(new_version)
    return new_version

def deploy():
    force = "--force" in sys.argv
    
    # 1. Check for Lock
    if os.path.exists(LOCK_FILE):
        print("ERROR: Build already in progress. Lock file exists.")
        sys.exit(1)
        
    try:
        # Create Lock
        with open(LOCK_FILE, "w") as f:
            f.write(str(time.time()))
            
        # 2. Check for Changes
        current_hash = get_project_hash()
        last_hash = ""
        if os.path.exists(HASH_FILE):
            with open(HASH_FILE, "r") as f:
                last_hash = f.read().strip()
                
        if current_hash == last_hash and not force:
            print("INFO: No changes detected since last deployment. Skipping build.")
            return

        print(f"STARTING DEPLOYMENT: {get_current_version()}")
        
        # 3. Simulate Build/Deploy (In reality, the agent calls the MCP tool)
        # For this script, we just mark that a deploy should happen.
        # But wait, the script itself should probably trigger the flutter build.
        
        print("Executing: flutter build web --release...")
        ret = os.system("flutter build web --release")
        if ret != 0:
            print("ERROR: Build failed.")
            sys.exit(1)
            
        # 4. Success Handling
        new_ver = update_version()
        with open(HASH_FILE, "w") as f:
            f.write(current_hash)
            
        print(f"SUCCESS: Deployed {new_ver}")
        
    finally:
        # Remove Lock
        if os.path.exists(LOCK_FILE):
            os.remove(LOCK_FILE)

if __name__ == "__main__":
    deploy()
