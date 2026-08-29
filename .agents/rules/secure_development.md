# Coding Conventions & Security Guidelines

This rule enforces strict cybersecurity, secret management, obfuscation, naming, typing, and app protection practices for all generated code. The agent must strictly adhere to these practices whenever writing or modifying code.

---

## 1. Strong Typing & Naming Conventions

### Type Safety
- **Explicit Types**: Avoid using generic dynamic types like `dynamic` (Dart/Flutter), `any` (TypeScript/JavaScript), or untyped variables (Python) unless absolutely necessary.
- **Null Safety**: Always write null-safe code. Check for null values explicitly before access, and use optional chaining/null-coalescing operators.
- **Generics**: Use strongly-typed generics (e.g., `List<String>`, `Map<String, dynamic>`) to ensure compilation-time checks.

### Casing and Naming
- **Classes, Enums, Mixins, Extensions**: Use `PascalCase` (e.g., `class SecurityService {}`).
- **Variables, Functions, Methods**: Use `camelCase` (e.g., `final String apiToken;`, `void validateInput()`).
- **Constants**: Use `camelCase` (standard for Dart) or `UPPER_CASE_WITH_UNDERSCORES` depending on specific project style. Prefer consistency.
- **Files and Folders**: Use `snake_case` (e.g., `secure_storage_service.dart`).
- **Descriptive Names**: Avoid short, ambiguous names (like `t`, `val`, `data`). Use clear, self-documenting names (like `tempToken`, `validatedInput`).

---

## 2. Cybersecurity & Safe Storage

### Secure Data Storage
- **No Sensitive Data in Plain Text**: Never store access tokens, JWTs, personal user information (PII), or database keys in standard `SharedPreferences` (Android), `NSUserDefaults` (iOS), or plain local databases (like Hive or SQLite) without encryption.
- **Encrypted Storage**:
  - In Flutter, use `flutter_secure_storage` (KeyStore for Android, KeyChain for iOS) or encrypted Hive boxes.
  - On other platforms, utilize native secure keystore APIs.

### Input Sanitization & Validation
- **Defense in Depth**: Always sanitize and validate user input on both the client side and the server side.
- **SQL Injection & XSS Prevention**: Use parameterized queries or ORMs. Escape dynamic HTML/JS content.

### Secure Communications
- **HTTPS Only**: Ensure all network calls are made over HTTPS with TLS 1.2 or 1.3.
- **SSL Pinning**: For high-security applications, implement SSL certificate pinning to prevent Man-in-the-Middle (MitM) attacks.
- **Network Security Configuration**: Restrict cleartext traffic in configuration files (e.g., `android:usesCleartextTraffic="false"`).

---

## 3. Environment Variables & Secret Management

### Zero Secrets in Code
- **Never Hardcode Secrets**: Do not write API keys, client secrets, database passwords, or private URLs directly in code.
- **Runtime Environment Injection**:
  - In Dart/Flutter, use `--dart-define` or `--dart-define-from-file` to inject configuration during compilation, or use environment config loaders like `flutter_dotenv`.
  - In JS/Node.js, use `process.env`.
- **Git Protection**:
  - Always append `.env`, `.env.local`, and any dynamic configuration files containing sensitive data to `.gitignore`.
  - Provide a `.env.example` file with placeholder values for other developers.

---

## 4. Code Obfuscation & APK Anti-Decompilation

### Compilation Obfuscation
- **Obfuscate Production Builds**: Always enable obfuscation flags for production builds.
  - Flutter command: `flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols`
- **Proguard & R8 (Android)**:
  - Keep `android/app/proguard-rules.pro` updated.
  - Enable minification and shrinking in `android/app/build.gradle`:
    ```groovy
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    ```

### Anti-Decompilation & Integrity Checks
- **Signature Verification**: Add checks to detect if the APK was re-signed after modification.
- **Root and Jailbreak Detection**: Implement checks (e.g., using `flutter_jailbreak_detection` or platform channels) to warn users or block operation on rooted/jailbroken devices.
- **Disable App Backup**: Ensure data backups are disabled in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  android:allowBackup="false"
  android:fullBackupContent="false"
  ```
- **Screenshot Protection**: For views with highly sensitive information (e.g., credentials, payment forms), prevent screenshots and screen recordings.
