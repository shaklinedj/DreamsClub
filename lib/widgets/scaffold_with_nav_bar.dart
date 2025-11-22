import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/widgets/loyalty_card_widget.dart';
// import 'package:casinoloyalty_flutter/widgets/dreams_mania/dreams_mania_overlay.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/dreams_mania_dialog.dart';
import 'package:casinoloyalty_flutter/services/dreams_mania_service.dart';

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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
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
    // Listen for Dreams Mania events and show dialog
    ref.listen<DreamsManiaState>(dreamsManiaProvider, (previous, next) {
      if (previous != null &&
          next.status == DreamsManiaStatus.warning &&
          previous.status == DreamsManiaStatus.inactive) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DreamsManiaDialog(),
        );
      }
    });

    final user = ref.watch(userProvider);
    final primaryColor = user.levelColor;
    final isInsideCasinoAsync = ref.watch(isInsideCasinoProvider);
    final isInsideCasino = isInsideCasinoAsync.value ?? false;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Wrap navigation shell in SafeArea to prevent system bar overlap
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: navigationShell,
            ),
          ),

          // Dreams Manía Overlay - PERMANENTLY DISABLED
          // Architectural issue: Global Stack overlay causes black screen
          // TODO: Reimplement as modal dialog instead
          // const DreamsManiaOverlay(),

          // Dev Trigger for Dreams Manía (Hidden)
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onDoubleTap: () {
                ref.read(dreamsManiaProvider.notifier).triggerEvent();
              },
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent, // Invisible hit box
              ),
            ),
          ),

          // Bottom Navigation Bar Background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    left: 32,
                    right: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A).withValues(alpha: 0.85),
                    border:
                        const Border(top: BorderSide(color: Colors.white10)),
                  ),
                  height: 60 + MediaQuery.of(context).padding.bottom,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavBarItem(
                          icon: Icons.star_outline,
                          label: 'Inicio',
                          isActive: navigationShell.currentIndex == 0,
                          onTap: () => navigationShell.goBranch(0),
                          activeColor: primaryColor,
                        ),
                        const SizedBox(width: 40),
                        _NavBarItem(
                          icon: Icons.location_on_outlined,
                          label: 'Casinos',
                          isActive: navigationShell.currentIndex == 3,
                          onTap: () => navigationShell.goBranch(3),
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Central Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 15,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (isInsideCasino) {
                    context.push('/slot-machine');
                  } else {
                    _showQRModal(context, ref);
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF121212), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    isInsideCasino ? Icons.casino : Icons.qr_code,
                    color: user.levelTextColor,
                    size: 32,
                  ),
                ),
              ),
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
  final Color activeColor;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
