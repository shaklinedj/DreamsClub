import 'dart:math';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:flutter/material.dart';

class SpinWheelWidget extends StatefulWidget {
  final List<Prize> prizes;
  final Function(Prize) onSpinComplete;
  final bool isSpinning;

  const SpinWheelWidget({
    super.key,
    required this.prizes,
    required this.onSpinComplete,
    this.isSpinning = false,
  });

  @override
  State<SpinWheelWidget> createState() => _SpinWheelWidgetState();
}

class _SpinWheelWidgetState extends State<SpinWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Prize? _selectedPrize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SpinWheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    }
  }

  void _startSpin() {
    // Calculate winner before animation
    final random = Random();
    int totalProb = widget.prizes.fold(0, (sum, p) => sum + p.probability);
    int randomValue = random.nextInt(totalProb);
    
    int cumulative = 0;
    for (var prize in widget.prizes) {
      cumulative += prize.probability;
      if (randomValue < cumulative) {
        _selectedPrize = prize;
        break;
      }
    }

    _controller.forward(from: 0).then((_) {
      if (_selectedPrize != null) {
        widget.onSpinComplete(_selectedPrize!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Multiple full rotations + final position
        final rotation = _animation.value * 10 * 2 * pi;
        
        return Transform.rotate(
          angle: rotation,
          child: CustomPaint(
            size: const Size(280, 280),
            painter: WheelPainter(
              prizes: widget.prizes,
              selectedPrize: _selectedPrize,
            ),
          ),
        );
      },
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Prize> prizes;
  final Prize? selectedPrize;

  WheelPainter({required this.prizes, this.selectedPrize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final segmentAngle = 2 * pi / prizes.length;

    // Draw segments
    for (var i = 0; i < prizes.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      
      // Alternating colors (gold and dark)
      final color = i % 2 == 0 
          ? const Color(0xFFD4AF37) 
          : const Color(0xFF2A2A2A);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw prize icon/text
      final midAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(midAngle);
      final textY = center.dy + textRadius * sin(midAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i].icon,
          style: const TextStyle(fontSize: 32),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, centerPaint);

    final centerBorderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.2, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
