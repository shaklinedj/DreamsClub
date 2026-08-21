import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/models/user_model.dart';

import 'package:casinoloyalty_flutter/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Mock transaction model
class Transaction {
  final String id;
  final String type; // 'load' or 'spend'
  final double amount;
  final DateTime date;
  final String description;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });
}

// Mock wallet balance provider
final walletBalanceProvider = StateProvider<double>((ref) => 50000.0);

// Mock transactions provider
final transactionsProvider = StateProvider<List<Transaction>>((ref) => [
      Transaction(
        id: '1',
        type: 'load',
        amount: 50000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Carga inicial',
      ),
    ]);

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showAllTransactions = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showLoadMoneyDialog() {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cargar Dinero',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa el monto a cargar',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(color: Colors.white),
                    hintText: '10.000',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un monto';
                    }
                    final amount = double.tryParse(value.replaceAll('.', ''));
                    if (amount == null || amount <= 0) {
                      return 'Monto inválido';
                    }
                    if (amount < 5000) {
                      return 'Monto mínimo: \$5.000';
                    }
                    if (amount > 1000000) {
                      return 'Monto máximo: \$1.000.000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _QuickAmountChip(amount: 10000, onTap: _setAmount),
                    _QuickAmountChip(amount: 20000, onTap: _setAmount),
                    _QuickAmountChip(amount: 50000, onTap: _setAmount),
                    _QuickAmountChip(amount: 100000, onTap: _setAmount),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _processLoadMoney(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Cargar'),
          ),
        ],
      ),
    );
  }

  void _setAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  void _processLoadMoney(BuildContext dialogContext) {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));

      // Add to balance
      final currentBalance = ref.read(walletBalanceProvider);
      ref.read(walletBalanceProvider.notifier).state = currentBalance + amount;

      // Add transaction
      final transactions = ref.read(transactionsProvider);
      ref.read(transactionsProvider.notifier).state = [
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'load',
          amount: amount,
          date: DateTime.now(),
          description: 'Carga de saldo',
        ),
        ...transactions,
      ];

      Navigator.of(dialogContext).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Carga exitosa: \$${NumberFormat('#,###', 'es_CL').format(amount)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final balance = ref.watch(walletBalanceProvider);
    final transactions = ref.watch(transactionsProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            ScaffoldWithNavBar.scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text('Mi Cartera'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Wallet Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A3E),
                    const Color(0xFF1E1E2E),
                    primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with name and level badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mi Cartera Dreams',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(user.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars,
                                size: 14, color: user.levelTextColor),
                            const SizedBox(width: 4),
                            Text(
                              user.levelName,
                              style: TextStyle(
                                color: user.levelTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.account_balance_wallet,
                                  size: 18, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            const Text('SALDO DISPONIBLE',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withValues(alpha: 0.7),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  '\$${NumberFormat('#,###', 'es_CL').format(balance)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Points Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.stars,
                                  size: 18, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            const Text('PUNTOS DREAMS',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.7),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                '${user.points}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('pts',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Level Progress
                  _buildLevelProgress(user),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Load Money Button (Premium Style)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showLoadMoneyDialog,
                icon: const Icon(Icons.add_circle_outline, size: 24),
                label: const Text('CARGAR DINERO',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: user.levelTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historial de Transacciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (transactions.length > 10)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllTransactions = !_showAllTransactions;
                      });
                    },
                    child: Text(
                      _showAllTransactions ? 'Ver menos' : 'Ver todo',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No hay transacciones',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_showAllTransactions ? transactions : transactions.take(10))
                  .map((transaction) {
                final isLoad = transaction.type == 'load';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLoad
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isLoad ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isLoad ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(transaction.date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isLoad ? '+' : '-'}\$${NumberFormat('#,###', 'es_CL').format(transaction.amount)}',
                        style: TextStyle(
                          color: isLoad ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 100), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(User user) {
    // Level thresholds: Blue (0) → Platinum (10000) → Gold (25000) → Black (50000)
    final levels = [
      {'level': UserLevel.blue, 'name': 'Blue', 'threshold': 0},
      {'level': UserLevel.platinum, 'name': 'Platinum', 'threshold': 10000},
      {'level': UserLevel.gold, 'name': 'Gold', 'threshold': 25000},
      {'level': UserLevel.black, 'name': 'Black', 'threshold': 50000},
    ];

    int currentIndex = levels.indexWhere((l) => l['level'] == user.level);
    if (currentIndex == -1) currentIndex = 0;

    // If already at max level
    if (currentIndex >= levels.length - 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Máximo nivel alcanzado!',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      );
    }

    final currentThreshold = levels[currentIndex]['threshold'] as int;
    final nextLevel = levels[currentIndex + 1];
    final nextThreshold = nextLevel['threshold'] as int;
    final nextName = nextLevel['name'] as String;

    final pointsInLevel = user.points - currentThreshold;
    final pointsNeeded = nextThreshold - currentThreshold;
    final progress = (pointsInLevel / pointsNeeded).clamp(0.0, 1.0);
    final pointsRemaining = nextThreshold - user.points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Próximo nivel: $nextName',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              '${NumberFormat('#,###', 'es_CL').format(pointsRemaining)} pts restantes',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              NumberFormat('#,###', 'es_CL').format(currentThreshold),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            Text(
              NumberFormat('#,###', 'es_CL').format(nextThreshold),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final double amount;
  final Function(double) onTap;

  const _QuickAmountChip({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('\$${NumberFormat('#,###', 'es_CL').format(amount)}'),
      onPressed: () => onTap(amount),
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
