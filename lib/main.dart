import 'package:casinoloyalty_flutter/navigation/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:casinoloyalty_flutter/firebase_options.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Si Firebase no está configurado aún, continuamos sin bloquear la app
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Casino Loyalty',
      theme: AppTheme.lightTheme, // Tema claro
      darkTheme: AppTheme.darkTheme, // Tema oscuro
      themeMode: ThemeMode.system, // Usar el tema del sistema
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
