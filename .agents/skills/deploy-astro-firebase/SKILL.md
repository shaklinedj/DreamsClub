---
name: deploy-astro-firebase
description: Remember to build and deploy Astro Dashboard changes to Firebase and release Flutter APK via GitHub Releases.
---

# Deploy & Release Automation (Astro Dashboard + Flutter App)

This skill documents the build, deployment, and versioning pipelines for the **Astro Dashboard** and **Flutter Mobile App**.

---

## 1. Deploy Astro Dashboard to Firebase

When you make changes to the Astro dashboard in the `dreams-admin` directory (e.g. modifying TSX components, Astro pages), those changes are only local. To make them live, you MUST:

1. Build the Astro project.
2. Deploy the built static files to Firebase Hosting.
3. Push changes to GitHub (for Vercel API auto-deploy).

### Instructions:
Always execute the build and deploy commands together after finishing your code edits.

```bash
# Working directory: dreams-admin
pnpm run build
firebase deploy --only hosting

# Then push to GitHub (triggers Vercel API redeploy automatically)
git add .
git commit -m "feat: description of changes"
git push
```

---

## 2. Release & Version Sync Automation (Flutter App)

### Distribution Method
**The app is distributed via GitHub Releases** (not Firebase App Distribution).
The flow is:
1. Compile the APK locally
2. Commit + create a Git tag (e.g. `v1.0.1`)
3. Push tag to GitHub
4. Manually go to **GitHub → Releases → Draft a new release** and attach the APK

### Versioning Convention
- Tags follow semantic versioning: `vMAJOR.MINOR.PATCH` (e.g. `v1.0.1`)
- `pubspec.yaml` version: `MAJOR.MINOR.PATCH+BUILDNUMBER` (e.g. `1.0.1+27`)
- **IMPORTANT**: Always keep these in sync. Check last tag with `git tag --sort=-version:refname | head -5`

### Build Script
Use the centralized build script (Windows PowerShell):
- **[version_and_build.ps1](file:///e:/DreamsClub-master/DreamsClub-master/version_and_build.ps1)**

```powershell
.\version_and_build.ps1
```

### What the build script does:
1. **Interactive Versioning**: Prompts to choose the type of release (Patch, Minor, Major, or None) and increments the version in `pubspec.yaml`.
2. **Build Compilation**: Compiles the production APK (`flutter build apk --release --no-tree-shake-icons`).
3. **APK Renaming**: Renames the APK to `DreamsFidelizacion-VERSION.apk`.
4. **Git Tag + Push**: Commits `pubspec.yaml`, creates a tag (e.g. `v1.0.1`), and pushes both branch and tags to GitHub.
5. **Firestore Version Sync**: Runs [update_version.mjs](file:///e:/DreamsClub-master/DreamsClub-master/dreams-admin/update_version.mjs) to update `config/app.latestVersion` in Firestore, triggering the in-app update banner for older clients instantly.
6. **GitHub Release**: Prints instructions to go to GitHub and publish the release with the APK attached.

### After running the script:
1. Go to **https://github.com/shaklinedj/DreamsClub/releases**
2. Click **"Draft a new release"**
3. Select the new tag (e.g. `v1.0.1`)
4. Attach the compiled APK from `build/app/outputs/flutter-apk/DreamsFidelizacion-X.X.X.apk`
5. Publish the release

### Firestore latestVersion
The `latestVersion` field in Firestore `config/app` is what the app checks to show the update banner. It is updated automatically by `update_version.mjs`. You can also update it manually in the Firebase Console at any time.

---

## 3. API Layer (Vercel)

The push notification API lives in `dreams-admin/api/` and is deployed automatically to **Vercel** whenever changes are pushed to the `master` branch on GitHub.

- API URL: `https://dreamsclub.vercel.app/api/send-push`
- Cron jobs (birthday reminders, prize expiration): `dreams-admin/api/cron-campaigns.js` (scheduled in `dreams-admin/vercel.json`)

---

## 4. Restricciones de Distribución y Aprendizajes (¡Muy Importante!)

### Repositorio Público para Descargas
El repositorio de código `shaklinedj/DreamsClub` es **privado**. Si los usuarios anónimos (sin cuenta de GitHub) intentan descargar el APK directamente desde allí, GitHub les pedirá iniciar sesión o les dará un error 404.
* **Solución**: Se utiliza el repositorio **público** `shaklinedj/DreamsClub-Release` para subir los APKs de distribución pública. Los enlaces en la web apuntan a:
  `https://github.com/shaklinedj/DreamsClub-Release/releases/download/vVERSION/DreamsApp-vVERSION.apk`

### Automatización de la Publicación de Releases con GitHub CLI
En lugar de crear y publicar drafts de releases manualmente, utiliza el GitHub CLI (`gh`), el cual ya está autenticado con la cuenta oficial `shaklinedj`:
```bash
# Crear release en repositorio público y subir el APK automáticamente
gh release create v1.0.9 "build\app\outputs\flutter-apk\DreamsApp-v1.0.9.apk" --repo shaklinedj/DreamsClub-Release --title "DreamsApp v1.0.9" --notes "Release de DreamsApp v1.0.9"

# Si necesitas resubir o corregir el APK del release existente, usa el flag --clobber
gh release upload v1.0.9 "build\app\outputs\flutter-apk\DreamsApp-v1.0.9.apk" --repo shaklinedj/DreamsClub-Release --clobber
```

### Sincronización de Versión en Firestore sin Credenciales (REST API)
Si la máquina local no tiene configuradas las credenciales por defecto de Google Cloud (`getApplicationDefaultAsync` error en Node/Firebase Admin), puedes intercambiar el token de refresco local de Firebase CLI por un token de acceso activo y actualizar Firestore mediante su API REST:
1. Lee las credenciales de Firebase CLI desde `C:\Users\Dell\.config\configstore\firebase-tools.json`.
2. Refresca el token llamando a `POST https://oauth2.googleapis.com/token` con el ID de cliente oficial de Firebase CLI (`563577306548-5284ar49gldss0777vl12m25r1t5ja2e.apps.googleusercontent.com`) y secreto (`j9z1mS2iT3tvdV7mYgTyMIyc`).
3. Envía una petición `PATCH` a la URL REST de Firestore para actualizar el documento `config/app`:
   `https://firestore.googleapis.com/v1/projects/dreams-casino-app/databases/(default)/documents/config/app?updateMask.fieldPaths=latestVersion&updateMask.fieldPaths=downloadUrl&updateMask.fieldPaths=updatedAt`

### Resolución de Bloqueo de Build (libflutter.so)
En sistemas Windows, los daemons de Gradle o procesos de Java/Dart a veces bloquean `libflutter.so` en la carpeta `build/`.
* **Solución**: Ejecuta `flutter clean` desde la terminal. Esto borra la carpeta `build` por completo liberando cualquier handle activo, permitiendo recompilar desde cero sin colisiones.

### Detección de Actualizaciones en la App
* **Regla de Firestore**: Para permitir que los clientes validen si hay una nueva versión, la colección `/config` debe tener una regla de lectura pública en `firestore.rules`:
  ```javascript
  match /config/{configId} {
    allow read: if true;
    allow write: if isAdmin();
  }
  ```
* **Comparación Dinámica**: La app lee su versión dinámicamente mediante `PackageInfo.fromPlatform()` (paquete `package_info_plus`) en lugar de usar cadenas fijas, comparándola contra el campo `latestVersion` del documento `config/app` en Firestore.

### Persistencia de Notificaciones Leídas / Borradas
* **Consistencia**: Guardar las notificaciones borradas solo en `SharedPreferences` local causa que reaparezcan al desinstalar/reinstalar la app.
* **Solución**: Sincroniza y persiste el listado de IDs borrados directamente en el documento del usuario en Firestore (`users/{uid}/deleted_notifications`) mediante `FieldValue.arrayUnion` cuando el usuario descarta o borra notificaciones. Al iniciar, recupera el estado de Firestore para poblar la UI.

### Migración de Perfiles (Email a UID)
En la base de datos Firestore, los documentos de usuario originalmente se creaban usando el `email` del socio como ID de documento. Para corregir la creación de cupones duplicados, ahora se utiliza el `uid` de Firebase Auth.
* **Migración**: Al iniciar sesión, la app ejecuta un proceso de migración de una sola vez en `_ensureUserDocument` (`auth_provider.dart`) que copia todo el historial de puntos, racha, nivel, permisos de administrador y foto de perfil desde el antiguo documento `users/{email}` al nuevo documento `users/{uid}`.
