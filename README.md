# Dreams Club - App de Lealtad de Casino

Aplicación móvil Flutter para el programa de lealtad de Dreams Casino. Permite a los usuarios encontrar casinos cercanos, jugar mini-juegos, participar en eventos virales y gestionar su membresía digital.

## 🚀 Nueva Característica: Integración con Supabase + Admin Panel

El proyecto ahora incluye:
- ✅ **Backend Supabase** completo con 14 tablas y funciones SQL
- ✅ **Servicios API** en Flutter para conectar con Supabase
- ✅ **Panel de Administración Web** (Next.js) para gestionar contenido
- ✅ **Documentación completa** de setup, migración y deploy

📚 **[Ver Guía de Configuración Completa →](SUPABASE_SETUP.md)**

## 🎯 Características Principales

### 🎰 Dreams Manía: Lluvia de Millones
Evento viral en tiempo real que simula la emoción del piso del casino:
- **Alarma Visual**: Pantalla parpadeante en rojo y dorado con alerta de jackpot
- **Mini-Juego**: 15 segundos para atrapar fichas doradas cayendo ($1000 por ficha)
- **Tarjeta de Victoria**: Diseño premium "Insta-ready" para compartir en redes sociales
- **Trigger de Desarrollo**: Doble tap en esquina superior derecha para activar

### 🎲 Slot Machine
Tragamonedas con validación GPS:
- Disponible solo cuando estás dentro de un casino (radio de 500m)
- Validación GPS real (sin simulación)
- Logo "Dreams Casino" integrado
- Mecánica de 3 rodillos con animaciones fluidas

### 🧭 Navegación Inteligente
- **Botón Central Condicional**:
  - Dentro de casino: Abre Slot Machine
  - Fuera de casino: Muestra Tarjeta Digital QR
- Navegación simplificada: Solo "Inicio" y "Casinos"
- Theming dinámico basado en nivel de usuario (Negro, Oro, Platino, Azul)

### 📍 Geolocalización
- Detección automática del casino más cercano
- Monitoreo continuo de ubicación en tiempo real
- Selección manual de casino favorito
- Radio de detección: 500 metros

### 🎫 Tarjeta Digital
- Código QR para validación en casino
- Diseño premium con colores de nivel de usuario
- Acceso rápido desde botón central

## 🏗️ Arquitectura y Tecnologías

### Stack Principal
- **Framework**: Flutter (>=3.4.0 <4.0.0)
- **Lenguaje**: Dart
- **Gestión de Estado**: [Riverpod](https://riverpod.dev/)
- **Navegación**: [go_router](https://pub.dev/packages/go_router)

### Dependencias Clave
- **Red**: [Dio](https://pub.dev/packages/dio)
- **Geolocalización**: [geolocator](https://pub.dev/packages/geolocator)
- **Mapas**: [map_launcher](https://pub.dev/packages/map_launcher)
- **Almacenamiento**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Notificaciones**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications), [workmanager](https://pub.dev/packages/workmanager)
- **Permisos**: [permission_handler](https://pub.dev/packages/permission_handler)
- **UI/Animaciones**: [lottie](https://pub.dev/packages/lottie), [google_fonts](https://pub.dev/packages/google_fonts)

## 📁 Estructura del Proyecto

```
lib/
├── models/              # Modelos de datos
├── services/            # Lógica de negocio
│   ├── dreams_mania_service.dart
│   ├── location_service.dart
│   └── casino_service.dart
├── providers/           # State management (Riverpod)
│   ├── user_provider.dart
│   └── location_provider.dart
├── screens/             # Pantallas principales
│   ├── home_screen.dart
│   ├── slot_machine_screen.dart
│   └── casinos_screen.dart
├── widgets/             # Componentes reutilizables
│   ├── dreams_mania/
│   │   ├── dreams_mania_overlay.dart
│   │   ├── falling_chip_widget.dart
│   │   └── victory_card_dialog.dart
│   ├── scaffold_with_nav_bar.dart
│   └── loyalty_card_widget.dart
├── navigation/          # Configuración de rutas
└── theme/              # Estilos y temas
```

## 🚀 Configuración y Ejecución

### Prerrequisitos
- Flutter SDK (>=3.4.0 <4.0.0)
- Dart SDK
- Android Studio / Xcode (para emuladores)

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd DreamsClub
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

### Análisis de Código
```bash
flutter analyze
```

### Build de Producción
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🎮 Guía de Uso

### Activar Dreams Manía (Modo Desarrollo)
1. Abre la app
2. Haz **doble tap** en la esquina superior derecha (área invisible)
3. Aparecerá la alarma de jackpot
4. Espera 3 segundos para que comience el juego
5. Toca las fichas doradas que caen
6. Al finalizar, verás tu tarjeta de victoria

### Jugar Slot Machine
1. Acércate a un casino Dreams (o simula ubicación GPS)
2. El botón central cambiará a icono de casino
3. Toca el botón para abrir el Slot Machine
4. Otorga permisos de ubicación si se solicitan
5. Presiona "JUGAR" para girar los rodillos

### Ver Tarjeta Digital
1. Aléjate de cualquier casino
2. El botón central mostrará icono QR
3. Toca el botón para ver tu tarjeta de socio

## 🗄️ Backend y Administración

### Supabase Backend
- **14 tablas** con relaciones completas
- **Funciones SQL** para lógica de negocio
- **Row Level Security** para protección de datos
- **Realtime** para actualizaciones en vivo

### Panel de Administración (Next.js)
- **Dashboard visual** con navegación intuitiva
- **CRUD completo** para eventos, promociones, restaurantes, etc.
- **UI moderna** con Tailwind CSS y dark mode
- **TypeScript** para type safety

📚 **Documentación:**
- [Setup de Supabase](SUPABASE_SETUP.md) - Configuración completa
- [Guía de Migración](MIGRATION_GUIDE.md) - Migrar de datos locales a Supabase
- [Guía de Deploy](DEPLOY_GUIDE.md) - Deploy a producción
- [Referencia de Comandos](COMMANDS_REFERENCE.md) - Comandos útiles
- [Resumen de Integración](INTEGRATION_SUMMARY.md) - Overview completo

## 🎨 Niveles de Usuario

La app adapta su diseño según el nivel del usuario:
- **Negro**: Color base
- **Oro**: Dorado premium (#D4AF37)
- **Platino**: Plateado elegante
- **Azul**: Azul distintivo

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Panel Web Admin (Next.js)

## 🔐 Permisos Requeridos

- **Ubicación**: Para detección de casinos cercanos y validación GPS
- **Notificaciones**: Para alertas de eventos y promociones

## 🚀 Quick Start

### Flutter App
```bash
# Instalar dependencias
flutter pub get

# Ejecutar app
flutter run
```

### Admin Panel
```bash
# Navegar al directorio
cd dreams-admin

# Instalar dependencias
npm install

# Configurar credenciales
cp .env.local.example .env.local
# Editar .env.local con tus credenciales de Supabase

# Iniciar servidor
npm run dev
```

## 📄 Licencia

[Especificar licencia]

## 👥 Contribuidores

[Especificar equipo de desarrollo]

---

**Versión Actual**: 1.0.0  
**Última Actualización**: Noviembre 2025
