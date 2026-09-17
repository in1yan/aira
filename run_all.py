import subprocess
import sys
import os
import time

def main():
    root_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.join(root_dir, "backend")

    print("=" * 65)
    print("  Starting Aira Smart Flash Card Unified Ecosystem")
    print("=" * 65)
    print("  - Unified Server:             http://127.0.0.1:8000")
    print("  - Web Admin Portal:           http://127.0.0.1:8000/admin/")
    print("  - Mobile API Endpoints:       http://127.0.0.1:8000/api")
    print("  - Interactive API Docs:       http://127.0.0.1:8000/docs")
    print("=" * 65)

    # Start Unified Backend (Port 8000)
    backend_proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"],
        cwd=backend_dir
    )

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping Aira backend service...")
        backend_proc.terminate()
        backend_proc.wait()
        print("Aira service stopped gracefully.")

if __name__ == "__main__":
    main()
