#!/bin/bash

# Salir inmediatamente si un comando falla
set -e

# --- Configuración ---
APP_NAME="DreamsFidelizacion"
FIREBASE_APP_ID="1:326453914816:android:f9a04e57ae0461e6291125"
TESTER_GROUP="testers"

# --- 1. Verificación de Git ---
echo "🔍 Verificando el estado de Git..."
if ! git diff-index --quiet HEAD --; then
    echo "❌ Error: Tienes cambios sin confirmar. Por favor, haz un commit o descarta los cambios antes de ejecutar este script."
    exit 1
fi
echo "✅ Repositorio limpio."

# --- 2. Versionado ---
full_version=$(grep 'version: ' pubspec.yaml | sed 's/version: //')
main_version=$(echo "$full_version" | cut -d'+' -f1)
build_number=$(echo "$full_version" | cut -d'+' -f2)
new_build_number=$((build_number + 1))
new_version="$main_version+$new_build_number"
echo "🚀 Versionando de $full_version a $new_version..."

sed -i.bak "s/version: $full_version/version: $new_version/" pubspec.yaml
rm pubspec.yaml.bak
echo "✅ pubspec.yaml actualizado."

# --- 3. Limpieza y Compilación ---
echo "🧹 Limpiando el proyecto..."
flutter clean
echo "📦 Compilando APK para Android..."
flutter build apk --release

# --- 4. Renombrar APK ---
output_folder="build/app/outputs/flutter-apk"
original_apk_path="$output_folder/app-release.apk"
new_apk_path="$output_folder/${APP_NAME}-${new_version}.apk"
mv "$original_apk_path" "$new_apk_path"
echo "✅ APK renombrado a: ${APP_NAME}-${new_version}.apk"

# --- 5. Commit y Tag en Git ---
commit_message="chore(release): version $new_version"
echo "💾 Creando commit y tag en Git..."
git add pubspec.yaml
git commit -m "$commit_message"
git tag -a "v$new_version" -m "$commit_message"
echo "✅ Commit y tag ('v$new_version') creados."

# --- 6. Subida a Firebase ---
echo "🔥 Subiendo a Firebase App Distribution..."
firebase appdistribution:distribute "$new_apk_path" \
    --app "$FIREBASE_APP_ID" \
    --release-notes "$commit_message" \
    --groups "$TESTER_GROUP"

# --- Finalización ---
echo "🎉 ¡Proceso completado! La versión $new_version está disponible para el grupo '$TESTER_GROUP' en Firebase."
