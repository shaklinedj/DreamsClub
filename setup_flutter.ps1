# Script para configurar Flutter en Windows
Write-Host "=== Configurando Flutter ===" -ForegroundColor Cyan

# Verificar si Flutter fue descargado
if (Test-Path "C:\src\flutter\bin\flutter.bat") {
    Write-Host "✓ Flutter encontrado en C:\src\flutter" -ForegroundColor Green
    
    # Agregar Flutter al PATH del usuario actual
    $flutterPath = "C:\src\flutter\bin"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$flutterPath*") {
        Write-Host "Agregando Flutter al PATH del usuario..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$currentPath;$flutterPath",
            "User"
        )
        Write-Host "✓ Flutter agregado al PATH" -ForegroundColor Green
        Write-Host "⚠ Necesitarás reiniciar PowerShell para que los cambios surtan efecto" -ForegroundColor Yellow
    } else {
        Write-Host "✓ Flutter ya está en el PATH" -ForegroundColor Green
    }
    
    # Actualizar PATH en la sesión actual
    $env:Path = "$env:Path;$flutterPath"
    
    # Ejecutar flutter doctor
    Write-Host "`n=== Ejecutando Flutter Doctor ===" -ForegroundColor Cyan
    & "C:\src\flutter\bin\flutter.bat" doctor
    
    Write-Host "`n=== Instalando dependencias del proyecto ===" -ForegroundColor Cyan
    & "C:\src\flutter\bin\flutter.bat" pub get
    
    Write-Host "`n✓ Configuración completada!" -ForegroundColor Green
    Write-Host "Puedes ejecutar 'flutter doctor' para verificar la instalación" -ForegroundColor Cyan
    
} else {
    Write-Host "✗ Flutter no encontrado en C:\src\flutter" -ForegroundColor Red
    Write-Host "Asegúrate de que la descarga se haya completado correctamente" -ForegroundColor Yellow
}
