import 'dart:ui';

import 'package:casinoloyalty_flutter/providers/user_provider.dart';

import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  /// GlobalKey para acceder al Scaffold desde pantallas hijas
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  @override
  Widget build(BuildContext context) {
    // DreamsMania auto-trigger removed - games only accessible from Games section

    final user = ref.watch(userProvider);

    final primaryColor = user.levelColor;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: ScaffoldWithNavBar.scaffoldKey,
      drawer: const AppDrawer(),
      extendBody: true,
      body: Stack(
        children: [
          // Wrap navigation shell in SafeArea to prevent system bar overlap
          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 60 + MediaQuery.of(context).padding.bottom,
                ),
                child: PopScope(
                  canPop: widget.navigationShell.currentIndex == 0,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    widget.navigationShell.goBranch(0);
                  },
                  child: widget.navigationShell,
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar - 4 or 3 items
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
                    left: 8,
                    right: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  height: 60 + MediaQuery.of(context).padding.bottom,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavBarItem(
                          icon: Icons.home_outlined,
                          label: 'Inicio',
                          isActive: widget.navigationShell.currentIndex == 0,
                          onTap: () => widget.navigationShell.goBranch(0),
                          activeColor: primaryColor,
                        ),
                        _NavBarItem(
                          icon: Icons.video_collection_outlined,
                          label: 'Novedades',
                          isActive: widget.navigationShell.currentIndex == 1,
                          onTap: () => widget.navigationShell.goBranch(1),
                          activeColor: primaryColor,
                        ),
                        _NavBarItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Cartera',
                          isActive: widget.navigationShell.currentIndex == 2,
                          onTap: () => widget.navigationShell.goBranch(2),
                          activeColor: primaryColor,
                        ),
                        _NavBarItem(
                          icon: Icons.location_on_outlined,
                          label: 'Casinos',
                          isActive: widget.navigationShell.currentIndex == 3,
                          onTap: () => widget.navigationShell.goBranch(3),
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
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
