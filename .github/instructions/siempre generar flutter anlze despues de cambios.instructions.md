---
applyTo: '**'
---

# DreamsClub - Instrucciones de Desarrollo

App Flutter de fidelización para casinos Dreams. Promociones, eventos, casinos cercanos y perfil de socio.

## Reglas Críticas

### 1. SIEMPRE ejecutar `flutter analyze` después de cambios. Corregir todos los warnings/errores.

### 2. Stack Tecnológico
- **Estado**: Riverpod (`/lib/providers/`)
- **Navegación**: GoRouter (`/lib/navigation/app_router.dart`)
  - Usar `context.go()` / `context.push()`
  - Verificar `if (!mounted) return;` después de async antes de usar `context`
- **Ubicación**: `LocationService` con permisos
- **Mapas**: `map_launcher` con `showDirections()` (no `showMarker`)
- **Notificaciones**: `BackgroundDistanceService` (60km threshold)

### 3. Buenas Prácticas
- `const` constructors donde sea posible
- `developer.log()` en lugar de `print()`
- `errorBuilder` en imágenes de red
- `Theme.of(context).colorScheme` (color primario: #D4AF37)
- Formato moneda: `NumberFormat.currency(locale: 'es_CL', symbol: 'CLP\$')`

### 4. Estructura
```
lib/
├── models/      # Casino, User, Promotion
├── providers/   # Riverpod providers
├── screens/     # Pantallas
├── services/    # API, ubicación, mapas
├── widgets/     # Reutilizables
├── theme/       # Tema
└── navigation/  # Rutas
```

### 5. Checklist
- ✅ `flutter analyze` sin errores
- ✅ Verificar `mounted` en async
- ✅ Manejar permisos apropiadamente
- ✅ No romper funcionalidad existente