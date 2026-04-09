import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/providers/match_game_provider.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
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
  bool _levelCompleteShown = false;
  bool _gameOverShown = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final authState = ref.watch(authProvider);
    final isMember = authState.isMember;

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
              const SizedBox(height: 8),
              _buildScoreBar(gameState),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: _buildGameGrid(gameState),
                ),
              ),
              if (!isMember) _buildPendingPointsBanner(gameState),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, MatchGameState gameState, bool isMember) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              border: Border.all(
                  color: AppTheme.kPrimaryBlue.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${gameState.movesLeft}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${gameState.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Meta: ${gameState.targetScore}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * 0.85 * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF5D061)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(MatchGameState gameState) {
    if (gameState.grid.isEmpty) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    // Show level complete dialog (only once)
    if (gameState.levelComplete && !_levelCompleteShown) {
      _levelCompleteShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLevelCompleteDialog();
      });
    } else if (!gameState.levelComplete) {
      _levelCompleteShown = false;
    }

    // Show game over dialog (only once)
    if (gameState.gameOver && !_gameOverShown) {
      _gameOverShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    } else if (!gameState.gameOver) {
      _gameOverShown = false;
    }

    final gridSize = gameState.grid.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = (screenWidth - 48) / gridSize;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(gridSize, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(gridSize, (col) {
              return _buildGemCell(gameState, row, col, cellSize);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildGemCell(
      MatchGameState gameState, int row, int col, double size) {
    final gem = gameState.grid[row][col];
    final isSelected = _selectedRow == row && _selectedCol == col;
    final isMatching = gameState.currentMatches.any(
      (m) => m.row == row && m.col == col,
    );

    return GestureDetector(
      onTap: () => _handleGemTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        child: AnimatedScale(
          scale: isMatching ? 0.0 : (isSelected ? 1.15 : 1.0),
          duration: const Duration(milliseconds: 200),
          child: gem != null
              ? _buildGem(gem, isSelected, size - 4)
              : const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildGem(GemType gem, bool isSelected, double size) {
    final color = Color(gem.colorValue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.9),
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
          width: isSelected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isSelected ? 0.6 : 0.4),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 2 : 0,
          ),
          // Inner glow
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getGemIcon(gem),
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  String _getGemIcon(GemType gem) {
    switch (gem) {
      case GemType.ruby:
        return '💎';
      case GemType.sapphire:
        return '🔷';
      case GemType.emerald:
        return '💚';
      case GemType.gold:
        return '⭐';
      case GemType.amethyst:
        return '🔮';
      case GemType.amber:
        return '🔶';
    }
  }

  void _handleGemTap(int row, int col) {
    HapticFeedback.lightImpact();

    if (_selectedRow == null || _selectedCol == null) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    } else {
      // Check if adjacent
      final rowDiff = (row - _selectedRow!).abs();
      final colDiff = (col - _selectedCol!).abs();

      if (rowDiff + colDiff == 1) {
        // Swap gems
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
        gameState.pendingPoints / MatchGameService.maxPendingPoints;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withValues(alpha: 0.2),
            const Color(0xFFD4AF37).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Puntos Pendientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '¡Obtén tu tarjeta Dreams para canjearlos!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${gameState.pendingPoints}',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${gameState.pendingPoints} / ${MatchGameService.maxPendingPoints} pts',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // ignore: prefer_const_constructors
        title: Column(
          children: const [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              '¡Nivel Completado!',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Has superado el Nivel ${ref.read(matchGameProvider).level}',
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
              backgroundColor: const Color(0xFFD4AF37),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(matchGameProvider.notifier).startNextLevel();
            },
            child: const Text('Siguiente Nivel',
                style: TextStyle(color: Colors.black)),
          ),
        ],
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
          'No alcanzaste la meta. ¡Inténtalo de nuevo!',
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
