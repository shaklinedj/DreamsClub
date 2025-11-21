import 'package:flutter/material.dart';
import 'package:casinoloyalty_flutter/models/reaction_type.dart';

class AnimatedReactionEmoji extends StatefulWidget {
  final ReactionType reactionType;
  final VoidCallback onTap;
  final double size;
  final int animationDelay;

  const AnimatedReactionEmoji({
    super.key,
    required this.reactionType,
    required this.onTap,
    this.size = 40,
    this.animationDelay = 0,
  });

  @override
  State<AnimatedReactionEmoji> createState() => _AnimatedReactionEmojiState();
}

class _AnimatedReactionEmojiState extends State<AnimatedReactionEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Staggered animation delay
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Bounce animation on tap
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedScale(
            scale: _isHovered ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color:
                              widget.reactionType.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.reactionType.emoji,
                  style: TextStyle(fontSize: widget.size * 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
