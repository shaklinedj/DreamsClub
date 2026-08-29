import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/game_config_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('HomeScreen muestra información del casino seleccionado',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'last_daily_claim': DateTime.now().toIso8601String(),
      'daily_streak': 0,
    });

    final mockPrefs = await SharedPreferences.getInstance();

    const sampleCasino = Casino(
      id: '1',
      nombre: 'Dreams Arica',
      ciudad: 'Arica',
      direccion: 'Av. Grecia 123',
      latitud: -18.478,
      longitud: -70.312,
      imageUrl: 'assets/images/logo-dreams.png',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          casinosProvider.overrideWith((ref) async => <Casino>[]),
          selectedCasinoProvider.overrideWith((ref) async => sampleCasino),
          locationServiceProvider.overrideWith((ref) => LocationService()),
          gameConfigsProvider.overrideWith((ref) => Stream.value(<GameConfig>[
                const GameConfig(
                  gameId: 'dreams_mania',
                  title: 'Dreams Manía',
                  isActive: true,
                  requiresLocation: false,
                ),
                const GameConfig(
                  gameId: 'roulette',
                  title: 'Ruleta de la Suerte',
                  isActive: true,
                  requiresLocation: false,
                ),
                const GameConfig(
                  gameId: 'slots',
                  title: 'Máquina de Premios',
                  isActive: true,
                  requiresLocation: false,
                ),
                const GameConfig(
                  gameId: 'dreams_match',
                  title: 'Dreams Match',
                  isActive: true,
                  requiresLocation: false,
                ),
              ])),
          globalGameRulesProvider.overrideWith(
              (ref) => Stream.value(const GameRulesConfig())),
          gameHistoryProvider.overrideWith(
              (ref) => GameHistoryNotifier('')),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Permite resolver el FutureProvider y el primer frame sin esperar a que “se asiente”
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('ZONA DE JUEGOS'), findsOneWidget);
    expect(find.text('Dreams Match'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
