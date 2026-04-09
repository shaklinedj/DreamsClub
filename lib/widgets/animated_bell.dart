import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBell extends StatefulWidget {
  const AnimatedBell({super.key, this.color = Colors.white});

  final Color color;

  @override
  State<AnimatedBell> createState() => _AnimatedBellState();
}

class _AnimatedBellState extends State<AnimatedBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: false);

    // Animación compleja de campana:
    // 0.0 -> 0.1: Quieto
    // 0.1 -> 0.2: Izquierda
    // 0.2 -> 0.3: Derecha
    // 0.3 -> 0.4: Izquierda
    // 0.4 -> 0.5: Derecha
    // 0.5 -> 0.6: Centro
    // 0.6 -> 1.0: Quieto (Pausa larga)
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0, end: -0.2), weight: 5),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.2), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 5),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.2), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0), weight: 65),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * pi,
          child: Icon(
            Icons.notifications_active,
            color: widget.color,
          ),
        );
      },
    );
  }
}
