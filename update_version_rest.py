import json
import os
import urllib.request
import urllib.parse
from datetime import datetime, timezone

def main():
    config_path = r"C:\Users\Dell\.config\configstore\firebase-tools.json"
    if not os.path.exists(config_path):
        print(f"Error: {config_path} not found")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    tokens = data.get("tokens", {})
    access_token = tokens.get("access_token")
    if not access_token:
        for k, v in tokens.items():
            if isinstance(v, dict) and "access_token" in v:
                access_token = v["access_token"]
                break
            elif k == "access_token":
                access_token = v
                break

    if not access_token:
        print("Error: access_token not found in firebase-tools.json")
        return

    print("✅ Token Firebase CLI encontrado!")
    
    pubspec_path = "pubspec.yaml"
    if not os.path.exists(pubspec_path):
        print(f"Error: {pubspec_path} not found")
        return

    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    import re
    version_match = re.search(r"version:\s*([^\s+]+)", content)
    if not version_match:
        print("Error: version not found in pubspec.yaml")
        return
    
    version = version_match.group(1)
    print(f"📦 Versión de pubspec.yaml detectada: {version}")

    project_id = "dreams-casino-app"
    document_path = "config/app"
    
    url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/{document_path}?updateMask.fieldPaths=latestVersion&updateMask.fieldPaths=downloadUrl&updateMask.fieldPaths=updatedAt"
    
    current_time = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    
    body = {
        "name": f"projects/{project_id}/databases/(default)/documents/{document_path}",
        "fields": {
            "latestVersion": {
                "stringValue": version
            },
            "downloadUrl": {
                "stringValue": "https://dreams-casino-app.web.app/download"
            },
            "updatedAt": {
                "timestampValue": current_time
            }
        }
    }
    
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        },
        method="PATCH"
    )
    
    try:
        with urllib.request.urlopen(req) as resp:
            resp_data = json.loads(resp.read().decode("utf-8"))
            print("🎉 ¡Firestore actualizado con éxito!")
            print("latestVersion es ahora:", version)
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
    except Exception as e:
        print("Error inesperado:", e)

if __name__ == "__main__":
    main()
