# Guía de Migración: De Datos Locales a Supabase

Esta guía muestra cómo actualizar tus providers de Riverpod para usar los servicios API de Supabase en lugar de datos hardcodeados.

## 📋 Estrategia de Migración

### Opción 1: Migración Progresiva (Recomendada)
- Mantén los servicios locales como fallback
- Usa una variable de configuración para activar/desactivar Supabase
- Permite desarrollo sin conexión a internet

### Opción 2: Migración Completa
- Reemplaza completamente los datos locales por llamadas a Supabase
- Requiere conexión a internet siempre
- Más simple, menos código

## 🔄 Ejemplos de Migración

### 1. Events Provider

#### Antes (datos locales):
```dart
// lib/providers/event_providers.dart
final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) async {
  return EventService.getEventsByCasino(casinoId);
});
```

#### Después (con Supabase + fallback):
```dart
// lib/providers/event_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/api/event_api_service.dart';
import '../services/event_service.dart';
import '../services/supabase_service.dart';

final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) async {
  // Si Supabase está inicializado, usar API
  if (SupabaseService.isInitialized) {
    try {
      return await EventApiService.getEventsByCasino(casinoId);
    } catch (e) {
      print('Error al obtener eventos de Supabase: $e');
      // Fallback a datos locales si falla
      return EventService.getEventsByCasino(casinoId);
    }
  }
  
  // Fallback a datos locales si Supabase no está inicializado
  return EventService.getEventsByCasino(casinoId);
});

final eventDetailProvider = FutureProvider.family<Event, int>((ref, eventId) async {
  if (SupabaseService.isInitialized) {
    try {
      final event = await EventApiService.getEventById(eventId);
      if (event != null) return event;
    } catch (e) {
      print('Error al obtener evento de Supabase: $e');
    }
  }
  
  return EventService.getEventById(eventId);
});
```

### 2. Casinos Provider

#### Antes:
```dart
// lib/providers/casino_providers.dart
final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return CasinoService.getCasinos();
});
```

#### Después:
```dart
// lib/providers/casino_providers.dart
import '../services/api/casino_api_service.dart';

final casinosProvider = FutureProvider<List<Casino>>((ref) async {
  if (SupabaseService.isInitialized) {
    try {
      return await CasinoApiService.getCasinos();
    } catch (e) {
      print('Error al obtener casinos: $e');
      return CasinoService.getCasinos(); // Fallback
    }
  }
  
  return CasinoService.getCasinos();
});
```

### 3. User Provider (con persistencia)

#### Actualizar para usar Supabase:
```dart
// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api/user_api_service.dart';
import '../services/user_profile_service.dart';
import '../services/supabase_service.dart';

class UserNotifier extends StateNotifier<User> {
  final UserProfileService _storage;

  UserNotifier(this._storage) : super(_defaultUser) {
    _loadUserProfile();
  }

  static const _defaultUser = User(
    name: 'Usuario Demo',
    email: 'demo@dreamsclub.cl',
    profileImageUrl: 'https://picsum.photos/200',
    level: UserLevel.blue,
    points: 0,
    balance: 0.0,
  );

  Future<void> _loadUserProfile() async {
    // Primero intentar cargar de Supabase (si el usuario está autenticado)
    if (SupabaseService.isInitialized && SupabaseService.currentUser != null) {
      try {
        final userProfile = await UserApiService.getCurrentUserProfile();
        if (userProfile != null) {
          state = userProfile;
          return;
        }
      } catch (e) {
        print('Error al cargar perfil de Supabase: $e');
      }
    }

    // Fallback a SharedPreferences
    final savedUser = await _storage.loadUserProfile();
    if (savedUser != null) {
      state = savedUser;
    }
  }

  Future<void> addPoints(int points) async {
    final newPoints = state.points + points;
    state = state.copyWith(points: newPoints);

    // Guardar en Supabase si está disponible
    if (SupabaseService.isInitialized && SupabaseService.currentUser != null) {
      try {
        await UserApiService.addPoints(points, 'Puntos ganados en la app');
      } catch (e) {
        print('Error al guardar puntos en Supabase: $e');
      }
    }

    // Siempre guardar localmente también (para sincronización)
    await _storage.savePoints(newPoints);
  }

  Future<void> updateProfile(User newUser) async {
    state = newUser;

    // Guardar en Supabase
    if (SupabaseService.isInitialized && SupabaseService.currentUser != null) {
      try {
        await UserApiService.upsertUserProfile(newUser);
      } catch (e) {
        print('Error al guardar perfil en Supabase: $e');
      }
    }

    // Guardar localmente
    await _storage.saveUserProfile(newUser);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier(UserProfileService());
});
```

### 4. Comments Provider (nuevo, con Supabase)

```dart
// lib/providers/comment_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../services/api/comment_api_service.dart';
import '../services/comment_service.dart';
import '../services/supabase_service.dart';

// Provider para comentarios de un evento
final eventCommentsProvider = FutureProvider.family<List<Comment>, int>((ref, eventId) async {
  if (SupabaseService.isInitialized) {
    try {
      return await CommentApiService.getCommentsByEvent(eventId);
    } catch (e) {
      print('Error al obtener comentarios: $e');
      return CommentService.getCommentsByEvent(eventId); // Fallback
    }
  }
  
  return CommentService.getCommentsByEvent(eventId);
});

// Provider para contador de comentarios
final eventCommentsCountProvider = FutureProvider.family<int, int>((ref, eventId) async {
  if (SupabaseService.isInitialized) {
    try {
      return await CommentApiService.getEventCommentsCount(eventId);
    } catch (e) {
      print('Error al obtener contador de comentarios: $e');
      return 0;
    }
  }
  
  return 0;
});

// StateNotifier para crear comentarios
class CommentsNotifier extends StateNotifier<AsyncValue<void>> {
  CommentsNotifier() : super(const AsyncValue.data(null));

  Future<void> createComment({
    required String userId,
    required String content,
    int? eventId,
    int? promotionId,
  }) async {
    state = const AsyncValue.loading();

    try {
      if (SupabaseService.isInitialized) {
        await CommentApiService.createComment(
          userId: userId,
          content: content,
          eventId: eventId,
          promotionId: promotionId,
        );
      } else {
        // Fallback: guardar localmente (SharedPreferences o similar)
        await CommentService.createCommentLocally(
          userId: userId,
          content: content,
          eventId: eventId,
          promotionId: promotionId,
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final commentsNotifierProvider = StateNotifierProvider<CommentsNotifier, AsyncValue<void>>((ref) {
  return CommentsNotifier();
});
```

## 🔄 Sincronización Offline

Para aplicaciones que funcionan offline, implementa una cola de sincronización:

```dart
// lib/services/sync_service.dart
class SyncService {
  static final List<Map<String, dynamic>> _pendingActions = [];

  // Agregar acción a la cola
  static void queueAction(String type, Map<String, dynamic> data) {
    _pendingActions.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Sincronizar cuando haya conexión
  static Future<void> syncPendingActions() async {
    if (!SupabaseService.isInitialized) return;

    for (var action in _pendingActions) {
      try {
        switch (action['type']) {
          case 'create_comment':
            await CommentApiService.createComment(
              userId: action['data']['userId'],
              content: action['data']['content'],
              eventId: action['data']['eventId'],
            );
            break;
          case 'add_points':
            await UserApiService.addPoints(
              action['data']['points'],
              action['data']['reason'],
            );
            break;
          // ... más casos
        }
      } catch (e) {
        print('Error sincronizando acción: $e');
        continue; // Mantener en la cola para reintentar
      }
    }

    _pendingActions.clear();
  }
}
```

## 🧪 Testing con Mock

Para testing sin conexión real a Supabase:

```dart
// test/mocks/mock_supabase_service.dart
class MockSupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    _initialized = true;
  }

  static void reset() {
    _initialized = false;
  }
}
```

## 📊 Configuración Global

Crea un archivo de configuración para controlar el uso de Supabase:

```dart
// lib/config/app_config.dart
class AppConfig {
  // En desarrollo, puedes desactivar Supabase
  static const bool useSupabase = true;
  
  // En producción, siempre usar Supabase
  static const bool requireSupabase = false;
  
  static bool get shouldUseSupabase {
    return useSupabase && SupabaseService.isInitialized;
  }
}
```

Luego en tus providers:

```dart
if (AppConfig.shouldUseSupabase) {
  return await EventApiService.getEvents();
} else {
  return EventService.getEventsLocal();
}
```

## 🚀 Orden de Migración Recomendado

1. **Casinos** - Datos maestros, rara vez cambian
2. **Events y Promotions** - Contenido dinámico
3. **Users** - Perfiles de usuario
4. **Comments** - Interacciones de usuarios
5. **Achievements y Missions** - Sistema de gamificación
6. **Restaurants y Hotels** - Información adicional

## ✅ Checklist de Migración

- [ ] Ejecutar schema SQL en Supabase
- [ ] Configurar credenciales en `supabase_config.dart`
- [ ] Inicializar Supabase en `main.dart`
- [ ] Actualizar provider de casinos
- [ ] Actualizar provider de eventos
- [ ] Actualizar provider de promociones
- [ ] Actualizar provider de usuarios
- [ ] Implementar sincronización de puntos
- [ ] Implementar sistema de comentarios
- [ ] Migrar datos existentes a Supabase (usando admin panel)
- [ ] Testing completo de flujos principales
- [ ] Configurar RLS en producción
- [ ] Deploy de app con Supabase habilitado

## 🐛 Debugging

Activa logs detallados durante la migración:

```dart
// En supabase_service.dart
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
  debug: true, // ← Habilitar en desarrollo
);
```

---

**Nota**: La migración puede hacerse gradualmente. No es necesario migrar todo de una vez. Puedes empezar con eventos y promociones, probar en producción, y luego continuar con el resto.
