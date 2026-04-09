import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyPrizesScreen extends StatefulWidget {
  const MyPrizesScreen({super.key});

  @override
  State<MyPrizesScreen> createState() => _MyPrizesScreenState();
}

class _MyPrizesScreenState extends State<MyPrizesScreen>
    with SingleTickerProviderStateMixin {
  final PrizeService _prizeService = PrizeService();
  late TabController _tabController;

  List<WonPrize> _activePrizes = [];
  List<WonPrize> _redeemedPrizes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrizes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrizes() async {
    setState(() => _isLoading = true);

    final active = await _prizeService.getActivePrizes();
    final redeemed = await _prizeService.getRedeemedPrizes();

    setState(() {
      _activePrizes = active;
      _redeemedPrizes = redeemed;
      _isLoading = false;
    });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Premios'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Canjeados'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Active prizes
                _activePrizes.isEmpty
                    ? _buildEmptyState('No tienes premios activos',
                        'Gira la ruleta para ganar!')
                    : RefreshIndicator(
                        onRefresh: _loadPrizes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activePrizes.length,
                          itemBuilder: (context, index) {
                            return _buildPrizeCard(_activePrizes[index]);
                          },
                        ),
                      ),
                // Redeemed prizes
                _redeemedPrizes.isEmpty
                    ? _buildEmptyState(
                        'No has canjeado premios', 'Usa tus premios activos!')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _redeemedPrizes.length,
                        itemBuilder: (context, index) {
                          return _buildPrizeCard(_redeemedPrizes[index],
                              isRedeemed: true);
                        },
                      ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeCard(WonPrize prize, {bool isRedeemed = false}) {
    final prizeColor = _getPrizeColor(prize.prize.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRedeemed
              ? Colors.grey.withValues(alpha: 0.3)
              : prizeColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/prize-detail/${prize.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: prizeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      prize.prize.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prize.prize.name,
                        style: TextStyle(
                          color: isRedeemed ? Colors.grey : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prize.prize.description,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (isRedeemed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✓ CANJEADO',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: prizeColor),
                            const SizedBox(width: 4),
                            Text(
                              'Expira en: ${prize.daysUntilExpiry}',
                              style: TextStyle(
                                  color: prizeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: isRedeemed ? Colors.grey : const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
