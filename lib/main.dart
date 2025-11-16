import 'package:casinoloyalty_flutter/navigation/app_router.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
   initializeDateFormatting('es_ES', null).then((_) {
    runApp(const ProviderScope(child: MyApp()));
  });
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
