---
name: security-hardening
description: >-
  Use this skill to implement security measures like environment variables, encrypted local storage,
  obfuscated builds, root/jailbreak detection, ProGuard/R8 configurations, and anti-decompilation rules.
---

# Security Hardening for Mobile Applications

This skill provides step-by-step instructions and snippets to implement environment variable separation, data encryption, code obfuscation, anti-decompilation, and device integrity checks.

---

## 1. Environment Variable Setup (.env)

Securely isolate API keys and credentials from source control using environment variables.

### Setup Steps
1. Add the environment configuration package to the project:
   ```shell
   flutter pub add flutter_dotenv
   ```
2. Add `.env` to the asset declarations in `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. Load the `.env` file at application startup in `lib/main.dart`:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await dotenv.load(fileName: ".env");
     runApp(const MyApp());
   }
   ```
4. Access environment variables safely in your code:
   ```dart
   final String apiKey = dotenv.env['API_KEY'] ?? 'default_fallback';
   ```
5. **Git Protection**: Ensure `.env` and local secrets are excluded from Git:
   Add this to your `.gitignore`:
   ```text
   # Secrets and Env files
   .env
   .env.local
   *.env
   ```
6. Create a `.env.example` in the project root containing placeholder names to share the structure without exposing secrets:
   ```text
   API_KEY=your_api_key_here
   API_URL=https://api.example.com
   FIREBASE_API_KEY=placeholder_firebase_key
   ```

---

## 2. Secure Storage Configuration

Encrypt all sensitive client-side data (like JWT tokens, passwords, and API credentials).

### Setup Steps
1. Add the secure storage package:
   ```shell
   flutter pub add flutter_dotenv flutter_secure_storage
   ```
2. Create a secure storage helper (`lib/services/secure_storage_service.dart`):
   ```dart
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';

   class SecureStorageService {
     // Singleton pattern
     SecureStorageService._privateConstructor();
     static final SecureStorageService instance = SecureStorageService._privateConstructor();

     final _storage = const FlutterSecureStorage(
       aOptions: AndroidOptions(
         encryptedSharedPreferences: true,
       ),
       iOptions: IOSOptions(
         accessibility: KeychainAccessibility.first_unlock,
       ),
     );

     Future<void> write(String key, String value) async {
       await _storage.write(key: key, value: value);
     }

     Future<String?> read(String key) async {
       return await _storage.read(key: key);
     }

     Future<void> delete(String key) async {
       await _storage.delete(key: key);
     }

     Future<void> clearAll() async {
       await _storage.deleteAll();
     }
   }
   ```

---

## 3. Anti-Decompilation & Android Hardening

Hardening the Android build against decompilation, reverse engineering, and backup tampering.

### Setup Steps
1. **Disable Backup & Cleartext Traffic**
   Open `android/app/src/main/AndroidManifest.xml` and ensure standard protections are in place:
   ```xml
   <application
       android:label="DreamsClub"
       android:name="${applicationName}"
       android:icon="@mipmap/ic_launcher"
       android:allowBackup="false"
       android:fullBackupContent="false"
       android:usesCleartextTraffic="false">
       <!-- ... -->
   </application>
   ```
2. **Setup ProGuard / R8 Obfuscation**
   Ensure ProGuard rules are enabled in `android/app/build.gradle`:
   ```groovy
   android {
       // ...
       buildTypes {
           release {
               signingConfig signingConfigs.release
               minifyEnabled true
               shrinkResources true
               proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
           }
       }
   }
   ```
3. **Configure ProGuard Rules File**
   Create or edit `android/app/proguard-rules.pro` to define obfuscation exemptions:
   ```proguard
   # Flutter Wrapper obfuscation exemptions
   -keep class io.flutter.app.** { *; }
   -keep class io.flutter.plugin.** { *; }
   -keep class io.flutter.util.** { *; }
   -keep class io.flutter.view.** { *; }
   -keep class io.flutter.embedding.** { *; }
   -keep class io.flutter.plugins.** { *; }

   # Keep native method names intact to prevent binding errors
   -keepclasseswithmembernames class * {
       native <methods>;
   }
   ```

---

## 4. Code Obfuscation in Flutter Builds

Flutter supports compiling Dart code into machine code that is heavily obfuscated.

### Compilation Commands
Always run the release compilation using these parameters to strip debug symbols and obfuscate:
- **Android APK**:
  ```shell
  flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
  ```
- **Android AppBundle**:
  ```shell
  flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
  ```
- **iOS IPA (iOS)**:
  ```shell
  flutter build ipa --obfuscate --split-debug-info=build/ios/outputs/symbols
  ```

---

## 5. Root & Jailbreak Detection

Detect compromised operating systems to mitigate credential dumping and memory hooking.

### Setup Steps
1. Add the root detection package:
   ```shell
   flutter pub add flutter_jailbreak_detection
   ```
2. Implement checking logic during app startup or before sensitive operations:
   ```dart
   import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

   Future<bool> checkDeviceIntegrity() async {
     bool jailbrokenOrRooted = true;
     bool developerModeActive = true;

     try {
       jailbrokenOrRooted = await FlutterJailbreakDetection.jailbroken;
       developerModeActive = await FlutterJailbreakDetection.developerMode;
     } catch (e) {
       // Fail-secure: assume compromised if check fails
       jailbrokenOrRooted = true;
     }

     if (jailbrokenOrRooted) {
       // Take secure action: log user out, restrict access, or alert
       return false;
     }
     return true;
   }
   ```

---

## 6. Verification Checklist

To verify that the obfuscation and hardening worked:
1. **Check Obfuscation**: Use a tool like `jadx` or `apktool` on the generated APK. Import the classes.dex file. The Dart code should be compiled into binary instructions (libapp.so) which cannot be reverse engineered back to readable Dart code.
2. **Check Java/Kotlin Obfuscation**: Check that classes outside of the exempted Flutter SDK classes in ProGuard are obfuscated (e.g. renamed to `a`, `b`, `c`).
3. **Verify Git Exclusions**: Run `git status --ignored` to confirm `.env` files are ignored and will not be tracked.
