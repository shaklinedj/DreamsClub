---
name: deploy-astro-firebase
description: Remember to build and deploy Astro Dashboard changes to Firebase.
---

# Deploy Astro Dashboard to Firebase

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

Failure to deploy means the user won't see your fixes! Always remember this step for the web dashboard.
