import platform
import os
import subprocess
import psutil

def run_command(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True)
    except Exception as e:
        return f"Error running {cmd}: {e}"

print("===== CONTAINER ENVIRONMENT INFO =====")
print(f"Python version: {platform.python_version()}")
print(f"OS: {platform.system()} {platform.release()} ({platform.version()})")
print(f"CPU Cores: {psutil.cpu_count(logical=True)}")
print(f"RAM: {round(psutil.virtual_memory().total / (1024**3), 2)} GiB")
print("\n--- Environment Variables ---")
for k, v in os.environ.items():
    print(f"{k}={v}")
print("\n--- Disk Usage ---")
print(run_command("df -h"))
print("\n--- Memory Usage ---")
print(run_command("free -h"))
print("\n--- Installed Python Packages ---")
print(run_command("pip freeze"))