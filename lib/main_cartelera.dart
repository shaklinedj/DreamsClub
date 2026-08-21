import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:casinoloyalty_flutter/firebase_options.dart';
import 'package:casinoloyalty_flutter/screens/cartelera_coyhaique_screen.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const ProviderScope(child: CarteleraApp()));
  }, (error, stack) {
    debugPrint('Error: $error');
  });
}

class CarteleraApp extends StatelessWidget {
  const CarteleraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartelera Coyhaique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CarteleraCoyhaiqueScreen(),
    );
  }
}
