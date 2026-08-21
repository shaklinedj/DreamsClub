import json
import os
import urllib.request
import urllib.parse

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
        print("Error: access_token not found in firebase-tools.json")
        return

    print("✅ Token Firebase CLI encontrado!")
    apk_path = r"E:\DreamsClub-master\DreamsClub-master\build\app\outputs\flutter-apk\app-release.apk"
    if not os.path.exists(apk_path):
        print(f"Error: {apk_path} not found")
        return

    file_size_mb = os.path.getsize(apk_path) / (1024 * 1024)
    print(f"📦 Tamaño del archivo APK: {file_size_mb:.2f} MB")

    bucket = "dreams-casino-app.firebasestorage.app"
    object_name = "releases/DreamsClub.apk"
    encoded_name = urllib.parse.quote(object_name, safe='')

    upload_url = f"https://storage.googleapis.com/upload/storage/v1/b/{bucket}/o?uploadType=media&name={encoded_name}"
    print(f"📤 Subiendo a {bucket}/{object_name}...")

    with open(apk_path, "rb") as f:
        apk_bytes = f.read()

    req = urllib.request.Request(
        upload_url,
        data=apk_bytes,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/vnd.android.package-archive"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as resp:
            resp_data = json.loads(resp.read().decode("utf-8"))
            print("✅ Subida exitosa a Firebase Storage!")
            print("Detalles:", resp_data.get("name"))

        # Set public access
        acl_url = f"https://storage.googleapis.com/storage/v1/b/{bucket}/o/{encoded_name}/acl"
        acl_req = urllib.request.Request(
            acl_url,
            data=json.dumps({"entity": "allUsers", "role": "READER"}).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            },
            method="POST"
        )
        try:
            with urllib.request.urlopen(acl_req) as acl_resp:
                print("✅ Permisos públicos configurados correctamente (allUsers: READER)")
        except Exception as e:
            print("Nota sobre ACL pública:", e)

        public_download_url = f"https://storage.googleapis.com/{bucket}/{object_name}"
        token_download_url = f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded_name}?alt=media"

        print("\n🎉 URLS DE DESCARGA DISPONIBLES:")
        print(f"1. GCS Direct URL: {public_download_url}")
        print(f"2. Firebase Storage URL: {token_download_url}")

        with open(r"E:\DreamsClub-master\DreamsClub-master\dreams-admin\apk_url.txt", "w", encoding="utf-8") as f_out:
            f_out.write(token_download_url)

    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
    except Exception as e:
        print("Error inesperado:", e)

if __name__ == "__main__":
    main()
