import 'package:flutter/material.dart';
import 'package:casinoloyalty_flutter/models/reaction_type.dart';
import 'package:casinoloyalty_flutter/widgets/reaction_picker.dart';

class ReactionButton extends StatefulWidget {
  final int eventId;
  final double size;
  final Function(ReactionType?)? onReactionChanged;

  const ReactionButton({
    super.key,
    required this.eventId,
    this.size = 24.0,
    this.onReactionChanged,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  ReactionType? _currentReaction;
  OverlayEntry? _overlayEntry;
  bool _isShowingPicker = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Quick like/unlike toggle
    setState(() {
      if (_currentReaction == ReactionType.like) {
        _currentReaction = null;
      } else {
        _currentReaction = ReactionType.like;
      }
    });
    _controller.forward().then((_) => _controller.reset());
    widget.onReactionChanged?.call(_currentReaction);
  }

  void _handleLongPress() {
    if (_isShowingPicker) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _showReactionPicker(position);
  }

  void _showReactionPicker(Offset position) {
    setState(() => _isShowingPicker = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent background to detect taps outside
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Reaction picker
            ReactionPicker(
              position: position,
              onReactionSelected: (reaction) {
                setState(() => _currentReaction = reaction);
                _controller.forward().then((_) => _controller.reset());
                widget.onReactionChanged?.call(reaction);
                _removeOverlay();
              },
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isShowingPicker = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentReaction != null
                ? _currentReaction!.color.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: _currentReaction != null
              ? Text(
                  _currentReaction!.emoji,
                  style: TextStyle(fontSize: widget.size),
                )
              : Icon(
                  Icons.thumb_up_outlined,
                  color: Colors.grey,
                  size: widget.size,
                ),
        ),
      ),
    );
  }
}
