# Casino Loyalty App - Versión Flutter

Este proyecto es una migración de la aplicación original de React Native a Flutter. La aplicación permite a los usuarios encontrar el casino Dreams más cercano, ver promociones y eventos, y seleccionar un casino favorito.

## Arquitectura y Tecnologías

La aplicación está construida con Flutter y utiliza las siguientes tecnologías clave:

- **Gestión de Estado:** [Riverpod](https://riverpod.dev/)
- **Navegación:** [go_router](https://pub.dev/packages/go_router)
- **Red:** [Dio](https://pub.dev/packages/dio)
- **Geolocalización:** [geolocator](https://pub.dev/packages/geolocator)
- **Mapas:** [map_launcher](https://pub.dev/packages/map_launcher)
- **Almacenamiento Local:** [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Notificaciones:** [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) y [workmanager](https://pub.dev/packages/workmanager)
- **Permisos:** [permission_handler](https://pub.dev/packages/permission_handler)
- **UI/Animaciones:** [flutter_animated_icons](https://pub.dev/packages/flutter_animated_icons), [lottie](https://pub.dev/packages/lottie), [circle_nav_bar](https://pub.dev/packages/circle_nav_bar), [google_fonts](https://pub.dev/packages/google_fonts)

## Estructura del Proyecto

- `lib/`: Código fuente Dart.
  - `models/`: Modelos de datos.
  - `services/`: Lógica de negocio y llamadas a API.
  - `providers/`: State management con Riverpod.
  - `screens/`: Pantallas de la UI.
  - `widgets/`: Componentes reutilizables.
  - `navigation/`: Configuración de rutas.
  - `theme/`: Estilos y temas.
- `assets/`: Imágenes y recursos estáticos.

## Configuración y Ejecución

### Prerrequisitos

- Flutter SDK (versión >=3.4.0 <4.0.0)
- Dart SDK

### Pasos para ejecutar

1. **Clonar el repositorio:**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

## Funcionalidades Principales

- **Ubicación Inteligente:** Detecta automáticamente el casino más cercano.
- **Selección Manual:** Permite elegir un casino favorito si no se usa la ubicación.
- **Contenido Dinámico:** Muestra promociones y eventos específicos del casino seleccionado.
- **Notificaciones:** Sistema de notificaciones locales y tareas en segundo plano.
