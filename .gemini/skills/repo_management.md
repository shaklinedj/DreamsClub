# Skill: Repository Management and Synchronization

This skill provides instructions for maintaining the DreamsClub GitHub repository and keeping all components (Flutter, Admin Panel, Functions) in sync.

## Repository Structure
- `lib/`: Flutter mobile application.
- `dreams-admin/`: Admin dashboard (Astro/React/TypeScript).
- `functions/`: Firebase Cloud Functions.
- `.idx/`: Firebase Studio/Cloud SDK configuration.

## Common Git Tasks

### 1. Synchronizing Changes
To push all changes while ensuring large files don't block the push:
1. Verify `.gitignore` includes `.firebase/`, `node_modules/`, and large build files.
2. If history is bloated and push fails, use the clean branch strategy:
   ```bash
   git checkout --orphan temp_branch
   git add -A
   git commit -m "feat: sync all project files"
   git branch -D main_branch
   git branch -m main_branch
   git push origin main_branch -f
   ```

### 2. Managing the Admin Sub-module
- The `dreams-admin` folder is part of the main repository. Do NOT keep a separate `.git` folder inside it unless using git submodules.
- If a `.git` folder appears in `dreams-admin`:
  ```bash
  Remove-Item -Recurse -Force dreams-admin\.git
  git rm --cached dreams-admin -f
  git add .
  ```

### 3. Commit Conventions
- Use descriptive prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `style:`.
- Ensure everything is formatted with `flutter format .` before committing.
