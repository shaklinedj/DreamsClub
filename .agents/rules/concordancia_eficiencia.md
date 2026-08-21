# Regla de Concordancia, Eficiencia de Datos y Sincronización Web-Móvil

## 1. Concordancia Total entre Dashboard Web Astro y App Flutter
- Todo cambio o nueva característica implementada en la App Móvil (ej. videos de YouTube, avatar `profile_image_url`, días de racha) DEBE funcionar e interpretarse exactamente de la misma manera en el Dashboard Administrador Web (`dreams-admin`).
- Cada vez que se realicen cambios en el Dashboard Astro (`dreams-admin`), se DEBE ejecutar la build (`pnpm run build`) y desplegar a Firebase Hosting (`firebase deploy --only hosting`) para que el usuario vea los cambios en vivo en `https://dreams-casino-app.web.app`.

## 2. Consumo Mínimo de Datos
- Optimizar todas las imágenes y recursos al transferirlos o almacenarlos.
- Evitar duplicaciones de campos en Firestore (ej. usar únicamente `profile_image_url` en lugar de `photoURL` y `profile_image_url`).
- Usar reproductores nativos y embebidos (`<iframe>` con `/embed/ID`) para videos de YouTube en la web y reproductores nativos optimizados en la app móvil.

## 3. Actualización de Especificaciones
- Mantener siempre actualizado `ESPECIFICACION_SISTEMA_DREAMSCLUB.md` tras cada hito técnico cumplido.
