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
