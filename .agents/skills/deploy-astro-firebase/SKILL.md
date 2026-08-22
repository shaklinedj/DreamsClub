---
name: deploy-astro-firebase
description: Remember to build and deploy Astro Dashboard changes to Firebase.
---

# Deploy & Release Automation (Astro Dashboard + Flutter App)

This skill documents the build, deployment, and versioning pipelines for the **Astro Dashboard** and **Flutter Mobile App**.

---

## 1. Deploy Astro Dashboard to Firebase

When you make changes to the Astro dashboard in the `dreams-admin` directory (e.g. modifying TSX components, Astro pages, Tailwind config), those changes are only local. To make them live for the user, you MUST:

1. Build the Astro project.
2. Deploy the built static files to Firebase Hosting.

### Instructions:
1. Always execute the build and deploy commands together after finishing your code edits.
2. The working directory for these commands must be `dreams-admin`.
3. Example command to run:

```bash
cd dreams-admin
pnpm run build
firebase deploy --only hosting
```

---

## 2. Release & Version Sync Automation (Flutter App)

To compile a new release of the Flutter mobile app and automatically notify users of the update, use the centralized build scripts:
- **Windows (PowerShell)**: [version_and_build.ps1](file:///e:/DreamsClub-master/DreamsClub-master/version_and_build.ps1)
- **Linux/macOS (Bash)**: [version_and_build.sh](file:///e:/DreamsClub-master/DreamsClub-master/version_and_build.sh)

### What the build scripts do:
1. **Interactive Versioning**: Prompts to choose the type of release (Patch, Minor, Major, or None) and increments the version in `pubspec.yaml`.
2. **Build Compilation**: Cleans the project cache and compiles the production APK (`flutter build apk --release`).
3. **Firestore Syncing**: Automatically triggers [update_version.mjs](file:///e:/DreamsClub-master/DreamsClub-master/dreams-admin/update_version.mjs), which parses the newly bumped version in `pubspec.yaml` and updates Firestore document `config/app`'s `latestVersion` field. This triggers the in-app update banner for older clients instantly.
4. **Git Tagging**: Commits the changes and creates a Git release tag (e.g., `v1.0.2`).
5. **Distribution**: Uploads the compiled APK to Firebase App Distribution for testers.

### How to release a new version:
Simply execute the script in your PowerShell or bash terminal:
```powershell
.\version_and_build.ps1
```
The script handles everything from version bumping to database updating automatically!
