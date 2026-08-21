# Regla de Calidad y Experiencia en Flutter

Como experto en las últimas prácticas y estándares de Flutter / Dart:

1. **Revisión Rigurosa Post-Modificación:**
   - Cada vez que se modifique o cree código Dart/Flutter, se debe verificar que esté 100% normalizado, con tipos explícitos, nulos controlados y sin dependencias rotas.
   - Atender y resolver de inmediato cualquier error, advertencia o problema reportado por el IDE o `dart analyze`.

2. **Cero Errores y Calidad de Código:**
   - Mantener firmas de métodos completas (ej. parámetros nombrados y opcionales como `isRefresh`, `casinoId`).
   - Evitar colisiones de nombres usando prefijos de importación (ej. `import 'package:firebase_auth/firebase_auth.dart' as fb_auth;`).
   - Respetar patrones de arquitectura limpia, separación de responsabilidades y reactividad con Riverpod.

3. **Separación de Roles (Móvil vs Dashboard Web):**
   - La aplicación móvil **DreamsClub** es 100% de cara al usuario final (consumo del feed, reacciones, comentarios, cartelera, stickers, ruleta y beneficios).
   - **NUNCA** se crean publicaciones desde el móvil. La creación y administración de contenido se realiza exclusivamente desde el Dashboard Web (`dreams-admin`).
