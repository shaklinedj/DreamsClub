import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/screens/feed/widgets/feed_item_widget.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

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
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      ref
          .read(feedProvider.notifier)
          .loadPosts(casinoId: user.favoriteCasinoId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(feedProvider);
    final user = ref.watch(userProvider);

    // Reload posts if favorite casino changes
    ref.listen(userProvider.select((u) => u.favoriteCasinoId), (prev, next) {
      if (prev != next) {
        ref.read(feedProvider.notifier).loadPosts(casinoId: next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, // Immersive feel
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: user.isAdmin
            ? IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 32),
                onPressed: () => context.push('/upload-post'),
                tooltip: 'Nuevo Post',
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: posts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.kPrimaryBlue))
          : VisibilityDetector(
              key: const Key('feed-screen-visibility'),
              onVisibilityChanged: (info) {
                final isVisible = info.visibleFraction > 0;
                if (_isScreenVisible != isVisible) {
                  setState(() {
                    _isScreenVisible = isVisible;
                  });
                }
              },
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: posts.isNotEmpty ? 10000 : 0,
                onPageChanged: (index) {
                  setState(() {
                    _focusedIndex = index;
                  });
                  if (posts.isEmpty) {
                    return;
                  }
                  // Trigger pagination when reaching near end
                  final actualIndex = index % posts.length;
                  if (actualIndex >= posts.length - 3) {
                    ref.read(feedProvider.notifier).loadPosts(
                          casinoId: user.favoriteCasinoId,
                          isRefresh: false,
                        );
                  }
                },
                itemBuilder: (context, index) {
                  if (posts.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final postIndex = index % posts.length;
                  return FeedItemWidget(
                    post: posts[postIndex],
                    isVisible: index == _focusedIndex && _isScreenVisible,
                    shouldPreload: (index == _focusedIndex + 1 ||
                            index == _focusedIndex + 2) &&
                        _isScreenVisible,
                  );
                },
              ),
            ),
    );
  }
}
