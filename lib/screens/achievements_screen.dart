import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/screens/coyhaique/coyhaique_shell.dart';
import 'package:casinoloyalty_flutter/screens/stickers_gallery_screen.dart';
import 'package:casinoloyalty_flutter/widgets/animated_bell.dart';
import 'package:casinoloyalty_flutter/widgets/notifications_modal.dart';
import 'package:casinoloyalty_flutter/widgets/gamification_section.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  Future<void> _openWhatsAppStickers(String packName, int streakTier) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StickersGalleryScreen(
          packName: packName,
          targetStreakTier: streakTier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final streak = userState.streak;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            CoyhaiqueShell.openDrawer();
          },
        ),
        title: const Text('Logros & Recompensas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const AnimatedBell(),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NotificationsModal(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          const GamificationSection(),
          const SizedBox(height: 28),

          // 2. STICKERS OFICIALES SECTION
          const Text(
            '🎨 STICKERS EXCLUSIVOS PARA WHATSAPP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _StickerPackCard(
            title: 'Pack Oficial Dreams Coyhaique',
            description: 'Stickers de la Patagonia, ruleta y diversión para compartir.',
            icon: '🏔️',
            unlocked: streak >= 1,
            requiredStreak: 'Desbloqueado (Día 1)',
            onDownload: () => _openWhatsAppStickers('Pack Dreams Coyhaique 1d', 1),
          ),

          const SizedBox(height: 12),

          _StickerPackCard(
            title: 'Pack Memes & Casino Party',
            description: 'Stickers animados de fiesta, coctelería y torneos.',
            icon: '🎉',
            unlocked: streak >= 3,
            requiredStreak: 'Requiere 3 días de racha',
            onDownload: () => _openWhatsAppStickers('Pack Memes y Casino 3d', 3),
          ),

          const SizedBox(height: 12),

          _StickerPackCard(
            title: 'Pack VIP Gold Legends',
            description: 'Stickers dorados exclusivos para miembros dedicados.',
            icon: '👑',
            unlocked: streak >= 7,
            requiredStreak: 'Requiere 7 días de racha',
            onDownload: () => _openWhatsAppStickers('Pack VIP Gold 7d', 7),
          ),

          const SizedBox(height: 12),

          _StickerPackCard(
            title: 'Pack Maestro de Coyhaique',
            description: 'Stickers premium para nuestros visitantes más leales.',
            icon: '💎',
            unlocked: streak >= 14,
            requiredStreak: 'Requiere 14 días de racha',
            onDownload: () => _openWhatsAppStickers('Pack Maestro Coyhaique 14d', 14),
          ),

          const SizedBox(height: 12),

          _StickerPackCard(
            title: 'Pack Leyenda Absoluta',
            description: 'Stickers legendarios y exclusivos de máxima categoría.',
            icon: '🔥',
            unlocked: streak >= 30,
            requiredStreak: 'Requiere 30 días de racha',
            onDownload: () => _openWhatsAppStickers('Pack Leyenda Absoluta 30d', 30),
          ),

          const SizedBox(height: 28),

          // 3. THEME UNLOCKS SECTION
          const Text(
            '🌟 TEMAS Y COLORES DE LA APP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          const _ThemeUnlockCard(
            title: 'Tema Clásico Dreams',
            subtitle: 'Diseño morado & azul de la noche.',
            colorPreview: Color(0xFF6B21A8),
            unlocked: true,
            requiredText: 'Disponible siempre',
          ),

          const SizedBox(height: 12),

          _ThemeUnlockCard(
            title: 'Tema Dorado VIP (Gold)',
            subtitle: 'Detalles en oro brillante y acabados de lujo.',
            colorPreview: const Color(0xFFD4AF37),
            unlocked: streak >= 3,
            requiredText: streak >= 3 ? '¡Desbloqueado!' : 'Desbloquea con 3 días de racha',
          ),

          const SizedBox(height: 12),

          _ThemeUnlockCard(
            title: 'Tema Platino Austral',
            subtitle: 'Gradientes gélidos inspirados en la Patagonia de Aysén.',
            colorPreview: const Color(0xFF0EA5E9),
            unlocked: streak >= 7,
            requiredText: streak >= 7 ? '¡Desbloqueado!' : 'Desbloquea con 7 días de racha',
          ),

          const SizedBox(height: 12),

          _ThemeUnlockCard(
            title: 'Tema Especial Patagónico',
            subtitle: 'Diseño exclusivo con paisajes y colores de bosques milenarios.',
            colorPreview: const Color(0xFF10B981),
            unlocked: streak >= 14,
            requiredText: streak >= 14 ? '¡Desbloqueado!' : 'Desbloquea con 14 días de racha',
          ),

          const SizedBox(height: 12),

          _ThemeUnlockCard(
            title: 'Tema Diamante Oscuro',
            subtitle: 'Estética premium en tonos oscuros para el modo leyenda.',
            colorPreview: const Color(0xFF1E293B),
            unlocked: streak >= 30,
            requiredText: streak >= 30 ? '¡Desbloqueado!' : 'Desbloquea con 30 días de racha',
          ),
        ],
      ),
    );
  }
}

class _StickerPackCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final String requiredStreak;
  final VoidCallback onDownload;

  const _StickerPackCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.requiredStreak,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? const Color(0xFF25D366).withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFF25D366).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked ? '✅ $requiredStreak' : '🔒 $requiredStreak',
                  style: TextStyle(
                    color: unlocked ? const Color(0xFF25D366) : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            ElevatedButton(
              onPressed: onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size.zero,
              ),
              child: const Text('Descargar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _ThemeUnlockCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color colorPreview;
  final bool unlocked;
  final String requiredText;

  const _ThemeUnlockCard({
    required this.title,
    required this.subtitle,
    required this.colorPreview,
    required this.unlocked,
    required this.requiredText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? colorPreview.withValues(alpha: 0.6)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorPreview,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorPreview.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                unlocked ? Icons.check : Icons.lock_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  requiredText,
                  style: TextStyle(
                    color: unlocked ? const Color(0xFFD4AF37) : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
