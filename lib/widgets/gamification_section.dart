import 'package:casinoloyalty_flutter/models/gamification_model.dart';
import 'package:casinoloyalty_flutter/providers/gamification_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamificationSection extends ConsumerWidget {
  const GamificationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read user data for Server-Side synchronization
    final user = ref.watch(userProvider);
    // Determine streak from user model (synced with Firestore)
    final streakData = StreakData(
      currentStreak: user.streak,
      longestStreak: 0, // Not currently tracked in plain int, but acceptable
      weekProgress: List.filled(
          7, false), // TOOD: Calculate from visits history if needed
      bonusMultiplier: (1.0 + (user.streak * 0.1)).toInt(),
    );

    final dailyMissions = ref.watch(dailyMissionsProvider);
    final achievements = ref.watch(achievementsProvider);
    final locationState = ref.watch(locationProvider);

    final completedMissions = dailyMissions.where((m) => m.isCompleted).length;
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).length;

    // Check if user is NOT near any casino - show reminder
    final isNotInCasino =
        !locationState.isLoading && !locationState.isNearAnyCasino;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gamification Reminder Banner (when NOT in a casino)
        if (isNotInCasino) _GamificationReminderBanner(),

        // Info Button - Beneficios de la App
        _BenefitsInfoCard(onTap: () => _showBenefitsInfo(context)),
        const SizedBox(height: 16),

        // Streak Card
        _StreakCard(streak: streakData),
        const SizedBox(height: 16),

        // Daily Missions Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt,
                    color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Misiones Diarias',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedMissions/${dailyMissions.length}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Daily Missions List
        ...dailyMissions.map((mission) => _MissionCard(mission: mission)),

        const SizedBox(height: 24),

        // Achievements Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Logros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _showAllAchievements(context, achievements),
              child: Text(
                'Ver todos ($unlockedAchievements/${achievements.length})',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent Achievements (horizontal scroll)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length.clamp(0, 6),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementBadge(achievement: achievement);
            },
          ),
        ),
      ],
    );
  }

  void _showAllAchievements(
      BuildContext context, List<Achievement> achievements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Todos los Logros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return _AchievementListItem(achievement: achievement);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBenefitsInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.stars, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beneficios Dreams Club',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '¡Gana premios visitando nuestros casinos!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sección: Cómo funciona
              _buildInfoSection(
                context,
                '📱',
                '¿Cómo funciona?',
                'Cada vez que visites un casino Dreams, la app detectará tu ubicación y registrará tu visita automáticamente. ¡Así de simple!',
              ),

              // Sección: Racha de visitas
              _buildInfoSection(
                context,
                '🔥',
                'Racha de Visitas',
                'Mantén tu racha visitando casinos días consecutivos y gana premios especiales:\n\n'
                    '• 3 días seguidos → 🥂 Espumante gratis\n'
                    '• 7 días seguidos → 🍽️ Cena para 2\n'
                    '• 14 días seguidos → 🍾 Botella de Champagne\n'
                    '• 30 días seguidos → 🏨 Noche en Hotel Dreams',
              ),

              // Sección: Misiones diarias
              _buildInfoSection(
                context,
                '🎯',
                'Misiones Diarias',
                'Completa misiones cada día para ganar puntos extra y premios:\n\n'
                    '• Visita un casino hoy → Bebida gratis\n'
                    '• Visita 2 casinos diferentes → 3,000 puntos\n'
                    '• Mantén tu racha → Multiplicador de puntos',
              ),

              // Sección: Logros
              _buildInfoSection(
                context,
                '🏆',
                'Logros y Premios',
                'Desbloquea logros visitando casinos y gana increíbles premios:\n\n'
                    '• Primera visita → Bebida de cortesía\n'
                    '• 10 visitas → 2,000 puntos Dreams\n'
                    '• Visita 2 casinos → 5,000 puntos\n'
                    '• Visita todos los casinos → Upgrade VIP 1 mes\n'
                    '• 50 visitas → Entrada VIP permanente\n'
                    '• 100 visitas → Weekend VIP con acompañante',
              ),

              // Sección: Dreams Match
              _buildInfoSection(
                context,
                '💎',
                'Dreams Match',
                '¡Diviértete combinando gemas y gana puntos reales!\n\n'
                    '• Gana 100 puntos Dreams por cada 10,000 pts en el juego\n'
                    '• Sin límite de jugadas diarias\n'
                    '• Disponible en todos los casinos',
              ),

              // Sección: Ubicación
              _buildInfoSection(
                context,
                '📍',
                'Ubicación',
                'Para que podamos registrar tus visitas, asegúrate de:\n\n'
                    '• Tener los permisos de ubicación activados\n'
                    '• Estar físicamente en el casino\n'
                    '• Tener la app abierta o en segundo plano',
              ),

              // CTA
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎰',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¡Empieza a ganar hoy!',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visita tu casino Dreams más cercano',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String emoji, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey[300], height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakData streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.deepOrange.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔥 Racha Actual',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${streak.currentStreak}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            'días',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'x${streak.bonusMultiplier}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Récord: ${streak.longestStreak} días',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Week progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
              final isCompleted = streak.weekProgress[index];
              final isToday = index == DateTime.now().weekday - 1;

              return Column(
                children: [
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: Colors.yellow, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.deepOrange, size: 18)
                          : null,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMission mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mission.isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mission.isCompleted
                  ? Colors.green.withValues(alpha: 0.1)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: mission.isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : Text(mission.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration:
                        mission.isCompleted ? TextDecoration.lineThrough : null,
                    color: mission.isCompleted ? Colors.grey : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (!mission.isCompleted) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mission.progress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: Theme.of(context).primaryColor,
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: mission.isCompleted
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mission.isCompleted ? Icons.check : Icons.star,
                  size: 14,
                  color: mission.isCompleted ? Colors.green : Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${mission.pointsReward}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        mission.isCompleted ? Colors.green : Colors.amber[700],
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

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: achievement.isUnlocked
                    ? Colors.amber
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: achievement.isUnlocked
                  ? Text(achievement.icon, style: const TextStyle(fontSize: 26))
                  : const Icon(Icons.lock, color: Colors.grey, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: achievement.isUnlocked ? null : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AchievementListItem extends StatelessWidget {
  final Achievement achievement;

  const _AchievementListItem({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked
              ? Colors.amber.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: achievement.isUnlocked
                  ? Text(achievement.icon, style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.lock_outline, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (!achievement.isUnlocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: achievement.progress,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            color: Colors.amber,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${achievement.currentValue}/${achievement.targetValue}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Reward
          Column(
            children: [
              Icon(
                achievement.isUnlocked ? Icons.emoji_events : Icons.star_border,
                color: achievement.isUnlocked ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                '+${achievement.pointsReward}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      achievement.isUnlocked ? Colors.amber[700] : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Card de información de beneficios
class _BenefitsInfoCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BenefitsInfoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.3),
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.info_outline, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Gana premios visitando casinos!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Toca aquí para ver todos los beneficios',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Gamification Reminder Banner - shown when user is NOT in a casino
class _GamificationReminderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700.withValues(alpha: 0.2),
            Colors.orange.shade800.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 Acumula puntos visitando un casino',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Abre la app dentro de un casino Dreams para desbloquear juegos y ganar premios.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
