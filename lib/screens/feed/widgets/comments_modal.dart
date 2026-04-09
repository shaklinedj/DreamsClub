import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/models/comment_model.dart';
import 'package:casinoloyalty_flutter/screens/feed/widgets/comment_item.dart';

class CommentsModal extends ConsumerStatefulWidget {
  final String postId;
  final String collectionPath;

  const CommentsModal(
      {super.key, required this.postId, this.collectionPath = 'posts'});

  @override
  ConsumerState<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends ConsumerState<CommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _replyingToUserName;
  String? _replyingToCommentId; // Parent ID for threading

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ref.read(userProvider);
      final userId = user.email;

      await ref.read(feedProvider.notifier).addComment(
            widget.postId,
            text,
            userId,
            user.name,
            user.profileImageUrl,
            collectionPath: widget.collectionPath,
            replyToUserName: _replyingToUserName,
            parentId: _replyingToCommentId,
          );

      _commentController.clear();
      setState(() {
        _replyingToUserName = null;
        _replyingToCommentId = null;
      });
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleReply(String userName, String commentId) {
    setState(() {
      _replyingToUserName = userName;
      _replyingToCommentId = commentId;
    });
    FocusScope.of(context).requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToUserName = null;
      _replyingToCommentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commentsStream = FirebaseFirestore.instance
        .collection(widget.collectionPath)
        .doc(widget.postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Comentarios',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Sé el primero en comentar',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                // Group comments: Parents and Replies
                final allComments =
                    docs.map((d) => Comment.fromFirestore(d)).toList();
                final parentComments =
                    allComments.where((c) => c.parentId == null).toList();

                // Map of ParentId -> List<Reply>
                final repliesMap = <String, List<Comment>>{};
                for (var c in allComments) {
                  if (c.parentId != null) {
                    repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
                  }
                }

                // Sort replies by time (oldest first usually for replies, or newest?)
                // Instagram shows newest first or "View replies". Let's stick to simple list for now.
                for (var key in repliesMap.keys) {
                  repliesMap[key]!
                      .sort((a, b) => a.createdAt.compareTo(b.createdAt));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final parent = parentComments[index];
                    final replies = repliesMap[parent.id] ?? [];
                    return _buildCommentItem(parent, replies: replies);
                  },
                );
              },
            ),
          ),

          // Reaction Bar (optional, can hide if replying)
          if (_replyingToUserName == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmojiReaction('❤️'),
                  _buildEmojiReaction('🙌'),
                  _buildEmojiReaction('🔥'),
                  _buildEmojiReaction('👏'),
                  _buildEmojiReaction('😢'),
                  _buildEmojiReaction('😍'),
                  _buildEmojiReaction('😮'),
                  _buildEmojiReaction('😂'),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
              color: Color(0xFF1E1E1E),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyingToUserName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Respondiendo a $_replyingToUserName',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Consumer(builder: (context, ref, _) {
                      final user = ref.watch(userProvider);
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: user.profileImageUrl.startsWith('http')
                            ? NetworkImage(user.profileImageUrl)
                            : AssetImage(user.profileImageUrl) as ImageProvider,
                      );
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _replyingToUserName != null
                              ? 'Responde a $_replyingToUserName...'
                              : 'Añadir un comentario...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white54),
                          ),
                          filled: true,
                          fillColor: Colors.black26,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          suffixIcon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.send,
                                      color: Colors.blue),
                                  onPressed: _submitComment,
                                ),
                        ),
                        onSubmitted: (_) => _submitComment(),
                        enabled: !_isSubmitting,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget builder for a single comment row + replies
  Widget _buildCommentItem(Comment comment,
      {List<Comment> replies = const []}) {
    return Column(
      children: [
        // Parent Comment
        CommentItem(
          comment: comment,
          onReply: _handleReply,
          collectionPath: widget.collectionPath,
          postId: widget.postId,
        ),

        // Replies
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44.0), // Indent replies
            child: Column(
              children: replies.map((reply) {
                return CommentItem(
                  comment: reply,
                  isReply: true,
                  parentId: comment.id,
                  onReply: _handleReply,
                  collectionPath: widget.collectionPath,
                  postId: widget.postId,
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmojiReaction(String emoji) {
    return GestureDetector(
      onTap: () {
        _commentController.text += emoji;
      },
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
