import subprocess
import sys
import os
import time

def main():
    root_dir = os.path.dirname(os.path.abspath(__file__))
    admin_backend_dir = os.path.join(root_dir, "admin", "backend")
    user_backend_dir = os.path.join(root_dir, "user", "backend")

    print("=" * 60)
    print("  Starting Aira Smart Flash Card Ecosystem")
    print("=" * 60)
    print("  - User Backend (Mobile API):  http://127.0.0.1:8000")
    print("  - Admin Backend (Web Portal): http://127.0.0.1:8001/admin/")
    print("=" * 60)

    # Start User Backend (Port 8000)
    user_proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"],
        cwd=user_backend_dir
    )

    # Start Admin Backend (Port 8001)
    admin_proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--reload"],
        cwd=admin_backend_dir
    )

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping services...")
        user_proc.terminate()
        admin_proc.terminate()
        user_proc.wait()
        admin_proc.wait()
        print("All services stopped.")

if __name__ == "__main__":
    main()
