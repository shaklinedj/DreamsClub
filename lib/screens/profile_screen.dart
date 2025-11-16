
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/widgets/loyalty_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                backgroundColor: Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Aquí integramos la tarjeta de lealtad
              LoyaltyCardWidget(user: user),
              const SizedBox(height: 24),
              // Otros detalles pueden ir aquí si es necesario
              ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.white70),
                  title: Text(
                    user.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
