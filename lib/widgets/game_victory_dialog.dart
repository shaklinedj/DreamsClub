import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

class GameVictoryDialog extends StatefulWidget {
  final String gameName;
  final int? pointsWon;
  final String? prizeName;
  final String? prizeIcon;
  final String? redemptionCode;
  final VoidCallback? onClose;
  final String? viewButtonLabel;
  final VoidCallback? onViewPressed;

  const GameVictoryDialog({
    super.key,
    required this.gameName,
    this.pointsWon,
    this.prizeName,
    this.prizeIcon,
    this.redemptionCode,
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
    if (widget.redemptionCode != null && widget.prizeName != null) {
      message =
          '🎰 ¡Gané ${widget.prizeName} en ${widget.gameName} de Dreams Club! 🎉 Código: ${widget.redemptionCode}';
    } else if (widget.prizeName != null) {
      message =
          '🎰 ¡Gané ${widget.prizeName} en ${widget.gameName} de Dreams Club! 🎉';
    } else if (widget.pointsWon != null) {
      message =
          '🎰 ¡Gané ${widget.pointsWon} puntos en ${widget.gameName} de Dreams Club! 🎉';
    } else {
      message = '🎰 ¡Gané en ${widget.gameName} de Dreams Club! 🎉';
    }

    SharePlus.instance.share(ShareParams(
      text: message,
      subject: 'Mi premio en Dreams Club',
    ));
  }

  void _handleViewPrizes() {
    Navigator.of(context).pop();

    if (widget.onViewPressed != null) {
      widget.onViewPressed!();
    } else {
      context.push('/my-prizes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E2C), Color(0xFF0F0F17)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Game name
                      Text(
                        widget.gameName.toUpperCase(),
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Victory message
                      const Text(
                        '¡FELICIDADES!',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Content (Prize with Icon or Points)
                      if (widget.prizeName != null) ...[
                        if (widget.prizeIcon != null)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                widget.prizeIcon!,
                                style: const TextStyle(fontSize: 42),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          widget.prizeName!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Prominent Alphanumeric Code Display
                        if (widget.redemptionCode != null && widget.redemptionCode!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'CÓDIGO DE CANJE EN CAJA',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  widget.redemptionCode!,
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.redemptionCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('¡Código copiado al portapapeles!'),
                                        backgroundColor: Color(0xFFD4AF37),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy, size: 12, color: Colors.white70),
                                        SizedBox(width: 4),
                                        Text(
                                          'Copiar Código',
                                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Guardado en tu Billetera de Premios',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ] else if (widget.pointsWon != null) ...[
                        const Text(
                          'HAS GANADO',
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 3,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+${widget.pointsWon}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'PUNTOS',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // View in Prizes button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleViewPrizes,
                          icon: const Icon(Icons.card_giftcard, color: Colors.black, size: 20),
                          label: Text(
                            widget.viewButtonLabel ?? 'VER EN MIS PREMIOS',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleShare,
                          icon: const Icon(Icons.share, color: Colors.white, size: 18),
                          label: const Text('COMPARTIR PREMIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFD4AF37),
                      size: 18,
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
            numberOfParticles: 35,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }
}
