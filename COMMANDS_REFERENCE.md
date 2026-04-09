# 🎮 Dreams Club - Comandos Rápidos

Referencia rápida de comandos para desarrollo, testing y deploy.

## 📱 Flutter App

### Instalación y Setup

```bash
# Instalar dependencias
flutter pub get

# Verificar configuración
flutter doctor

# Limpiar build (si hay problemas)
flutter clean
flutter pub get
```

### Desarrollo

```bash
# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter devices
flutter run -d <device-id>

# Hot reload
# Presiona 'r' en la terminal mientras corre

# Hot restart
# Presiona 'R' en la terminal
```

### Testing

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar test específico
flutter test test/widget_test.dart

# Análisis de código
flutter analyze

# Formatear código
flutter format lib/
```

### Build

```bash
# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build App Bundle (para Play Store)
flutter build appbundle --release

# Build iOS (requiere Mac)
flutter build ios --release

# Build con variables de entorno
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-anon-key
```

### Supabase en Flutter

```bash
# Instalar Supabase
flutter pub add supabase_flutter

# Actualizar dependencia
flutter pub upgrade supabase_flutter

# Ver versión instalada
flutter pub deps | grep supabase
```

## 🌐 Next.js Admin Panel

### Instalación

```bash
# Navegar al directorio
cd dreams-admin

# Instalar dependencias
npm install

# o con yarn
yarn install
```

### Desarrollo

```bash
# Iniciar servidor de desarrollo
npm run dev

# Abrir en navegador
# http://localhost:3000

# Limpiar cache de Next.js
rm -rf .next
npm run dev
```

### Build y Deploy

```bash
# Build para producción
npm run build

# Iniciar en modo producción
npm run start

# Verificar errores
npm run lint

# Deploy a Vercel
npm i -g vercel
vercel login
vercel --prod

# Deploy a Netlify
npm i -g netlify-cli
netlify login
netlify deploy --prod
```

### Variables de Entorno

```bash
# Crear archivo de configuración
cp .env.local.example .env.local

# Editar variables
notepad .env.local

# Variables requeridas:
# NEXT_PUBLIC_SUPABASE_URL=...
# NEXT_PUBLIC_SUPABASE_ANON_KEY=...
# SUPABASE_SERVICE_ROLE_KEY=...
```

## 🗄️ Supabase

### SQL

```sql
-- Ejecutar schema completo
-- (Copiar contenido de supabase/schema.sql al SQL Editor)

-- Ver todas las tablas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Contar registros en una tabla
SELECT COUNT(*) FROM events;

-- Ver políticas RLS
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Habilitar RLS en una tabla
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Crear política básica
CREATE POLICY "Anyone can view" 
ON public.events 
FOR SELECT 
USING (true);
```

### CLI de Supabase

```bash
# Instalar Supabase CLI
npm install -g supabase

# Login
supabase login

# Inicializar proyecto local
supabase init

# Iniciar Supabase local
supabase start

# Detener Supabase local
supabase stop

# Ver status
supabase status

# Crear migración
supabase migration new nombre_migracion

# Aplicar migraciones
supabase db push

# Deploy función edge
supabase functions deploy nombre-funcion
```

## 🔧 Git

### Comandos Básicos

```bash
# Inicializar repositorio (si no existe)
git init

# Ver estado
git status

# Agregar archivos
git add .
git add archivo.dart

# Commit
git commit -m "Descripción del cambio"

# Push
git push origin main

# Pull
git pull origin main

# Ver historial
git log --oneline
```

### Branches

```bash
# Crear nueva rama
git checkout -b feature/nueva-funcionalidad

# Cambiar de rama
git checkout main

# Listar ramas
git branch

# Merge
git checkout main
git merge feature/nueva-funcionalidad

# Eliminar rama
git branch -d feature/nueva-funcionalidad
```

## 🐛 Debugging

### Flutter

```bash
# Ver logs detallados
flutter run -v

# Ver logs de dispositivo Android
adb logcat

# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run

# Verificar configuración de Android
cd android
./gradlew signingReport

# Ver tamaño del APK
flutter build apk --analyze-size
```

### Next.js

```bash
# Ver logs detallados
npm run dev -- --debug

# Limpiar cache
rm -rf .next
rm -rf node_modules
npm install

# Verificar build
npm run build

# Analizar bundle size
npm run build -- --analyze
```

## 📦 Gestión de Dependencias

### Flutter

```bash
# Agregar dependencia
flutter pub add nombre_paquete

# Agregar dev dependency
flutter pub add --dev nombre_paquete

# Actualizar dependencias
flutter pub upgrade

# Actualizar dependencia específica
flutter pub upgrade nombre_paquete

# Ver dependencias desactualizadas
flutter pub outdated

# Listar todas las dependencias
flutter pub deps
```

### Next.js

```bash
# Agregar dependencia
npm install nombre-paquete

# Agregar dev dependency
npm install --save-dev nombre-paquete

# Actualizar dependencias
npm update

# Actualizar dependencia específica
npm update nombre-paquete

# Ver dependencias desactualizadas
npm outdated

# Auditar seguridad
npm audit
npm audit fix
```

## 🔍 Búsqueda y Análisis

### Buscar en Código

```bash
# Buscar texto en Flutter
grep -r "texto a buscar" lib/

# Buscar texto en Next.js
grep -r "texto a buscar" app/

# PowerShell (Windows)
Select-String -Path "lib\**\*.dart" -Pattern "texto"
```

### Análisis de Código

```bash
# Flutter: Contar líneas de código
find lib -name "*.dart" | xargs wc -l

# Next.js: Contar líneas de código
find app -name "*.tsx" -o -name "*.ts" | xargs wc -l

# Ver tamaño de directorios
du -sh lib/
du -sh dreams-admin/
```

## 🚀 Deploy Rápido

### Flutter a Google Play

```bash
# 1. Incrementar versión en pubspec.yaml
# version: 1.0.0+1 -> 1.0.1+2

# 2. Build App Bundle
flutter build appbundle --release

# 3. El archivo estará en:
# build/app/outputs/bundle/release/app-release.aab

# 4. Subir a Google Play Console
```

### Next.js a Vercel (más rápido)

```bash
cd dreams-admin

# Primera vez
vercel

# Siguientes deploys
vercel --prod
```

## 🔐 Seguridad

### Verificar Secrets

```bash
# No commitear estos archivos:
# .env.local
# android/key.properties
# *.jks
# lib/config/supabase_config.dart (si tiene credenciales)

# Verificar qué se va a commitear
git status
git diff

# Remover archivo del staging
git reset HEAD archivo.txt

# Agregar a .gitignore
echo ".env.local" >> .gitignore
```

## 📊 Monitoreo

### Supabase

```bash
# Ver logs en tiempo real (Dashboard)
# Supabase Dashboard -> Logs

# Ejecutar query para estadísticas
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN level = 'gold' THEN 1 END) as gold_users,
  AVG(points) as avg_points
FROM users;
```

### Performance

```bash
# Flutter: Perfil de performance
flutter run --profile

# Next.js: Analizar bundle
npm run build
npm run analyze
```

## 🆘 Solución de Problemas Comunes

```bash
# Error: Gradle sync failed (Android)
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get

# Error: Pod install failed (iOS)
cd ios
pod deintegrate
pod install
cd ..

# Error: Next.js build failed
rm -rf .next node_modules
npm install
npm run build

# Error: Supabase connection
# Verificar credenciales en .env.local
# Verificar que Supabase está online
```

---

## 📚 Recursos Adicionales

- [Flutter Docs](https://docs.flutter.dev/)
- [Next.js Docs](https://nextjs.org/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Git Cheatsheet](https://education.github.com/git-cheat-sheet-education.pdf)

---

💡 **Tip:** Guarda este archivo en favoritos para acceso rápido a comandos durante el desarrollo.
