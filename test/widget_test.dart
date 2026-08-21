import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HomeScreen muestra información del casino seleccionado',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      // Evita que el bonus diario se marque como reclamable (y abra un diálogo).
      'last_daily_claim': DateTime.now().toIso8601String(),
      'daily_streak': 0,
    });

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
          // Evita llamadas a red en providers base.
          casinosProvider.overrideWith((ref) async => <Casino>[]),
          selectedCasinoProvider.overrideWith((ref) async => sampleCasino),
          locationServiceProvider.overrideWith((ref) => LocationService()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Permite resolver el FutureProvider y el primer frame sin esperar a que “se asiente”
    // (HomeScreen dispara callbacks post-frame y timers que pueden impedir pumpAndSettle).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // HomeScreen programa un Future.delayed de 1s en initState; avanzamos el tiempo
    // para evitar timers pendientes al terminar el test.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('DREAMS CLUB'), findsOneWidget);
    expect(find.text(sampleCasino.nombre.toUpperCase()), findsWidgets);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}

