#!/bin/bash

# Salir inmediatamente si un comando falla
set -e

# --- Configuración ---
APP_NAME="DreamsFidelizacion"
FIREBASE_APP_ID="1:326453914816:android:f9a04e57ae0461e6291125"
TESTER_GROUP="testers"

# --- 1. Verificación y Commit Interactivo de Cambios ---
echo "🔍 Verificando el estado de Git..."
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Se encontraron cambios sin confirmar."
    git status -s # Muestra un estado resumido de los cambios
    echo "👇 Por favor, introduce un mensaje para el commit de estos cambios y presiona Enter:"
    read -r COMMIT_MESSAGE
    
    # Si el mensaje está vacío, usar uno por defecto
    if [ -z "$COMMIT_MESSAGE" ]; then
        COMMIT_MESSAGE="chore: Commit de cambios previos al build"
    fi

    git add .
    git commit -m "$COMMIT_MESSAGE"
    echo "✅ Cambios guardados en un nuevo commit."
else
    echo "✅ Repositorio limpio."
fi

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
#--- echo "🧹 Limpiando el proyecto..."
#--- flutter clean
echo "📦 Compilando APK para Android..."
flutter build apk --release --no-tree-shake-icons

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
if [ -z "$FIREBASE_APP_ID" ] || [[ "$FIREBASE_APP_ID" == "REPLACE_WITH_FIREBASE_APP_ID" ]]; then
    echo "⚠️  Firebase App ID no configurado. Omite la distribución."
    echo "ℹ️  Configura FIREBASE_APP_ID en el script o como variable de entorno para habilitar la subida."
else
    if firebase appdistribution:distribute "$new_apk_path" \
        --app "$FIREBASE_APP_ID" \
        --release-notes "$commit_message" \
        --groups "$TESTER_GROUP"; then
        echo "🎉 ¡Proceso completado! La versión $new_version está disponible para el grupo '$TESTER_GROUP' en Firebase."
    else
        echo "❌ Error al subir a Firebase App Distribution. Revisa el App ID, autenticación y permisos."
        exit 1
    fi
fi

# --- 7. Actualización de Versión en Firestore ---
echo "📤 Actualizando versión en la base de datos de Firestore (config/app)..."
node dreams-admin/update_version.mjs
