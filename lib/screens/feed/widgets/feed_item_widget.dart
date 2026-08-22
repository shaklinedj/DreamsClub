// ignore_for_file: unused_element, unused_field, unused_local_variable
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';
import 'package:lottie/lottie.dart';
import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:casinoloyalty_flutter/screens/feed/widgets/comments_modal.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/feed_media_prefetch_service.dart';
import 'package:casinoloyalty_flutter/services/feed_media_cache_manager.dart';
import 'package:casinoloyalty_flutter/services/sound_service.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isHeartAnimating = false;

  // Reaction picker overlay
  final GlobalKey _likeButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final ValueNotifier<Offset?> _dragPositionNotifier = ValueNotifier(null);
  final GlobalKey<_ReactionPickerOverlayState> _pickerKey = GlobalKey();

  String get _effectiveUserId {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) return authUid;
    final user = ref.read(userProvider);
    return user.email.isNotEmpty ? user.email : user.name;
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();

    final user = ref.read(userProvider);
    final userId = _effectiveUserId;

    if (widget.post.reactionType == null) {
      ref.read(feedProvider.notifier).setReaction(
            widget.post.id,
            ReactionType.like,
            userId: userId,
            userName: user.name,
          );
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
      if (_checkIsYoutube(widget.post.mediaUrl)) {
        _isYoutube = true;
        _initializeYoutube();
      } else {
        _initializeVideo();
      }
    }
  }

  @override
  void didUpdateWidget(FeedItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle Video Logic
    if (widget.post.mediaType == FeedMediaType.video) {
      final isYt = _checkIsYoutube(widget.post.mediaUrl);
      if (isYt) {
        _isYoutube = true;
        if (widget.isVisible) {
          if (_youtubeController == null) {
            _initializeYoutube();
          } else {
            _youtubeController?.playVideo();
          }
        } else {
          _youtubeController?.pauseVideo();
        }
      } else {
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
    }

    // Handle Preload Logic (Dynamic)
    if (widget.shouldPreload && !oldWidget.shouldPreload) {
      FeedMediaPrefetchService.prefetchPost(widget.post);
    }
  }

  String _formatMediaUrl(String url, {bool isVideo = false}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    String? fileId;
    if (trimmed.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('drive.google.com/open?id=')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('drive.google.com/uc')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('googleusercontent.com/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    }

    if (fileId != null && fileId.isNotEmpty) {
      if (isVideo) {
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
    return trimmed;
  }

  Future<void> _initializeVideo() async {
    if (!mounted) return;

    // STOP: Do not initialize if not visible (Double check)
    if (!widget.isVisible) return;

    try {
      if (_videoPlayerController != null) return; // Already initialized

      final url = _formatMediaUrl(widget.post.mediaUrl, isVideo: true);
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

  bool _checkIsYoutube(String url) {
    final trimmed = url.trim().toLowerCase();
    return trimmed.contains('youtube.com') || trimmed.contains('youtu.be');
  }

  String? _extractYoutubeId(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    // 1. Precise regex matching exact 11-character YouTube video IDs
    final regExp = RegExp(
      r'(?:v=|\/embed\/|\/v\/|\/shorts\/|\/live\/|youtu\.be\/)([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    if (match != null && match.group(1) != null) {
      return match.group(1);
    }

    // 2. Fallback using YoutubePlayerController.convertUrlToId and cleaning parameters
    var id = YoutubePlayerController.convertUrlToId(trimmed);
    if (id != null && id.isNotEmpty) {
      if (id.contains('&')) id = id.split('&').first;
      if (id.contains('?')) id = id.split('?').first;
      if (id.length == 11) return id;
    }

    return null;
  }

  void _initializeYoutube() {
    try {
      final videoId = _extractYoutubeId(widget.post.mediaUrl);
      if (videoId == null) {
        debugPrint('❌ Could not extract YouTube video ID from: ${widget.post.mediaUrl}');
        if (mounted) setState(() => _hasError = true);
        return;
      }

      debugPrint('🎬 Initializing Youtube Player v10.0.1 for videoId: $videoId');

      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          loop: true,
          enableJavaScript: true,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint('❌ Error initializing youtube: $e');
      AppLogger.error('Youtube initialization error', e, stack);
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
              final user = ref.read(userProvider);
              final userId = _effectiveUserId;
              ref.read(feedProvider.notifier).setReaction(
                    widget.post.id,
                    reaction,
                    userId: userId,
                    userName: user.name,
                  );
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

  void _showFullScreenImage(BuildContext context) {
    if (widget.post.mediaUrl.isEmpty) return;
    final formattedUrl = _formatMediaUrl(widget.post.mediaUrl);

    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      barrierDismissible: true,
      pageBuilder: (BuildContext context, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: formattedUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isShorts = widget.post.mediaUrl.toLowerCase().contains('/shorts/');
    final playerAspectRatio = isShorts ? (9 / 16) : (16 / 9);
    final targetWidth = MediaQuery.of(context).size.width * (isShorts ? 0.75 : 0.95);
    final targetHeight = targetWidth / (isShorts ? (9 / 16) : playerAspectRatio);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Media Content
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            onTap: () {
              if (widget.post.mediaType == FeedMediaType.image) {
                _showFullScreenImage(context);
              } else if (widget.post.mediaType == FeedMediaType.video) {
                if (_isYoutube && _youtubeController != null) {
                  final state = _youtubeController!.value.playerState;
                  if (state == PlayerState.playing) {
                    _youtubeController!.pauseVideo();
                  } else {
                    _youtubeController!.playVideo();
                  }
                } else if (_videoPlayerController != null) {
                  if (_videoPlayerController!.value.isPlaying) {
                    _videoPlayerController!.pause();
                  } else {
                    _videoPlayerController!.play();
                  }
                }
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaContent(targetWidth, targetHeight),
                if (_isYoutube)
                  Center(
                    child: SizedBox(
                      width: targetWidth,
                      height: targetHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_youtubeController != null) {
                            final state = _youtubeController!.value.playerState;
                            if (state == PlayerState.playing) {
                              _youtubeController!.pauseVideo();
                            } else {
                              _youtubeController!.playVideo();
                            }
                          }
                        },
                        onDoubleTap: _handleDoubleTap,
                      ),
                    ),
                  ),
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

          // 2. Bottom shadow gradient for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top shadow gradient for top buttons readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),

          // 4. Overlays (Post Info & Description on bottom-left)
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: _buildPostInfoOverlay(),
          ),

          // 5. Actions Sidebar (Right aligned)
          Positioned(
            right: 12,
            bottom: 40,
            child: _buildActionsSidebar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInfoOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.post.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            shadows: [
              Shadow(blurRadius: 4.0, color: Colors.black45, offset: Offset(1.0, 1.0)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.post.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            height: 1.3,
            shadows: const [
              Shadow(blurRadius: 4.0, color: Colors.black45, offset: Offset(1.0, 1.0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSidebar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like Button
        _buildSidebarReactionButton(),
        const SizedBox(height: 16),

        // Comments Button
        _buildSidebarButton(
          icon: Icons.chat_bubble_rounded,
          label: '${widget.post.commentsCount}',
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: CommentsModal(postId: widget.post.id),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Share Button
        _buildSidebarButton(
          icon: Icons.share_rounded,
          label: '${widget.post.sharesCount}',
          onTap: () {
            ref.read(feedProvider.notifier).incrementShare(widget.post.id);
            ShareHelper.sharePost(widget.post.id, widget.post.title, widget.post.description);
          },
        ),
        const SizedBox(height: 16),

        // Link Button (Ver más)
        if (widget.post.linkUrl != null && widget.post.linkUrl!.isNotEmpty) ...[
          _buildSidebarButton(
            icon: Icons.link_rounded,
            label: 'Ver',
            onTap: () async {
              final url = Uri.parse(widget.post.linkUrl!);
              try {
                await launchUrl(url, mode: LaunchMode.inAppBrowserView);
              } catch (_) {
                try {
                  await launchUrl(url, mode: LaunchMode.platformDefault);
                } catch (_) {}
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Delete Button (Admin)
        if (ref.watch(userProvider).isAdmin) ...[
          _buildSidebarButton(
            icon: Icons.delete_outline_rounded,
            label: 'Borrar',
            iconColor: Colors.redAccent,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Borrar publicación'),
                  content: const Text('¿Estás seguro de que deseas eliminar esta publicación?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(feedProvider.notifier).deletePost(widget.post.id);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarReactionButton() {
    final isLiked = widget.post.reactionType != null;

    return GestureDetector(
      key: _likeButtonKey,
      onTap: () {
        final user = ref.read(userProvider);
        final userId = _effectiveUserId;
        ref.read(feedProvider.notifier).toggleLike(
              widget.post.id,
              userId: userId,
              userName: user.name,
            );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.favorite_rounded,
              color: isLiked ? Colors.red : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.post.reactionsCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildMediaContent(double targetWidth, double targetHeight) {
    if (widget.post.mediaType == FeedMediaType.video) {
      if (_isYoutube && _youtubeController != null) {
        final isShorts = widget.post.mediaUrl.toLowerCase().contains('/shorts/');
        final playerAspectRatio = isShorts ? (9 / 16) : (16 / 9);

        return ClipRect(
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.999,
              child: Center(
                child: SizedBox(
                  width: targetWidth,
                  height: targetHeight,
                  child: IgnorePointer(
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                      aspectRatio: isShorts ? (9 / 16) : playerAspectRatio,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Using standard VideoPlayer
      if (_isInitialized &&
          _videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized) {
        final videoSize = _videoPlayerController!.value.size;
        final aspectRatio = _videoPlayerController!.value.aspectRatio;
        final isVertical = aspectRatio < 1.0; // Vertical Video / Reels / Shorts

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ambient blur backdrop
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: VideoPlayer(_videoPlayerController!),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              // Foreground video: Fill screen for vertical videos (Reels/Shorts), contain for landscape
              Center(
                child: isVertical
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: videoSize.width,
                          height: videoSize.height,
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
              ),
            ],
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
      final formattedUrl = _formatMediaUrl(widget.post.mediaUrl);
      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Blurred background image matching colors
          CachedNetworkImage(
            imageUrl: formattedUrl,
            fit: BoxFit.cover,
            memCacheWidth: 360,
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF0D0B18),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          // 2. Full crisp image fitted without cropping
          Center(
            child: CachedNetworkImage(
              imageUrl: formattedUrl,
              fit: BoxFit.contain,
              memCacheWidth: 1080,
              maxWidthDiskCache: 1080,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              ),
              errorWidget: (context, url, error) {
                debugPrint('Error loading image ($url): $error');
                return Center(
                  child: Image.asset(
                    'assets/images/coyhaique.jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.casino,
                          color: Color(0xFFD4AF37), size: 60),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }





  @override
  void dispose() {
    // CRITICAL: Clean up video player to prevent memory leaks
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;

    _youtubeController?.close();
    _youtubeController = null;

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
      final selectedReaction = ReactionType.values[_hoverIndex!];
      _hoverIndex = null;
      widget.onReactionSelected(selectedReaction);
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
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onReactionSelected(reaction);
                },
                onTapDown: (_) {
                  HapticFeedback.selectionClick();
                  widget.onHoverChange();
                  setState(() => _hoverIndex = index);
                },
                onTapCancel: () {
                  setState(() => _hoverIndex = null);
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






