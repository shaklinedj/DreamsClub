import 'package:flutter/material.dart';
import 'dart:math';

class FallingChipWidget extends StatefulWidget {
  final VoidCallback onCaught;

  const FallingChipWidget({super.key, required this.onCaught});

  @override
  State<FallingChipWidget> createState() => _FallingChipWidgetState();
}

class _FallingChipWidgetState extends State<FallingChipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _startX;
  late double _rotation;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _startX = random.nextDouble(); // Random horizontal position (0.0 to 1.0)
    _rotation = random.nextDouble() * 2 * pi; // Random initial rotation

    _controller = AnimationController(
      duration:
          Duration(milliseconds: 1500 + random.nextInt(1000)), // Random speed
      vsync: this,
    );

    _animation = Tween<double>(begin: -100, end: 1000).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // If animation finishes without being caught, just remove it (parent handles list)
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          left: _startX * (screenWidth - 60), // Keep within bounds
          child: GestureDetector(
            onTap: widget.onCaught,
            child: Transform.rotate(
              angle:
                  _rotation + _controller.value * 2 * pi, // Spin while falling
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
