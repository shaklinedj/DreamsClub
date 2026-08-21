import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:casinoloyalty_flutter/models/comment_model.dart';
import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

ImageProvider _getAvatarProvider(String? path) {
  if (path == null || path.isEmpty) {
    return const AssetImage('assets/images/logo-dreams.png');
  }
  if (path.startsWith('data:image')) {
    try {
      final commaIndex = path.indexOf(',');
      if (commaIndex != -1) {
        final base64Data = path.substring(commaIndex + 1);
        return MemoryImage(base64Decode(base64Data));
      }
    } catch (_) {}
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  try {
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {}
  return const AssetImage('assets/images/logo-dreams.png');
}

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
    final currentUser = ref.watch(userProvider);
    final isOwnComment = widget.comment.userId == currentUser.email ||
        widget.comment.userId == currentUser.name ||
        widget.comment.userName == currentUser.name;
    final effectiveAvatar = (isOwnComment && currentUser.profileImageUrl.isNotEmpty)
        ? currentUser.profileImageUrl
        : widget.comment.userAvatar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: widget.isReply ? 14 : 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: _getAvatarProvider(effectiveAvatar),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isStickerOrGif(widget.comment.text)) ...[
                  Text(
                    '${widget.comment.userName}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStickerOrGif(widget.comment.text),
                  ),
                ] else ...[
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
                ],
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
                    if (isOwnComment) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar comentario'),
                              content: const Text('¿Seguro que quieres eliminar este comentario?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(feedProvider.notifier).deleteComment(
                                      widget.postId,
                                      widget.comment.id,
                                      collectionPath: widget.collectionPath,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Eliminar',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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

  bool _isStickerOrGif(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('[STICKER]') || trimmed.startsWith('[GIF]')) return true;
    if (trimmed.startsWith('assets/images/stickers/')) return true;
    if (trimmed.startsWith('data:image/') || trimmed.startsWith('data:application/')) return true;
    if ((trimmed.startsWith('http://') || trimmed.startsWith('https://')) &&
        (trimmed.contains('.gif') || trimmed.contains('.png') || trimmed.contains('.webp') || trimmed.contains('media.giphy.com') || trimmed.contains('tenor.com'))) {
      return true;
    }
    return false;
  }

  Widget _buildStickerOrGif(String text) {
    String cleanUrl = text.replaceAll('[STICKER]', '').replaceAll('[GIF]', '').trim();

    if (cleanUrl.startsWith('data:image/') || cleanUrl.startsWith('data:application/')) {
      try {
        final commaIndex = cleanUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = cleanUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white30),
          );
        }
      } catch (_) {}
      return const Icon(Icons.broken_image, color: Colors.white30);
    }

    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white30),
      );
    }

    return Image.network(
      cleanUrl,
      width: 140,
      height: 140,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 100, height: 100,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
        );
      },
      errorBuilder: (context, url, error) => Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white10,
        child: const Icon(Icons.broken_image, color: Colors.white30),
      ),
    );
  }
}
