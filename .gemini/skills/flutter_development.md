# Skill: Flutter Feature Development Workflow

This skill provides instructions for adding new features or screens to the DreamsClub Flutter project.

## Project Context
- **Framework**: Flutter (Material 3)
- **State Management**: Provider / ChangeNotifier
- **Backend**: Firebase (Auth, Firestore, Messaging, Storage)
- **Styling**: Google Fonts (Oswald, Roboto, Open Sans) as defined in `lib/main.dart` or `GEMINI.md`.

## Workflow Steps

### 1. Planning
- Identify the purpose of the new screen/feature.
- Check existing widgets in `lib/widgets` for reuse (e.g., `ScaffoldWithNavBar`, custom buttons).
- Verify if new models are needed in `lib/models`.

### 2. Implementation
- Create new screen files in `lib/screens/`.
- Use `Consumer<UserProvider>` or other relevant providers if state is needed.
- Follow the visual style: Dark themes, vibrant accents, and custom typography.
- Use `go_router` for navigation if configured, or standard `Navigator` based on search results in `main.dart`.

### 3. State Management
- If the feature requires global state, add it to an existing provider or create a new one in `lib/providers/`.
- Register new providers in `lib/main.dart`'s `MultiProvider`.

### 4. Verification
- Run `flutter analyze` to check for errors.
- Run `flutter format .` to ensure code consistency.
- Verify the UI in the preview server.

## Relevant Files
- `GEMINI.md`: Full architectural and design guidelines.
- `lib/main.dart`: Entry point and theme definition.
- `lib/providers/user_provider.dart`: Core user state.
