# PowerShell Build Script - DreamsClub
# Distribución via GitHub Releases (no Firebase App Distribution)

$ErrorActionPreference = "Stop"

# --- Configuración ---
$APP_NAME = "DreamsClub"

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

$selection = "1";#
    $selection = Read-Host "Opción (1-4)"


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
Write-Host "Compilando APK para Android (arm64-v8a split)..."
cmd /c "flutter build apk --release --split-per-abi --no-tree-shake-icons --android-skip-build-dependency-validation"
if ($LASTEXITCODE -ne 0) { throw "Error al compilar" }

# --- 4. Renombrar APK arm64-v8a ---
$outputFolder = "build\app\outputs\flutter-apk"
$originalApkPath = Join-Path $outputFolder "app-arm64-v8a-release.apk"
$newApkPath = Join-Path $outputFolder "$APP_NAME.apk"

if (Test-Path $originalApkPath) {
    Copy-Item -Path $originalApkPath -Destination $newApkPath -Force
    Write-Host "APK renombrado a: $APP_NAME.apk"
}
else {
    Write-Error "No se encontró el APK generado en $originalApkPath"
    exit 1
}

# --- 5. Commit, Tag y Push en Git ---
$commitMessage = "chore(release): version $newVersion"
Write-Host "Creando commit y tag en Git..."
git add pubspec.yaml
git commit -m "$commitMessage"
git tag -a "v$newSemVer" -m "$commitMessage"
git push
git push --tags
Write-Host "Commit, tag ('v$newSemVer') y push a GitHub completados."
Write-Host ""
Write-Host ">> APK listo en: $newApkPath"
Write-Host ">> Ahora ve a GitHub → Releases → 'Draft a new release' y selecciona el tag v$newSemVer"
Write-Host ">> Adjunta el APK: DreamsClub-arm64-v8a-release.apk"
Write-Host ">> Publica el release para que los usuarios reciban la actualización."

# --- 6. Actualización de Versión en Firestore ---
Write-Host "Actualizando versión en la base de datos de Firestore (config/app)..."
cmd /c "node dreams-admin\update_version.mjs"
Write-Host "Proceso completo. Version $newVersion publicada."
