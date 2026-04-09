import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

class GameVictoryDialog extends StatefulWidget {
  final String gameName;
  final int? pointsWon;
  final String? prizeName;
  final String? prizeIcon;
  final VoidCallback? onClose;
  final String? viewButtonLabel;
  final VoidCallback? onViewPressed;

  const GameVictoryDialog({
    super.key,
    required this.gameName,
    this.pointsWon,
    this.prizeName,
    this.prizeIcon,
    this.onClose,
    this.viewButtonLabel,
    this.onViewPressed,
  });

  @override
  State<GameVictoryDialog> createState() => _GameVictoryDialogState();
}

class _GameVictoryDialogState extends State<GameVictoryDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Auto-play confetti on dialog open
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleShare() {
    String message = '';
    if (widget.pointsWon != null) {
      message =
          '🎰 ¡Gané ${widget.pointsWon} puntos en ${widget.gameName} de Dreams Club! 🎉';
    } else if (widget.prizeName != null) {
      message =
          '🎰 ¡Gané ${widget.prizeName} en ${widget.gameName} de Dreams Club! 🎉';
    } else {
      message = '🎰 ¡Gané en ${widget.gameName} de Dreams Club! 🎉';
    }

    SharePlus.instance.share(ShareParams(
      text: message,
      subject: 'Mi victoria en Dreams Club',
    ));
  }

  void _handleViewPoints() {
    // Close dialog first
    Navigator.of(context).pop();

    if (widget.onViewPressed != null) {
      widget.onViewPressed!();
    } else {
      // Navigate to wallet to view points
      context.go('/wallet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Game name
                    Text(
                      widget.gameName.toUpperCase(),
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Victory message
                    Text(
                      '¡FELICIDADES!',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content (Points or Prize)
                    if (widget.pointsWon != null) ...[
                      Text(
                        'HAS GANADO',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '+${widget.pointsWon}',
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PUNTOS',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (widget.prizeName != null) ...[
                      if (widget.prizeIcon != null)
                        Text(
                          widget.prizeIcon!,
                          style: const TextStyle(fontSize: 64),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        widget.prizeName!,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),

                    // Share button
                    ElevatedButton.icon(
                      onPressed: _handleShare,
                      icon: const Icon(Icons.share, color: Colors.black),
                      label: const Text('COMPARTIR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle: textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // View points button
                    ElevatedButton.icon(
                      onPressed: _handleViewPoints,
                      icon: Icon(
                          widget.viewButtonLabel != null
                              ? Icons.card_giftcard
                              : Icons.emoji_events,
                          color: Colors.white),
                      label: Text(widget.viewButtonLabel ?? 'VER MIS PUNTOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        side: BorderSide(color: colorScheme.primary, width: 2),
                        textStyle: textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.close,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFD4AF37),
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }
}
