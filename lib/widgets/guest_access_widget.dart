import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';

/// Widget to display when user doesn't have Dreams membership
/// Shows a message encouraging them to register at a casino
class GuestAccessWidget extends StatelessWidget {
  final String featureName;
  final IconData? icon;

  const GuestAccessWidget({
    super.key,
    this.featureName = 'esta función',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF5D061)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon ?? Icons.card_membership,
                    size: 60,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  '¡Únete a Dreams Club!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Description
                Text(
                  'Para acceder a $featureName necesitas tener tu tarjeta Dreams Club.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Casino registration message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFD4AF37),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Acércate a cualquier casino de la compañía y regístrate',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Para ingresar a un mundo de entretenimiento!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // View Casinos Button
                ElevatedButton.icon(
                  onPressed: () => context.go('/casinos'),
                  icon: const Icon(Icons.casino),
                  label: const Text('VER CASINOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that checks user access and shows content or guest message
class MembershipGuard extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final IconData? icon;
  final bool requiresMembership;

  const MembershipGuard({
    super.key,
    required this.child,
    this.featureName = 'esta función',
    this.icon,
    this.requiresMembership = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Uncommented enforcement logic
    if (requiresMembership && !authState.hasFullAccess) {
      return GuestAccessWidget(featureName: featureName, icon: icon);
    }

    return child;
  }
}
