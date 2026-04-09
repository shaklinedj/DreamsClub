# Dreams Casino - App de Fidelización

Sistema de fidelización para los casinos Dreams, construido con Flutter para la aplicación móvil y Supabase como backend.

## 🎰 Descripción

Esta aplicación permite a los clientes de los casinos Dreams:
- **Detectar el casino más cercano** usando la ubicación del dispositivo.
- **Ver eventos**, promociones y carteleras de cada casino.
- **Marcar casinos como favoritos**.
- **Navegar** entre los diferentes casinos de la cadena.

## 🛠️ Tecnologías Utilizadas

### App Móvil
- **Flutter**: Framework de UI para crear aplicaciones compiladas de forma nativa para móvil, web y escritorio desde una única base de código.
- **Riverpod**: Para la gestión de estado.
- **GoRouter**: Para la navegación.

### Backend
- **Supabase**: Plataforma de backend como servicio (BaaS) que proporciona:
    - **PostgreSQL Database**: Para almacenar todos los datos.
    - **Authentication**: Gestión de usuarios y seguridad a nivel de fila (RLS).
    - **Storage**: Para almacenar archivos como imágenes de promociones y casinos.
    - **APIs automáticas**: APIs RESTful generadas automáticamente.

## 📂 Estructura del Proyecto

```
fidelizacion/
├── casinoloyalty_flutter/ # Aplicación móvil hecha en Flutter
│   ├── lib/
│   │   ├── main.dart      # Punto de entrada de la app
│   │   ├── models/        # Modelos de datos (Casino, Evento, etc.)
│   │   ├── screens/       # Pantallas de la aplicación
│   │   ├── services/      # Lógica de negocio y comunicación con API
│   │   └── providers/     # Proveedores de estado (Riverpod)
│   ├── pubspec.yaml       # Dependencias y configuración del proyecto
│   └── ...
│
├── admin_panel/           # Panel de administración (React)
│
├── TUTORIAL_SUPABASE.md   # Guía paso a paso para configurar Supabase
│
└── README.md              # Este archivo
```

## 🚀 Instalación y Configuración

### 1. Backend (Supabase)

Antes de ejecutar la aplicación, necesitas configurar tu backend en Supabase.

1.  **Crea un proyecto** en [supabase.com](https://supabase.com/).
2.  Sigue las instrucciones detalladas en el archivo **[TUTORIAL_SUPABASE.md](TUTORIAL_SUPABASE.md)** para:
    *   Crear las tablas necesarias (`casinos`, `events`, etc.).
    *   Configurar las políticas de seguridad (Row Level Security).
    *   Obtener tu **URL de proyecto** y tu clave **anon key**.

### 2. App Móvil (Flutter)

1.  **Requisitos Previos**: Asegúrate de tener el [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.

2.  **Navega al directorio de la app**:
    ```bash
    cd casinoloyalty_flutter
    ```

3.  **Instala las dependencias**:
    ```bash
    flutter pub get
    ```

4.  **Configura las credenciales de Supabase**:
    Una vez que tengas tu URL y tu clave `anon` de Supabase, deberás configurarlas en la aplicación. El lugar recomendado para hacerlo será en el archivo `lib/main.dart` por ahora.

    *(Te ayudaré a hacer esto en el siguiente paso, una vez que me proporciones las credenciales.)*

5.  **Ejecuta la aplicación**:
    ```bash
    flutter run
    ```

## 🔄 Próximas Mejoras

- [ ] Notificaciones push cuando el usuario está cerca de un casino.
- [ ] Sistema de puntos de fidelidad.
- [ ] Perfil de usuario.
- [ ] Historial de visitas.
- [ ] Reservas de eventos.
- [ ] Integración con redes sociales.
- [ ] Vista de mapa con todos los casinos.
- [ ] Chat de soporte.

## 📄 Licencia

Este proyecto es para fines de demostración y desarrollo.

## 👥 Soporte

Para soporte técnico, contactar a: admin@casinoloyalty.cl
