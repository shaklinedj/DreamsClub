# Casino Loyalty App - Versión Flutter

Este proyecto es una migración de la aplicación original de React Native a Flutter. La aplicación permite a los usuarios encontrar el casino Dreams más cercano, ver promociones y eventos, y seleccionar un casino favorito.

## Arquitectura

La aplicación está construida con Flutter y utiliza [Riverpod](https://riverpod.dev/) para la gestión del estado. La navegación se gestiona con [go_router](https://pub.dev/packages/go_router).

La estructura del proyecto es la siguiente:

- `lib/`: Contiene todo el código Dart de la aplicación.
  - `models/`: Define los modelos de datos (Casino, Promoción, Evento).
  - `services/`: Contiene los servicios para obtener datos (API, ubicación, etc.).
  - `providers/`: Contiene los providers de Riverpod que exponen los datos a la UI.
  - `screens/`: Contiene las diferentes pantallas de la aplicación.
  - `widgets/`: Contiene los widgets reutilizables.
  - `navigation/`: Contiene la configuración de la navegación con go_router.
  - `theme/`: Contiene la configuración del tema de la aplicación.
- `assets/`: Contiene los assets estáticos, como imágenes y logos.

## Cómo ejecutar la aplicación

1. **Clonar el repositorio:**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   ```
2. **Instalar las dependencias:**
   ```bash
   cd casinoloyalty_flutter
   flutter pub get
   ```
3. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

## Funcionalidades

- **Casino más cercano:** Al iniciar la aplicación, se solicita la ubicación del usuario para mostrar el casino más cercano.
- **Casino favorito:** Si el usuario no concede los permisos de ubicación, se le permite seleccionar un casino favorito de una lista.
- **Promociones y eventos:** Las pantallas de promociones y eventos muestran la información correspondiente al casino principal (el más cercano o el favorito).
- **Tema personalizado:** La aplicación utiliza un tema personalizado basado en la identidad de marca de Dreams.

## Firebase (opcional)

Este proyecto incluye la inicialización de Firebase (firebase_core). Para conectarlo con tu proyecto:

1. Instala el CLI de FlutterFire y configura el proyecto:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<tu-proyecto> --platforms=android,ios,web
   ```
2. Revisa que se haya generado `lib/firebase_options.dart` (reemplazará el placeholder existente).
3. Android: coloca `android/app/google-services.json` y, si usas Gradle Groovy/KTS, aplica el plugin de Google Services.
4. iOS: coloca `ios/Runner/GoogleService-Info.plist` y añade el archivo al target en Xcode.
5. Web: verifica que `web/index.html` tenga las etiquetas de Firebase si el CLI las añadió.

Luego instala dependencias y ejecuta:
```bash
flutter pub get
flutter run
```
