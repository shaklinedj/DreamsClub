import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen muestra información del casino seleccionado',
      (WidgetTester tester) async {
    final sampleCasino = Casino(
      id: 1,
      nombre: 'Dreams Arica',
      ciudad: 'Arica',
      direccion: 'Av. Grecia 123',
      latitud: -18.478,
      longitud: -70.312,
      imageUrl: 'assets/images/logo.png',
      hotel: null,
      restaurantes: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedCasinoProvider.overrideWith((ref) async => sampleCasino),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mi Casino'), findsOneWidget);
    expect(find.text(sampleCasino.nombre), findsWidgets);
    expect(find.byIcon(Icons.card_giftcard), findsWidgets);
  });
}
