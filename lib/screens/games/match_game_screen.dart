import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:casinoloyalty_flutter/providers/match_game_provider.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:casinoloyalty_flutter/services/spin_wheel_service.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/widgets/game_victory_dialog.dart';
import 'package:casinoloyalty_flutter/services/match_game_service.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';

class MatchGameScreen extends ConsumerStatefulWidget {
  const MatchGameScreen({super.key});

  @override
  ConsumerState<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends ConsumerState<MatchGameScreen>
    with TickerProviderStateMixin {
  int? _selectedRow;
  int? _selectedCol;
  late AnimationController _pulseController;
  final PrizeService _prizeService = PrizeService();
  final SpinWheelService _spinWheelService = SpinWheelService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final authState = ref.watch(authProvider);
    final isMember = authState.isMember;

    // Listen to level complete and game over transitions
    ref.listen<MatchGameState>(matchGameProvider, (previous, next) {
      if (previous != null && next.score > previous.score) {
        _audioPlayer.play(AssetSource('sounds/coins.wav')).catchError((_) => null);
      }
      if (next.levelComplete && !(previous?.levelComplete ?? false)) {
        _audioPlayer.play(AssetSource('sounds/win.wav')).catchError((_) => null);
        _showLevelCompleteDialog();
      } else if (next.gameOver && !(previous?.gameOver ?? false)) {
        _audioPlayer.play(AssetSource('sounds/coins_back.wav')).catchError((_) => null);
        _showGameOverDialog();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, gameState, isMember),
              const SizedBox(height: 4),
              _buildScoreBar(gameState),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: _buildGameGrid(gameState),
                ),
              ),
              if (!isMember) _buildPendingPointsBanner(gameState),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, MatchGameState gameState, bool isMember) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'DREAMS MATCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: AppTheme.kPrimaryBlue.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Nivel ${gameState.level}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${gameState.movesLeft}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(MatchGameState gameState) {
    final progress = (gameState.score / gameState.targetScore).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Puntos: ${gameState.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Meta: ${gameState.targetScore}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? const Color(0xFF4CAF50) : const Color(0xFFD4AF37),
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(MatchGameState gameState) {
    if (gameState.grid.isEmpty) {
      return const CircularProgressIndicator(color: Color(0xFFD4AF37));
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 64,
          itemBuilder: (context, index) {
            final row = index ~/ 8;
            final col = index % 8;
            final gem = gameState.grid[row][col];
            final isSelected = _selectedRow == row && _selectedCol == col;

            return _buildGemTile(row, col, gem, isSelected);
          },
        ),
      ),
    );
  }

  Widget _buildGemTile(int row, int col, GemType? gem, bool isSelected) {
    if (gem == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _handleTileTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFFD4AF37), width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            gem.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  void _handleTileTap(int row, int col) {
    HapticFeedback.lightImpact();

    if (_selectedRow == null) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    } else {
      final isAdjacent = (_selectedRow == row && (_selectedCol! - col).abs() == 1) ||
          (_selectedCol == col && (_selectedRow! - row).abs() == 1);

      if (isAdjacent) {
        ref.read(matchGameProvider.notifier).swapGems(
              _selectedRow!,
              _selectedCol!,
              row,
              col,
            );
      }

      setState(() {
        _selectedRow = null;
        _selectedCol = null;
      });
    }
  }

  Widget _buildPendingPointsBanner(MatchGameState gameState) {
    final progress =
        (gameState.pendingPoints / MatchGameService.maxPendingPoints).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFFD4AF37),
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premios y Vouchers Dreams',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '¡Supera cada nivel para desbloquear premios!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '🎁',
                style: TextStyle(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLevelCompleteDialog() async {
    final user = ref.read(userProvider);
    final locationState = ref.read(locationProvider);
    final casinoId = locationState.nearestCasino?.id ?? '4';

    WonPrize? wonPrize;
    try {
      final catalog = await _prizeService.getPrizesCatalog();
      if (catalog.isNotEmpty) {
        final random = Random();
        final selectedPrize = catalog[random.nextInt(catalog.length)];
        wonPrize = _spinWheelService.createWonPrize(
          prize: selectedPrize,
          casinoId: casinoId,
          userId: user.email.isNotEmpty ? user.email : (user.rut ?? ''),
          userName: user.name,
          userEmail: user.email,
          userRut: user.rut ?? '',
          gameSource: 'dreams_match',
        );
        await _prizeService.saveWonPrize(wonPrize);
      }
    } catch (_) {}

    if (!mounted) return;

    final currentLevel = ref.read(matchGameProvider).level;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => GameVictoryDialog(
        gameName: 'Dreams Match - Nivel $currentLevel',
        prizeName: wonPrize?.prize.name ?? '¡Nivel $currentLevel Superado!',
        prizeIcon: wonPrize?.prize.icon ?? '💎',
        redemptionCode: wonPrize?.redemptionCode,
        viewButtonLabel: wonPrize != null ? 'VER EN MIS PREMIOS' : 'SIGUIENTE NIVEL',
        onViewPressed: () {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              if (wonPrize != null) {
                context.push('/my-prizes');
              } else {
                ref.read(matchGameProvider.notifier).startNextLevel();
              }
            }
          });
        },
        onClose: () {
          ref.read(matchGameProvider.notifier).startNextLevel();
        },
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Text('😅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'Sin Movimientos',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'No alcanzaste la meta de puntos. ¡Inténtalo de nuevo!',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Salir'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.kPrimaryBlue,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(matchGameProvider.notifier).restartLevel();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
