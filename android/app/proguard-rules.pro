# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Core (Fixes assembleRelease R8 failures)
-dontwarn com.google.android.play.core.**

# Better Player and Media3
-dontwarn androidx.media3.**

# Workmanager
-dontwarn com.google.common.util.concurrent.ListenableFuture

# Native Methods & JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for obfuscated Crashlytics stack traces
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

