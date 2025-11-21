import 'package:flutter/material.dart';
import 'package:casinoloyalty_flutter/models/reaction_type.dart';
import 'package:casinoloyalty_flutter/widgets/animated_reaction_emoji.dart';

class ReactionPicker extends StatefulWidget {
  final Function(ReactionType) onReactionSelected;
  final Offset position;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    required this.position,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleReactionSelected(ReactionType reaction) {
    widget.onReactionSelected(reaction);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 150, // Center the picker
      top: widget.position.dy - 70, // Position above the button
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ReactionType.values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reaction = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedReactionEmoji(
                      reactionType: reaction,
                      onTap: () => _handleReactionSelected(reaction),
                      size: 40,
                      animationDelay: index * 30, // Staggered animation
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
