import 'package:casinoloyalty_flutter/config/membership_levels_config.dart';
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/screens/coyhaique/coyhaique_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BenefitsScreen extends ConsumerWidget {
  const BenefitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = context.canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => CoyhaiqueShell.openDrawer(),
              ),
        title: const Text('Beneficios Club'),
        centerTitle: false,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MembershipLevelsHeader(),
            SizedBox(height: 16),
            _MembershipLevelsCarousel(),
            SizedBox(height: 100), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }
}

class _MembershipLevelsHeader extends StatelessWidget {
  const _MembershipLevelsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveles de Membresía',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Descubre los beneficios exclusivos de cada categoría',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    );
  }
}

class _MembershipLevelsCarousel extends StatelessWidget {
  const _MembershipLevelsCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480, // Height for the card
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MembershipLevelsConfig.levels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final info = MembershipLevelsConfig.levels[index];
          return _MembershipCard(info: info);
        },
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final MembershipLevelInfo info;

  const _MembershipCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header with Gradient and Level Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: info.gradientColors,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo-dreams.png',
                      height: 24,
                      color: info.level == UserLevel.black
                          ? Colors.white
                          : Colors.black87,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(), // Fallback if logo not found
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        info.pointsRequirement,
                        style: TextStyle(
                          color: info.level == UserLevel.black
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'DREAMS CLUB',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: info.level == UserLevel.black
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: const Color(0xFF1E1E2E),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: info.benefits.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final benefit = info.benefits[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              info.gradientColors.first.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(benefit.icon,
                            color: info.gradientColors.first, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              benefit.detail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
