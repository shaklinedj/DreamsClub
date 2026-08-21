# Consistency Between Flutter and Astro Dashboard

When modifying Firebase interactions, data models, or schemas, **you MUST ensure consistency between the Flutter mobile application and the Astro web dashboard.**

This project is an ecosystem. If you change a field name, collection name, or data structure in one place, you must verify and update the other.

## Key Directives:

1. **Shared Database Schema:** The mobile app (Flutter) writes and reads data to/from Firebase, and the Admin Dashboard (Astro) reads and sometimes writes to the exact same Firebase collections.
2. **Naming Conventions:** If you change a key name in Flutter (e.g., `wantsContact` -> `contactConsent`), you MUST update the corresponding React/Astro component that reads this key (e.g., `UserList.tsx`).
3. **Subcollections:** If you change a subcollection name (e.g., `reactions` vs `likes`), both platforms must use the exact same string to query it.
4. **Verification Step:** Whenever making a backend structural change, explicitly search (`grep`) both the Flutter `/lib` folder and the Astro `/dreams-admin/src` folder to catch all instances of the affected data property.

Failure to maintain consistency breaks the ecosystem and results in silent failures where data is written by the app but invisible on the dashboard.
