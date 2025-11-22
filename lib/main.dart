import 'package:casinoloyalty_flutter/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const ProviderScope(child: DreamsLoyaltyApp()));
}

// --- CONSTANTES DE DISEÑO ---
const Color kGoldColor = Color(0xFFD4AF37);
const Color kBackgroundColor = Colors.black;
const Color kSurfaceColor = Color(0xFF1A1A1A);
const Color kSurfaceLightColor = Color(0xFF2A2A2A);

class DreamsLoyaltyApp extends StatelessWidget {
  const DreamsLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dreams Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kGoldColor,
        fontFamily: 'Sans',
        colorScheme: const ColorScheme.dark(
          primary: kGoldColor,
          secondary: kGoldColor,
          surface: kSurfaceColor,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
