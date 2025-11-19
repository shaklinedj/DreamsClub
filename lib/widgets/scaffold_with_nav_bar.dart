import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/widgets/loyalty_card_widget.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  void _showQRModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'DREAMS CLUB',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tarjeta de Socio Digital',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: LoyaltyCardWidget(user: user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final primaryColor = Theme.of(context).primaryColor;
    final userLevelColor = user.levelColor;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 60 + bottomPadding), // Espacio para la navbar
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none, // Permitir que el botón salga fuera
              children: [
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: bottomPadding,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A).withValues(alpha: 0.85),
                        border: const Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: SizedBox(
                        height: 60, // Altura del contenido de la barra
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        _NavBarItem(
                          icon: Icons.star_outline,
                          label: 'Inicio',
                          isActive: navigationShell.currentIndex == 0,
                          onTap: () => navigationShell.goBranch(0),
                          userLevelColor: userLevelColor,
                        ),
                          _NavBarItem(
                          icon: Icons.card_giftcard,
                          label: 'Beneficios',
                          isActive: navigationShell.currentIndex == 1,
                          onTap: () => navigationShell.goBranch(1),
                          userLevelColor: userLevelColor,
                        ),
                        
                        const SizedBox(width: 70), // Espacio para el botón central
                        
                        _NavBarItem(
                          icon: Icons.event,
                          label: 'Eventos',
                          isActive: navigationShell.currentIndex == 2,
                          onTap: () => navigationShell.goBranch(2),
                          userLevelColor: userLevelColor,
                        ),
                        _NavBarItem(
                          icon: Icons.location_on_outlined,
                          label: 'Casinos',
                          isActive: navigationShell.currentIndex == 3,
                          onTap: () => navigationShell.goBranch(3),
                          userLevelColor: userLevelColor,
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
                // Botón QR flotante que sobresale
                Positioned(
                  left: 0,
                  right: 0,
                  top: -35, // Sobresale 35px hacia arriba
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showQRModal(context, ref),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              userLevelColor,
                              userLevelColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: userLevelColor.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: userLevelColor.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color: user.levelTextColor,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color userLevelColor;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.userLevelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? userLevelColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? userLevelColor : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

