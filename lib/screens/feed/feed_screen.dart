import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/screens/feed/widgets/feed_item_widget.dart';
import 'package:casinoloyalty_flutter/screens/coyhaique/coyhaique_shell.dart';
import 'package:casinoloyalty_flutter/widgets/animated_bell.dart';
import 'package:casinoloyalty_flutter/widgets/notifications_modal.dart';
import 'package:shimmer/shimmer.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  int _focusedIndex = 0;
  bool _isScreenVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      ref.read(feedProvider.notifier).loadPosts(casinoId: user.favoriteCasinoId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          
          // Media Skeleton (Main Content)
          Expanded(
            child: Container(
              color: Colors.white,
            ),
          ),
          
          // Footer Skeleton
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(width: 50, height: 24, color: Colors.white),
                    const SizedBox(width: 24),
                    Container(width: 50, height: 24, color: Colors.white),
                    const SizedBox(width: 24),
                    Container(width: 50, height: 24, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 16),
                Container(width: double.infinity, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 200, height: 14, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List posts, String? favoriteCasinoId) {
    final notifier = ref.read(feedProvider.notifier);

    // Mientras no haya datos cargados (ni en caché ni en red) → Skeleton Loader
    if (!notifier.hasLoaded) {
      return _buildSkeleton();
    }

    // Firestore respondió pero no hay publicaciones reales
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.feed_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '¡Pronto novedades!',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Estamos preparando cosas increíbles para ti.',
              style: TextStyle(color: Colors.white38, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Hay publicaciones → feed normal
    return VisibilityDetector(
      key: const Key('feed-screen-visibility'),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction > 0;
        if (_isScreenVisible != isVisible && mounted) {
          setState(() => _isScreenVisible = isVisible);
        }
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: 10000,
        onPageChanged: (index) {
          if (mounted) setState(() => _focusedIndex = index);
          final actualIndex = index % posts.length;
          if (actualIndex >= posts.length - 3) {
            ref.read(feedProvider.notifier).loadPosts(
                  casinoId: favoriteCasinoId,
                  isRefresh: false,
                );
          }
        },
        itemBuilder: (context, index) {
          final postIndex = index % posts.length;
          return FeedItemWidget(
            post: posts[postIndex],
            isVisible: index == _focusedIndex && _isScreenVisible,
            shouldPreload:
                (index == _focusedIndex + 1 || index == _focusedIndex + 2) &&
                    _isScreenVisible,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(feedProvider);
    final user = ref.watch(userProvider);

    ref.listen(userProvider.select((u) => u.favoriteCasinoId), (prev, next) {
      if (prev != next) {
        ref.read(feedProvider.notifier).loadPosts(casinoId: next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Feed Body
          _buildBody(posts, user.favoriteCasinoId),

          // 2. Floating Top Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 56,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.menu_rounded, 
                      color: Colors.white, 
                      size: 28,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(1, 1))],
                    ),
                    onPressed: () => CoyhaiqueShell.openDrawer(),
                    tooltip: 'Menú & Perfil',
                  ),
                  const Text(
                    'DREAMS SOCIAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 16,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(1.0, 1.0)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const AnimatedBell(color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const NotificationsModal(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
