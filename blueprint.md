# Blueprint de la Aplicación Casino Loyalty

## Descripción General

Esta aplicación permite a los usuarios de la cadena de casinos "Dreams" ver información sobre los diferentes casinos, sus promociones y eventos. También permite a los usuarios seleccionar un casino favorito para tener un acceso rápido a su información.

## Estilo, Diseño y Características

*   **Arquitectura:** Flutter con Riverpod para la gestión de estado.
*   **Navegación:** `go_router` para una navegación robusta y basada en rutas.
*   **Diseño:** Interfaz limpia y moderna, con un tema oscuro y tarjetas de casino visualmente atractivas que incluyen imágenes y gradientes.
*   **Funcionalidades:**
    *   **Detección de casino cercano:** (Funcionalidad futura)
    *   **Selección de casino favorito:** Permite a los usuarios elegir un casino principal.
    *   **Listado de casinos:** Muestra todos los casinos disponibles con imágenes y nombres en tarjetas interactivas.
    *   **Detalles del casino:** Pantalla de detalles para cada casino.
    *   **Promociones y Eventos:** Secciones dedicadas a mostrar promociones y eventos para el casino seleccionado, con mensajes claros cuando no hay datos disponibles.

## Mejoras Recientes (Sesión Actual)

*   **Corrección de Navegación:**
    *   Se anidó la ruta de detalles del casino (`/casinos/:id`) dentro de la ruta de la lista (`/all-casinos`) para crear una jerarquía de navegación lógica.
    *   Se cambió el método `context.go()` por `context.push()` en las tarjetas de casino para apilar la pantalla de detalles sobre la lista, preservando el historial de navegación y permitiendo al usuario volver atrás.
*   **Solución de Visualización de Imágenes:**
    *   Se unificaron los modelos de datos `Casino` en un solo archivo (`lib/models/casino_model.dart`), eliminando el conflicto y la duplicidad.
    *   Se añadió el campo `imageUrl` al modelo unificado.
    *   Se actualizaron los datos de ejemplo en `casino_service.dart` para incluir las rutas de las imágenes locales desde la carpeta `assets/images/`.
    *   Se corrigió el widget `CasinoCard` para cargar las imágenes usando `AssetImage` en lugar de `NetworkImage`.
*   **Mejora de la Experiencia de Usuario (UX):**
    *   Se implementó una lógica en las pantallas de `EventsScreen` y `PromotionsScreen` para mostrar un mensaje centrado ("No hay eventos/promociones disponibles para este casino.") cuando la lista de datos está vacía. Esto evita pantallas en blanco y mejora la comunicación con el usuario.
*   **Inclusión de Imágenes en Eventos y Promociones:**
    *   Se añadieron imágenes a las secciones de eventos y promociones para mejorar la presentación visual.
    *   Se modificaron los modelos de datos `Event` y `Promotion` para incluir un campo `imageUrl`.
    *   Se actualizaron los servicios de datos `EventService` y `PromotionService` para proporcionar URLs de imágenes de marcador de posición (`picsum.photos`).
    *   Se modificaron las pantallas `events_screen.dart`, `promotions_screen.dart`, y `casino_detail_screen.dart` para mostrar las imágenes junto con el título y la descripción.
