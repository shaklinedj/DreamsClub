import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPrizesScreen extends ConsumerStatefulWidget {
  const MyPrizesScreen({super.key});

  @override
  ConsumerState<MyPrizesScreen> createState() => _MyPrizesScreenState();
}

class _MyPrizesScreenState extends ConsumerState<MyPrizesScreen>
    with SingleTickerProviderStateMixin {
  final PrizeService _prizeService = PrizeService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getPrizeColor(PrizeType type) {
    switch (type) {
      case PrizeType.hotel:
        return Colors.purple;
      case PrizeType.drink:
        return Colors.blue;
      case PrizeType.food:
        return Colors.orange;
      case PrizeType.tickets:
        return Colors.pink;
      case PrizeType.chips:
        return Colors.green;
      case PrizeType.points:
        return const Color(0xFFD4AF37);
      case PrizeType.promotionalCredits:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? (user.email.isNotEmpty ? user.email : (user.rut ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: const Text(
          'Billetera de Premios',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          indicatorWeight: 3,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Disponibles', icon: Icon(Icons.card_giftcard, size: 18)),
            Tab(text: 'Cobrados', icon: Icon(Icons.check_circle_outline, size: 18)),
            Tab(text: 'Expirados', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: StreamBuilder<List<WonPrize>>(
        stream: _prizeService.streamUserPrizes(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          final allPrizes = snapshot.data ?? [];
          final activePrizes = allPrizes.where((p) => p.isActive).toList();
          final redeemedPrizes = allPrizes.where((p) => p.isRedeemed).toList();
          final expiredPrizes = allPrizes.where((p) => p.isExpired && !p.isRedeemed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Disponibles
              activePrizes.isEmpty
                  ? _buildEmptyState(
                      'No tienes premios por canjear',
                      '¡Juega a la Ruleta, Slots o Dreams Match para ganar!',
                      Icons.card_giftcard,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activePrizes.length,
                      itemBuilder: (context, index) {
                        return _buildPrizeCard(activePrizes[index]);
                      },
                    ),

              // 2. Cobrados
              redeemedPrizes.isEmpty
                  ? _buildEmptyState(
                      'Sin premios cobrados aún',
                      'Cuando el atendedor en caja queme tu premio aparecerá aquí.',
                      Icons.receipt_long,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: redeemedPrizes.length,
                      itemBuilder: (context, index) {
                        return _buildPrizeCard(redeemedPrizes[index], isRedeemed: true);
                      },
                    ),

              // 3. Expirados
              expiredPrizes.isEmpty
                  ? _buildEmptyState(
                      'No tienes premios vencidos',
                      'Todos tus premios están al día.',
                      Icons.alarm_on,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: expiredPrizes.length,
                      itemBuilder: (context, index) {
                        return _buildPrizeCard(expiredPrizes[index], isExpired: true);
                      },
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(icon, size: 64, color: const Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeCard(WonPrize prize, {bool isRedeemed = false, bool isExpired = false}) {
    final prizeColor = _getPrizeColor(prize.prize.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRedeemed
              ? Colors.green.withValues(alpha: 0.4)
              : isExpired
                  ? Colors.red.withValues(alpha: 0.3)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          if (!isRedeemed && !isExpired)
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/prize-detail/${prize.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: prizeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: prizeColor.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          prize.prize.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prize.prize.name,
                            style: TextStyle(
                              color: isRedeemed
                                  ? Colors.grey
                                  : isExpired
                                      ? Colors.grey
                                      : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prize.prize.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Expiry / Status text
                          if (isRedeemed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '✓ CANJEADO EN CAJA',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '✕ VENCIDO',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: prizeColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Expira en: ${prize.daysUntilExpiry}',
                                  style: TextStyle(
                                    color: prizeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // Alphanumeric Code Strip
                Row(
                  children: [
                    const Text(
                      'CÓDIGO DE CANJE:',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prize.redemptionCode.isNotEmpty
                                ? prize.redemptionCode
                                : prize.id,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: prize.redemptionCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Código copiado al portapapeles'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: Color(0xFFD4AF37),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.copy,
                              size: 14,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
