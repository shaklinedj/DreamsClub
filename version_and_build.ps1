# PowerShell Build Script

$ErrorActionPreference = "Stop"

# --- Configuración ---
$APP_NAME = "DreamsFidelizacion"
$FIREBASE_APP_ID = "1:326453914816:android:f9a04e57ae0461e6291125"
$TESTER_GROUP = "testers"

# --- 1. Verificación y Commit Interactivo de Cambios ---
Write-Host "Verificando el estado de Git..."
if (git diff-index --quiet HEAD --) {
    Write-Host "Repositorio limpio."
}
else {
    Write-Host "Se encontraron cambios sin confirmar."
    git status -s
    $COMMIT_MESSAGE = Read-Host "Por favor, introduce un mensaje para el commit de estos cambios y presiona Enter"
    
    if ([string]::IsNullOrWhiteSpace($COMMIT_MESSAGE)) {
        $COMMIT_MESSAGE = "chore: Commit de cambios previos al build"
    }

    git add .
    git commit -m "$COMMIT_MESSAGE"
    Write-Host "Cambios guardados en un nuevo commit."
}

# --- 2. Versionado ---
$pubspecContent = Get-Content pubspec.yaml
$versionLine = $pubspecContent | Select-String "version: " | Select-Object -First 1
$fullVersion = $versionLine.ToString().Trim().Replace("version: ", "")
$mainVersion = $fullVersion.Split("+")[0]
$buildNumber = [int]$fullVersion.Split("+")[1]
$newBuildNumber = $buildNumber + 1
$newVersion = "$mainVersion+$newBuildNumber"

Write-Host "Versionando de $fullVersion a $newVersion..."

$escapedFullVersion = [regex]::Escape($fullVersion)
(Get-Content pubspec.yaml) -replace "version: $escapedFullVersion", "version: $newVersion" | Set-Content pubspec.yaml
Write-Host "pubspec.yaml actualizado."

# --- 3. Limpieza y Compilación ---
Write-Host "Compilando APK para Android..."
cmd /c "flutter build apk --release --no-tree-shake-icons"
if ($LASTEXITCODE -ne 0) { throw "Error al compilar" }

# --- 4. Renombrar APK ---
$outputFolder = "build\app\outputs\flutter-apk"
$originalApkPath = Join-Path $outputFolder "app-release.apk"
$newApkPath = Join-Path $outputFolder "$APP_NAME-$newVersion.apk"

if (Test-Path $originalApkPath) {
    Move-Item -Path $originalApkPath -Destination $newApkPath -Force
    Write-Host "APK renombrado a: $APP_NAME-$newVersion.apk"
}
else {
    Write-Error "No se encontró el APK generado en $originalApkPath"
    exit 1
}

# --- 5. Commit y Tag en Git ---
$commitMessage = "chore(release): version $newVersion"
Write-Host "Creando commit y tag en Git..."
git add pubspec.yaml
git commit -m "$commitMessage"
git tag -a "v$newVersion" -m "$commitMessage"
Write-Host "Commit y tag ('v$newVersion') creados."

# --- 6. Subida a Firebase ---
Write-Host "Subiendo a Firebase App Distribution..."
if ([string]::IsNullOrWhiteSpace($FIREBASE_APP_ID) -or $FIREBASE_APP_ID -eq "REPLACE_WITH_FIREBASE_APP_ID") {
    Write-Host "Firebase App ID no configurado. Omite la distribución."
}
else {
    # Usar cmd /c para asegurar que se ejecute el comando firebase si es un batch file
    cmd /c "npx firebase appdistribution:distribute `"$newApkPath`" --app `"$FIREBASE_APP_ID`" --release-notes `"$commitMessage`" --groups `"$TESTER_GROUP`""
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Proceso completado! La versión $newVersion está disponible para el grupo '$TESTER_GROUP' en Firebase."
    }
    else {
        Write-Host "Error al subir a Firebase App Distribution."
        exit 1
    }
}
