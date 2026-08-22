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

# --- 2. Versionado Inteligente ---
$pubspecContent = Get-Content pubspec.yaml
$versionLine = $pubspecContent | Select-String "version: " | Select-Object -First 1
$fullVersion = $versionLine.ToString().Trim().Replace("version: ", "")

# Parsear versión actual (Major.Minor.Patch+Build)
$versionParts = $fullVersion.Split("+")
$semVer = $versionParts[0]
$buildNumber = [int]$versionParts[1]

$semParts = $semVer.Split(".")
$major = [int]$semParts[0]
$minor = [int]$semParts[1]
$patch = [int]$semParts[2]

Write-Host "Versión Actual: $semVer (Build $buildNumber)"
Write-Host "Selecciona el tipo de actualización:"
Write-Host "[1] Patch ($major.$minor.$($patch+1)) - Corrección de errores"
Write-Host "[2] Minor ($major.$($minor+1).0) - Nuevas funcionalidades compatibles"
Write-Host "[3] Major ($($major+1).0.0) - Cambios incompatibles/grandes"
Write-Host "[4] Ninguno (Mantener $semVer) - Solo nueva build"

do {
    $selection = Read-Host "Opción (1-4)"
} until ($selection -match "^[1-4]$")

switch ($selection) {
    "1" { $patch++; $newSemVer = "$major.$minor.$patch" }
    "2" { $minor++; $patch = 0; $newSemVer = "$major.$minor.$patch" }
    "3" { $major++; $minor = 0; $patch = 0; $newSemVer = "$major.$minor.$patch" }
    "4" { $newSemVer = $semVer }
}

$newBuildNumber = $buildNumber + 1
$newVersion = "$newSemVer+$newBuildNumber"

Write-Host "Actualizando versión a: $newVersion"

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

# --- 7. Actualización de Versión en Firestore ---
Write-Host "Actualizando versión en la base de datos de Firestore (config/app)..."
cmd /c "node dreams-admin\update_version.mjs"
