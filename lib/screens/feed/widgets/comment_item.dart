import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:casinoloyalty_flutter/models/comment_model.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class CommentItem extends ConsumerStatefulWidget {
  final Comment comment;
  final bool isReply;
  final String? parentId;
  final Function(String userName, String commentId) onReply;
  final String collectionPath;
  final String postId;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onReply,
    required this.collectionPath,
    required this.postId,
    this.isReply = false,
    this.parentId,
  });

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  // Local state to manage likes instantly without rebuilding parent list
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _isLiked = widget.comment.likedBy.contains(user.email);
    _likesCount = widget.comment.likesCount;
  }

  @override
  void didUpdateWidget(covariant CommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external data changes significantly (e.g. real update from stream), sync up
    // But be careful not to overwrite optimistic updates immediately if stream is laggy
    // For now, simpler approach: if the widget is rebuilt with new data, respect it roughly
    // BUT since we want to avoid jump, we trust our local logic for user interaction.
    if (oldWidget.comment.likesCount != widget.comment.likesCount) {
      _likesCount = widget.comment.likesCount;
    }
    if (oldWidget.comment.likedBy != widget.comment.likedBy) {
      final user = ref.read(userProvider);
      _isLiked = widget.comment.likedBy.contains(user.email);
    }
  }

  void _toggleLike() {
    final user = ref.read(userProvider);
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount--;
      } else {
        _isLiked = true;
        _likesCount++;
      }
    });

    ref.read(feedProvider.notifier).toggleCommentLike(
          widget.postId,
          widget.comment.id,
          user.email,
          collectionPath: widget.collectionPath,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: widget.isReply ? 14 : 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: widget.comment.userAvatar != null &&
                    widget.comment.userAvatar!.isNotEmpty
                ? (widget.comment.userAvatar!.startsWith('http')
                    ? NetworkImage(widget.comment.userAvatar!)
                    : AssetImage(widget.comment.userAvatar!) as ImageProvider)
                : null,
            child: (widget.comment.userAvatar == null ||
                    widget.comment.userAvatar!.isEmpty)
                ? Text(widget.comment.userName[0].toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isReply ? 10 : 14))
                : null,
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.comment.userName} ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: widget.comment.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Metadata Row: Time, Likes, Reply Button
                Row(
                  children: [
                    Text(
                      timeago.format(widget.comment.createdAt,
                          locale: 'es_short'),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    if (_likesCount > 0) ...[
                      Text(
                        '$_likesCount me gusta',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                    ],
                    GestureDetector(
                      onTap: () {
                        final targetId = widget.isReply
                            ? widget.parentId!
                            : widget.comment.id;
                        widget.onReply(widget.comment.userName, targetId);
                      },
                      child: Text(
                        'Responder',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Like Heart (Right Aligned)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: GestureDetector(
              onTap: _toggleLike,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: _isLiked ? Colors.red : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
