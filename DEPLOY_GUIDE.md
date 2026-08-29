# Guía de Deploy - Dreams Club

Instrucciones para desplegar la aplicación Flutter y el panel de administración Next.js en producción.

## 📱 Deploy de la App Flutter

### Android (Google Play Store)

#### 1. Configurar Keystore

Crea un keystore para firmar la app:

```bash
keytool -genkey -v -keystore ~/dreams-club-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dreamsclub
```

#### 2. Configurar key.properties

Crea `android/key.properties`:

```properties
storePassword=tu-store-password
keyPassword=tu-key-password
keyAlias=dreamsclub
storeFile=C:/ruta/a/dreams-club-key.jks
```

#### 3. Actualizar android/app/build.gradle.kts

```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

#### 4. Build APK de Producción

```bash
# APK
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

El archivo estará en:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

#### 5. Subir a Google Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Crea una nueva aplicación
3. Completa la información requerida
4. Sube el archivo `.aab` en "Producción" → "Crear nueva versión"
5. Completa las notas de la versión
6. Envía para revisión

### iOS (App Store)

#### 1. Configurar en Xcode

```bash
open ios/Runner.xcworkspace
```

En Xcode:
1. Selecciona el proyecto "Runner"
2. Ve a "Signing & Capabilities"
3. Selecciona tu equipo de desarrollo
4. Habilita "Automatically manage signing"

#### 2. Build para iOS

```bash
flutter build ios --release
```

#### 3. Subir a App Store Connect

1. Abre Xcode
2. Product → Archive
3. Una vez completado, haz clic en "Distribute App"
4. Selecciona "App Store Connect"
5. Sigue el asistente para subir

### Configuración de Producción

#### Credenciales de Producción

En producción, configura tus variables de entorno o constantes de configuración de manera segura:

```dart
// lib/config/app_config.dart
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://tu-servidor-api.com',
  );
}
```

Build con variables:

```bash
flutter build apk --release \
  --dart-define=API_URL=https://tu-servidor-api.com
```

## 🌐 Deploy del Panel Admin (Next.js)

### Opción 1: Vercel (Recomendado)

#### 1. Preparar el proyecto

```bash
cd dreams-admin
npm run build  # Verificar que compila sin errores
```

#### 2. Deploy a Vercel

**Método A: CLI**

```bash
# Instalar Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

**Método B: GitHub**

1. Sube tu código a GitHub
2. Ve a [Vercel](https://vercel.com)
3. Click en "Import Project"
4. Selecciona tu repositorio
5. Configura las variables de entorno necesarias para la API (por ejemplo, `NEXT_PUBLIC_API_URL`).

#### 3. Configurar dominio personalizado (opcional)

1. En Vercel, ve a Settings → Domains
2. Agrega tu dominio personalizado
3. Configura los DNS según las instrucciones

### Opción 2: Netlify

```bash
# Instalar Netlify CLI
npm i -g netlify-cli

# Build
cd dreams-admin
npm run build

# Deploy
netlify deploy --prod
```

Configura las variables de entorno en Netlify Dashboard → Site Settings → Environment Variables.

### Opción 3: VPS (DigitalOcean, AWS, etc.)

#### 1. Preparar el servidor

```bash
# Conectar al servidor
ssh user@tu-servidor.com

# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar PM2 (gestor de procesos)
sudo npm install -g pm2
```

#### 2. Clonar y configurar el proyecto

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/DreamsClub.git
cd DreamsClub/dreams-admin

# Instalar dependencias
npm install

# Crear .env.local con tus credenciales
nano .env.local

# Build
npm run build
```

#### 3. Iniciar con PM2

```bash
# Iniciar la aplicación
pm2 start npm --name "dreams-admin" -- start

# Guardar configuración
pm2 save

# Configurar inicio automático
pm2 startup
```

#### 4. Configurar Nginx (opcional)

```nginx
# /etc/nginx/sites-available/dreams-admin
server {
    listen 80;
    server_name admin.dreamsclub.cl;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/dreams-admin /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Instalar SSL con Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d admin.dreamsclub.cl
```

## 🔐 Seguridad en Producción

### Checklist de Seguridad

- [ ] **HTTPS** habilitado en el panel admin y servidor API
- [ ] **Variables de entorno** configuradas correctamente
- [ ] **CORS** configurado de manera restrictiva en el servidor API
- [ ] **Rate Limiting** habilitado para evitar abuso en la API
- [ ] **Backups** automáticos de base de datos y media configurados
- [ ] **Logs** de errores activos y monitoreados
- [ ] **Monitoreo** de uso de CPU, memoria y almacenamiento de tu servidor VPS

### Errores en Flutter

Integra Firebase Crashlytics:

```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.0.0
  firebase_core: ^3.0.0
```

```dart
// main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const MyApp());
}
```

## 🚀 CI/CD Automatizado

### GitHub Actions para Flutter

Crea `.github/workflows/flutter-build.yml`:

```yaml
name: Flutter Build

on:
  push:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

### GitHub Actions para Next.js

Crea `.github/workflows/nextjs-deploy.yml`:

```yaml
name: Deploy Next.js

on:
  push:
    branches: [ main ]
    paths:
      - 'dreams-admin/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        working-directory: ./dreams-admin
        run: npm ci
      
      - name: Build
        working-directory: ./dreams-admin
        run: npm run build
          NEXT_PUBLIC_API_URL: ${{ secrets.API_URL }}
      
      # Deploy a Vercel automáticamente
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./dreams-admin
```

## 📝 Checklist Final de Deploy

### Flutter App
- [ ] Build de producción exitoso
- [ ] Backend/API configurado con credenciales de producción
- [ ] Keystore configurado y guardado de forma segura
- [ ] Permisos de Android/iOS revisados
- [ ] Testing en dispositivos reales
- [ ] Screenshots para stores preparadas
- [ ] Descripción de la app completada
- [ ] Política de privacidad publicada
- [ ] APK/IPA subido a las stores

### Next.js Admin
- [ ] Build de producción exitoso
- [ ] Variables de entorno configuradas
- [ ] Deploy en plataforma (Vercel/Netlify/VPS)
- [ ] Dominio configurado (si aplica)
- [ ] HTTPS habilitado
- [ ] Acceso restringido a administradores

### Backend y Base de Datos
- [ ] Esquema de base de datos migrado correctamente
- [ ] Permisos y políticas de seguridad configurados
- [ ] Storage buckets / proveedor de media creados y configurados
- [ ] Backups automáticos habilitados

---

**¡Listo para producción!** 🎉

Para soporte post-deploy, consulta los logs de tu servidor API autoalojado y las herramientas de monitoreo de tu plataforma de hosting.
