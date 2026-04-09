import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';
import 'package:lottie/lottie.dart';
import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:casinoloyalty_flutter/screens/feed/widgets/comments_modal.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/feed_media_prefetch_service.dart';
import 'package:casinoloyalty_flutter/services/feed_media_cache_manager.dart';
import 'package:casinoloyalty_flutter/services/sound_service.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:casinoloyalty_flutter/utils/share_helper.dart';

class FeedItemWidget extends ConsumerStatefulWidget {
  final FeedPost post;
  final bool isVisible;
  final bool shouldPreload;

  const FeedItemWidget({
    super.key,
    required this.post,
    required this.isVisible,
    this.shouldPreload = false,
  });

  @override
  ConsumerState<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends ConsumerState<FeedItemWidget> {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isHeartAnimating = false;

  // Reaction picker overlay
  final GlobalKey _likeButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final ValueNotifier<Offset?> _dragPositionNotifier = ValueNotifier(null);
  final GlobalKey<_ReactionPickerOverlayState> _pickerKey = GlobalKey();

  void _handleDoubleTap() {
    // Optimistic UI: Double tap always likes if not liked, or could check state
    // Instagram logic: Double tap ALWAYS triggers heart animation.
    // Use proper haptic feedback
    HapticFeedback.lightImpact();

    // Only add reaction if not already liked (or other reaction).
    // If already liked, just animate the heart locally without backend call?
    // User requested "optimistic UI".
    if (widget.post.reactionType == null) {
      ref
          .read(feedProvider.notifier)
          .setReaction(widget.post.id, ReactionType.like);
    }

    // Always animate big heart
    setState(() {
      _isHeartAnimating = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Preload if requested (Images AND Videos) - Lightweight file download only
    if (widget.shouldPreload && !widget.isVisible) {
      FeedMediaPrefetchService.prefetchPost(widget.post);
    }

    // Initialize Player only if VISIBLE
    if (widget.post.mediaType == FeedMediaType.video && widget.isVisible) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(FeedItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle Video Logic
    if (widget.post.mediaType == FeedMediaType.video) {
      if (widget.isVisible) {
        if (!_isInitialized) {
          _initializeVideo();
        } else {
          _videoPlayerController?.play();
        }
      } else {
        _videoPlayerController?.pause();
      }
    }

    // Handle Preload Logic (Dynamic)
    if (widget.shouldPreload && !oldWidget.shouldPreload) {
      FeedMediaPrefetchService.prefetchPost(widget.post);
    }
  }

  Future<void> _initializeVideo() async {
    if (!mounted) return;

    // STOP: Do not initialize if not visible (Double check)
    if (!widget.isVisible) return;

    try {
      if (_videoPlayerController != null) return; // Already initialized

      final url = widget.post.mediaUrl;
      if (url.isEmpty) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      // 1. Check if file exists in our cache manager
      final fileInfo =
          await FeedMediaCacheManager.instance.getFileFromCache(url);

      VideoPlayerController controller;

      if (fileInfo != null && await fileInfo.file.exists()) {
        debugPrint('🚀 Playing from CACHE: $url');
        controller = VideoPlayerController.file(fileInfo.file);
      } else {
        debugPrint('🌐 Playing from NETWORK (Uncached fallback): $url');
        // If not in cache, playing from network is safest fallback.
        // We do NOT trigger download here to avoid delaying playback.
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }

      _videoPlayerController = controller;

      // Initialize
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0); // Ensure sound is on

      if (!mounted) {
        controller.dispose();
        _videoPlayerController = null;
        return;
      }

      if (widget.isVisible) {
        await controller.play();
      } else {
        await controller.pause();
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e, stack) {
      debugPrint('❌ Error initializing video: $e');
      AppLogger.error('Video initialization error', e, stack);
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _showReactionPicker() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);

    SoundService.instance.playSound('box_up.mp3');
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
            anchorPosition: Offset(buttonPosition.dx, buttonPosition.dy - 70),
            dragPositionNotifier: _dragPositionNotifier,
            onReactionSelected: (reaction) {
              SoundService.instance.playSound('icon_pick.mp3');
              ref
                  .read(feedProvider.notifier)
                  .setReaction(widget.post.id, reaction);
              _hideOverlay();
            },
            onHoverChange: () {
              SoundService.instance.playSound('icon_focus.mp3');
            },
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      SoundService.instance.playSound('box_down.mp3');
      _overlayEntry?.remove();
      _overlayEntry = null;
      _dragPositionNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media Content with Double Tap
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          onTap: () {
            // Optional: Toggle enter/exit full screen or show/hide controls
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaContent(),
              // Heart Animation Overlay
              if (_isHeartAnimating)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    onEnd: () {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _isHeartAnimating = false;
                          });
                        }
                      });
                    },
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 100,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // ... (Gradient)

        // Content & Actions
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTag(),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Action Buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reaction Button with long-press picker
                  _buildReactionButton(),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.comment,
                    label: '${widget.post.commentsCount}',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            CommentsModal(postId: widget.post.id),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.share,
                    label: '${widget.post.sharesCount}', // Show shares count
                    onTap: () {
                      ref
                          .read(feedProvider.notifier)
                          .incrementShare(widget.post.id);
                      ShareHelper.sharePost(widget.post.id, widget.post.title,
                          widget.post.description);
                    },
                  ),
                  // ... loops

                  // Link button - Instagram style (only visible if linkUrl exists)
                  if (widget.post.linkUrl != null &&
                      widget.post.linkUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.link,
                      label: 'Ver más',
                      onTap: () async {
                        final url = Uri.parse(widget.post.linkUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                  // Admin-only Delete Button
                  if (ref.watch(userProvider).isAdmin) ...[
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Borrar',
                      color: Colors.redAccent,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Borrar publicación'),
                            content: const Text(
                                '¿Estás seguro de que deseas eliminar esta publicación? Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await ref
                              .read(feedProvider.notifier)
                              .deletePost(widget.post.id);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Reaction button with long-press to open picker
  Widget _buildReactionButton() {
    final reaction = widget.post.reactionType;
    final hasReaction = reaction != null;

    return GestureDetector(
      key: _likeButtonKey,
      onTap: () {
        // Toggle like on tap
        ref.read(feedProvider.notifier).toggleLike(widget.post.id);
      },
      onLongPressStart: (details) {
        _showReactionPicker();
        _dragPositionNotifier.value = details.globalPosition;
      },
      onLongPressMoveUpdate: (details) {
        _dragPositionNotifier.value = details.globalPosition;
      },
      onLongPressEnd: (details) {
        final selected = _pickerKey.currentState?.selectCurrent() ?? false;
        if (selected) {
          _hideOverlay();
        }
      },
      onLongPressUp: () {
        final selected = _pickerKey.currentState?.selectCurrent() ?? false;
        if (selected) {
          _hideOverlay();
        }
      },
      child: Column(
        children: [
          if (hasReaction)
            SizedBox(
              width: 30,
              height: 30,
              child: Lottie.asset(
                reaction.lottieAsset,
                package: 'flutter_facebook_reactions',
                repeat: false,
                fit: BoxFit.contain,
              ),
            )
          else
            const Icon(Icons.favorite_border, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            '${widget.post.likesCount}',
            style: TextStyle(
              color: hasReaction ? reaction.color : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.mediaType == FeedMediaType.video) {
      // Using standard VideoPlayer
      if (_isInitialized &&
          _videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoPlayerController!.value.size.width,
              height: _videoPlayerController!.value.size.height,
              child: VideoPlayer(_videoPlayerController!),
            ),
          ),
        );
      } else if (_hasError) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text('Error loading video',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    } else {
      if (widget.post.mediaUrl.isEmpty) {
        return const Center(
          child:
              Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
        );
      }
      return CachedNetworkImage(
        imageUrl: widget.post.mediaUrl,
        fit: BoxFit.cover,
        // Critical for memory: Resize images to screen width (approx 1080)
        // prevents loading full 12MP photos into RAM.
        memCacheWidth: 1080,
        maxWidthDiskCache: 1080,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Error loading image ($url): $error');
          return const Center(
            child: Icon(Icons.error, color: Colors.white),
          );
        },
      );
    }
  }

  Widget _buildTag() {
    Color tagColor;
    String tagText;

    switch (widget.post.postType) {
      case FeedPostType.event:
        tagColor = AppTheme.kPrimaryBlue;
        tagText = 'EVENTO';
        break;
      case FeedPostType.promotion:
        tagColor = AppTheme.kAccentRed;
        tagText = 'PROMOCIÓN';
        break;
      default:
        tagColor = Colors.grey;
        tagText = 'NOTICIA';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tagText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // CRITICAL: Clean up video player to prevent memory leaks
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;

    // Clean up overlay if open
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Clean up value notifier
    _dragPositionNotifier.dispose();

    super.dispose();
  }
}

/// Reaction picker overlay widget (embedded for feed use)
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

    final screenWidth = MediaQuery.of(context).size.width;
    const margin = 16.0;

    double left = widget.anchorPosition.dx - (pickerWidth / 2) + 20;

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
            color: Colors.grey[850]!.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
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
                  scale: isHovered ? 2.0 : 1.0,
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
                        animate: true,
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
