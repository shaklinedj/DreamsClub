# Copilot Instructions - Casino Loyalty Flutter App

## Project Overview

**Casino Loyalty** is a Flutter loyalty app for the Dreams casino chain in Chile. Users can view nearby casinos, promotions, events, and select a favorite casino. The app uses **Riverpod** for state management and **GoRouter** for navigation.

### Tech Stack
- **Flutter 3.4+** with Riverpod 2.5.1
- **State Management**: Riverpod (FutureProvider, StateProvider, Provider)
- **Navigation**: GoRouter with StatefulShellRoute (bottom nav support)
- **Local Storage**: SharedPreferences for favorite casino persistence
- **Geolocation**: geolocator package for location services
- **UI**: Material Design with Google Fonts (Oswald, Roboto, Open Sans)

## Architecture

### Core Layer Pattern: Services → Providers → Screens

1. **Services** (`lib/services/`) - Mock data sources
   - `CasinoService` - 7 Chilean casinos with hotels & restaurants
   - `EventService`, `PromotionService` - Event/promotion data per casino
   - `UserPreferences` - Local storage wrapper (SharedPreferences)
   - `LocationService` - Currently stub (empty), will handle geolocator calls

2. **Providers** (`lib/providers/`) - Riverpod state containers
   - `FutureProvider<List<Casino>>` via `casinosProvider`
   - `FutureProvider.family<List<Event>, int>` scoped by casinoId
   - `StateProvider<int?>` for active casino tracking

3. **Screens** (`lib/screens/`) - UI consumers
   - Use `ref.watch()` to subscribe to providers
   - Use `ref.read()` for one-time reads (splash logic)
   - Data flows: Service → Provider → Widget `.when()` handler

### Navigation Structure (GoRouter)

```
/ (DecisionScreen) → check favorite → /home (bottom nav root)
├── /home (HomeScreen)
├── /promotions (PromotionsScreen)
├── /events (EventsScreen)
└── /all-casinos (AllCasinosScreen)
    └── :id (CasinoDetailScreen)
/select-favorite (SelectFavoriteScreen)
/promotion/:id (PromotionDetailScreen)
```

**Key Detail**: StatefulShellRoute with 4 branches preserves nav state across tab switches. Casino detail uses nested route under `/all-casinos`.

## Critical Workflows

### Adding New Features

1. **New Data Type** (e.g., loyalty points)
   - Create model in `lib/models/` with `fromJson` factory
   - Create service in `lib/services/` returning `Future<T>`
   - Create provider in `lib/providers/` as `FutureProvider` or `FutureProvider.family`

2. **New Screen**
   - Create in `lib/screens/`, consume providers via `ref.watch()`
   - Add route to `lib/navigation/app_router.dart`
   - Use `.when(data:, loading:, error:)` for async UI

3. **Testing Locally**
   ```bash
   flutter pub get
   flutter run
   ```

### Common Patterns

**Closest Casino Logic** (Splash Screen):
- Calculate distance using `Geolocator.distanceBetween()`
- Haversine formula implemented in `_calculateDistance()`
- Fallback: if user >20km from favorite, show dialog to switch

**Scoped Data by Casino**:
```dart
// FutureProvider.family pattern - used for events/promotions/restaurants
final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) {
  return ref.watch(eventServiceProvider).getEventsByCasinoId(casinoId);
});

// Usage: ref.watch(eventsProvider(casinoId)).when(...)
```

**UI State Handling**:
```dart
// Use .when() for clean async handling
casinosAsync.when(
  data: (casinos) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
)
```

## Project-Specific Conventions

### Naming
- Services: `{Entity}Service` (e.g., `CasinoService`)
- Providers: `{entity}Provider`, `{entity}sProvider` (plural for lists)
- Models: `{Entity}Model` or just `{Entity}` class
- Screens: `{feature}_screen.dart` (snake_case files)

### Data Flow Example: Displaying Casino Promotions

1. User navigates to `/promotions`
2. `PromotionsScreen` calls `ref.watch(promotionsProvider(activeCAsinoId))`
3. Provider calls `PromotionService.getPromotionsByCasinoId()`
4. Service returns mock list filtered by casinoId
5. Widget renders via `.when(data: (promos) => ...)`

### Empty State Handling
- When lists are empty (no events/promos), show centered message: "No hay eventos/promociones disponibles para este casino."
- Example: `EventsScreen`, `PromotionsScreen`

### Images
- **Casinos**: Local assets in `assets/images/` (e.g., `iqq.jpg`, `temuco.jpg`)
- **Events/Promotions**: Placeholder URLs from `picsum.photos` (seed-based, pseudo-stable)
- **Load via**: `Image.asset()` for local, `Image.network()` for URLs

## Integration Points & Dependencies

### SharedPreferences (user_prefs.dart)
- Stores single favorite casino ID under `'favoriteCasino'` key
- Async operations - always `await`
- Used by: DecisionScreen, SplashScreen, SelectFavoriteScreen

### Geolocator (not fully implemented)
- `LocationService` stub exists but is empty
- Future: Request location permission and get user coordinates
- Will feed into splash screen closest-casino logic

### Data Persistence Strategy
- **Current**: Mock data in-memory (services recreated per access)
- **Future**: Replace mock lists with Firebase/HTTP calls
- Service interface stays same: `Future<T>` return type

## Files to Reference When Implementing

- `lib/navigation/app_router.dart` - Route definitions and navigation flow
- `lib/services/casino_service.dart` - Mock data structure (7 casinos with lat/long)
- `lib/providers/casino_providers.dart` - Provider patterns baseline
- `lib/screens/splash_screen.dart` - Complex async logic example (distance calc, dialog logic)
- `lib/theme/app_theme.dart` - Color scheme (gold #D4AF37, dark gray #4C4C4C)

## Do's and Don'ts

✅ **Do:**
- Use `ref.watch()` in build methods, `ref.read()` in callbacks
- Return `Future<T>` from service methods for consistency
- Scope data fetches by ID using `FutureProvider.family`
- Show loading/error states in UI
- Test navigation paths in hot reload

❌ **Don't:**
- Make blocking calls outside async handlers
- Store large state in `StateProvider` - use computed `FutureProvider` instead
- Hardcode casino IDs - always pass via route params or provider
- Import services directly in screens - go through providers
- Mix `.go()` and `.push()` - use `.push()` for detail screens to preserve stack
