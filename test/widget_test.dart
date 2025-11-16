import 'package:casinoloyalty_flutter/main.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen displays logo in AppBar',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeCasinoIdProvider.overrideWith((ref) => 1),
      ],
      child: const MyApp(),
    ));

    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify that our app bar has the logo.
    expect(find.byType(Image), findsOneWidget);
  });
}
