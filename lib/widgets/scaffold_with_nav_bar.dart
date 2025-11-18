import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = (Theme.of(context)
                .textTheme
                .labelMedium)
            ?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ) ??
        TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: CircleNavBar(
          color: colorScheme.surface,
          activeIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          height: 70,
          circleWidth: 62,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          circleShadowColor: Colors.black.withValues(alpha: 0.2),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        circleGradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        activeIcons: const [
          Icon(Icons.star, color: Colors.white),
          Icon(Icons.card_giftcard, color: Colors.white),
          Icon(Icons.event, color: Colors.white),
          Icon(Icons.explore, color: Colors.white),
        ],
        inactiveIcons: [
          Text('Casino', style: labelStyle),
          Text('Promo', style: labelStyle),
          Text('Eventos', style: labelStyle),
          Text('Explorar', style: labelStyle),
        ],
        ),
      ),
    );
  }
}
