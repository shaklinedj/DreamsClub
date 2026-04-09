import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'reaction_type.dart';

/// A specialized widget to mimic Facebook's social interactions bar.
/// Includes a Like button with reaction picker, Comment button, and Share button.
/// Handles haptic feedback, dynamic scaling of emojis (Lottie) during selection, and sounds.
class FacebookSocialBar extends StatefulWidget {
  final ReactionType? currentReaction;
  final VoidCallback onLikeTap;
  final ValueChanged<ReactionType> onReactionSelected;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final int commentsCount;
  final int sharesCount;

  const FacebookSocialBar({
    super.key,
    this.currentReaction,
    required this.onLikeTap,
    required this.onReactionSelected,
    required this.onCommentTap,
    required this.onShareTap,
    this.commentsCount = 0,
    this.sharesCount = 0,
  });

  @override
  State<FacebookSocialBar> createState() => _FacebookSocialBarState();
}

class _FacebookSocialBarState extends State<FacebookSocialBar> {
  final GlobalKey _likeButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  // Notifier to stream drag positions from the button to the overlay
  final ValueNotifier<Offset?> _dragPositionNotifier = ValueNotifier(null);

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _dragPositionNotifier.dispose();
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(String assetName) async {
    try {
      // Stop if playing to allow rapid sound triggers
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }
      final bytes = await rootBundle
          .load('packages/flutter_facebook_reactions/assets/sounds/$assetName');
      await _audioPlayer.play(BytesSource(bytes.buffer.asUint8List()));
    } catch (_) {
      // Ignore
    }
  }

  void _showReactionPicker() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);

    // Play Open Sound
    _playSound('box_up.mp3');
    HapticFeedback.mediumImpact();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent dismiss layer
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Picker
          _ReactionPickerOverlay(
            key: _pickerKey,
            anchorPosition: Offset(buttonPosition.dx, buttonPosition.dy - 60),
            dragPositionNotifier: _dragPositionNotifier,
            onReactionSelected: (reaction) {
              _playSound('icon_pick.mp3');
              widget.onReactionSelected(reaction);
              _hideOverlay();
            },
            onHoverChange: () {
              _playSound('icon_focus.mp3');
            },
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _playSound('box_down.mp3');
      _overlayEntry?.remove();
      _overlayEntry = null;
      _dragPositionNotifier.value = null;
    }
  }

  final GlobalKey<_ReactionPickerOverlayState> _pickerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsRow(),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                key: _likeButtonKey,
                onTap: widget.onLikeTap,
                onLongPressStart: (details) {
                  _showReactionPicker();
                  _dragPositionNotifier.value = details.globalPosition;
                },
                onLongPressMoveUpdate: (details) {
                  _dragPositionNotifier.value = details.globalPosition;
                },
                onLongPressEnd: (details) {
                  final selected =
                      _pickerKey.currentState?.selectCurrent() ?? false;
                  if (selected) {
                    _hideOverlay();
                  }
                },
                onLongPressUp: () {
                  final selected =
                      _pickerKey.currentState?.selectCurrent() ?? false;
                  if (selected) {
                    _hideOverlay();
                  }
                },
                child: _SocialButton(
                  lottieAsset: _getReactionLottieAsset(),
                  iconData: _getReactionIconData(),
                  label: _getReactionLabel(),
                  color: _getReactionColor(),
                ),
              ),
              GestureDetector(
                onTap: widget.onCommentTap,
                child: const _SocialButton(
                  iconData: Icons.chat_bubble_outline,
                  label: 'Comentar',
                ),
              ),
              GestureDetector(
                onTap: widget.onShareTap,
                child: const _SocialButton(
                  iconData: Icons.share_outlined,
                  label: 'Compartir',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    // Don't show if nothing to show
    if (widget.currentReaction == null &&
        widget.commentsCount == 0 &&
        widget.sharesCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Left side: Reaction icons + text
          if (widget.currentReaction != null) ...[
            _buildReactionIcon(widget.currentReaction!),
            const SizedBox(width: 4),
            Text(
              'Tú',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ] else
            // Example placeholder if no reaction but we want to show something?
            // User said "ni veo reacciones de ejemplo".
            // Let's show a generic like icon if there are "other" likes hypothetically,
            // but we don't have a "totalLikes" prop passed in effectively aside from current.
            // Let's rely on the fact the user sees "Tú" when they react.
            // If they want fake stats, we can add them, but cleaner to just show what we have.
            const SizedBox.shrink(),

          const Spacer(),

          // Right side: Comments & Shares
          if (widget.commentsCount > 0)
            Text(
              '${widget.commentsCount} comentarios',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          if (widget.commentsCount > 0 && widget.sharesCount > 0)
            Text(
              ' • ',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          if (widget.sharesCount > 0)
            Text(
              '${widget.sharesCount} veces compartido',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildReactionIcon(ReactionType type) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: type.color,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          type.emoji,
          style: const TextStyle(fontSize: 8),
        ),
      ),
    );
  }

  IconData? _getReactionIconData() {
    if (widget.currentReaction == null) return Icons.thumb_up_outlined;
    return null;
  }

  String? _getReactionLottieAsset() {
    // If selected, show the lottie (maybe static or playing once)
    return widget.currentReaction?.lottieAsset;
  }

  String _getReactionLabel() {
    return widget.currentReaction?.label ?? 'Me gusta';
  }

  Color _getReactionColor() {
    return widget.currentReaction?.color ?? Colors.grey[600]!;
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? iconData;
  final String? lottieAsset;
  final String label;
  final Color color;

  const _SocialButton({
    this.iconData,
    this.lottieAsset,
    required this.label,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          if (lottieAsset != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Lottie.asset(
                lottieAsset!,
                package: 'flutter_facebook_reactions',
                width: 24,
                height: 24,
                repeat: false,
              ),
            )
          else if (iconData != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(iconData, color: color, size: 20),
            ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionPickerOverlay extends StatefulWidget {
  final Offset anchorPosition;
  final ValueNotifier<Offset?> dragPositionNotifier;
  final ValueChanged<ReactionType> onReactionSelected;
  final VoidCallback onHoverChange;

  const _ReactionPickerOverlay({
    super.key,
    required this.anchorPosition,
    required this.dragPositionNotifier,
    required this.onReactionSelected,
    required this.onHoverChange,
  });

  @override
  State<_ReactionPickerOverlay> createState() => _ReactionPickerOverlayState();
}

class _ReactionPickerOverlayState extends State<_ReactionPickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _hoverIndex;

  static const double _itemWidth = 48.0;
  static const double _padding = 8.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();

    widget.dragPositionNotifier.addListener(_onDragUpdate);
  }

  @override
  void dispose() {
    widget.dragPositionNotifier.removeListener(_onDragUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate() {
    final globalPos = widget.dragPositionNotifier.value;
    if (globalPos == null) return;

    final pickerWidth =
        (ReactionType.values.length * _itemWidth) + (_padding * 2);

    // Calculate basic left position
    // We want the picker centered above the button if possible
    // But constrained to screen
    // The anchorPosition is the top-left of the button
    // It's passed as: Offset(buttonPosition.dx, buttonPosition.dy - 60)

    // Re-calculate layout for logic
    final screenWidth = MediaQuery.of(context).size.width;
    const margin = 16.0;

    double left = widget.anchorPosition.dx -
        (pickerWidth / 2) +
        20; // +20 is roughly half button width

    if (left < margin) left = margin;
    if (left + pickerWidth > screenWidth - margin) {
      left = screenWidth - pickerWidth - margin;
    }

    final pickerLeft = left;
    final pickerTop = widget.anchorPosition.dy;

    if (globalPos.dy < pickerTop - 50 || globalPos.dy > pickerTop + 100) {
      if (_hoverIndex != null) {
        setState(() => _hoverIndex = null);
      }
      return;
    }

    final localDx = globalPos.dx - pickerLeft;
    int newIndex = -1;
    if (localDx >= _padding && localDx <= pickerWidth - _padding) {
      newIndex = ((localDx - _padding) / _itemWidth).floor();
    }

    if (newIndex >= 0 && newIndex < ReactionType.values.length) {
      if (_hoverIndex != newIndex) {
        HapticFeedback.selectionClick();
        widget.onHoverChange();
        setState(() => _hoverIndex = newIndex);
      }
    } else {
      if (_hoverIndex != null) {
        setState(() => _hoverIndex = null);
      }
    }
  }

  bool selectCurrent() {
    if (_hoverIndex != null &&
        _hoverIndex! >= 0 &&
        _hoverIndex! < ReactionType.values.length) {
      widget.onReactionSelected(ReactionType.values[_hoverIndex!]);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final pickerWidth =
        (ReactionType.values.length * _itemWidth) + (_padding * 2);

    final screenWidth = MediaQuery.of(context).size.width;
    const margin = 16.0;

    // Center initially relative to button (anchor.dx)
    // anchor.dx is the button's left edge.
    // Button is ~44px wide?
    // Let's assume anchorPosition includes the offset to center.
    // The previous code did `widget.anchorPosition.dx - (pickerWidth / 2) + 30`.
    // Let's make it robust.

    double left = widget.anchorPosition.dx - (pickerWidth / 2) + 20;

    if (left < margin) left = margin;
    if (left + pickerWidth > screenWidth - margin) {
      left = screenWidth - pickerWidth - margin;
    }

    return Positioned(
      left: left,
      top: widget.anchorPosition.dy,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 60,
          width: pickerWidth,
          padding: const EdgeInsets.symmetric(horizontal: _padding),
          decoration: BoxDecoration(
            color: Colors.grey[850]!.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(ReactionType.values.length, (index) {
              final reaction = ReactionType.values[index];
              final isHovered = _hoverIndex == index;

              return GestureDetector(
                onTapDown: (_) {
                  HapticFeedback.selectionClick();
                  widget.onHoverChange();
                  setState(() => _hoverIndex = index);
                },
                onTapUp: (_) {
                  if (_hoverIndex == index) {
                    widget.onReactionSelected(reaction);
                  }
                },
                child: AnimatedScale(
                  scale: isHovered ? 2.0 : 1.0, // Scale up Lottie comfortably
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.fastOutSlowIn,
                  child: Transform.translate(
                    offset: isHovered ? const Offset(0, -15) : Offset.zero,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Lottie.asset(
                        reaction.lottieAsset,
                        package: 'flutter_facebook_reactions',
                        animate: true, // Always animate in picker
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
