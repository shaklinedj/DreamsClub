import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/notification_provider.dart';

class AnimatedBell extends ConsumerStatefulWidget {
  const AnimatedBell({super.key, this.color = Colors.white});

  final Color color;

  @override
  ConsumerState<AnimatedBell> createState() => _AnimatedBellState();
}

class _AnimatedBellState extends ConsumerState<AnimatedBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación compleja de campana:
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
    final hasNotifications = ref.watch(notificationsProvider).isNotEmpty;

    if (hasNotifications) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: false);
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.reset();
      }
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * pi,
          child: Icon(
            hasNotifications ? Icons.notifications_active : Icons.notifications_outlined,
            color: widget.color,
          ),
        );
      },
    );
  }
}
