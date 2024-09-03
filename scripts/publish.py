import sys
from pathlib import Path
import hashlib
import os
import requests

channel = "https://prefix.dev/api/v1/upload/mojo-community"
token = os.environ.get("PREFIX_API_KEY")
if not token:
    print("Please set PREFIX_API_KEY to your Prefix API key.")
    sys.exit(1)

def upload(fn):
    data = fn.read_bytes()

    # skip if larger than 100Mb
    if len(data) > 100 * 1024 * 1024:
        print("Skipping", fn, "because it is too large")
        return

    name = fn.name
    sha256 = hashlib.sha256(data).hexdigest()
    headers = {
        "X-File-Name": name,
        "X-File-SHA256": sha256,
        "Authorization": f"Bearer {token}",
        "Content-Length": str(len(data) + 1),
        "Content-Type": "application/octet-stream",
    }

    r = requests.post(channel, data=data, headers=headers)
    print(f"Uploaded package {name} with status  {r.status_code}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        upload(Path(sys.argv[1]))
    else:
        print("Usage: upload.py <package>")
        sys.exit(1)
