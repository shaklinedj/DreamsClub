import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:casinoloyalty_flutter/providers/feed_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/models/comment_model.dart';
import 'package:casinoloyalty_flutter/screens/feed/widgets/comment_item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

ImageProvider _resolveAvatar(String? path) {
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
      final userId = user.email.isEmpty ? 'anonymous' : user.email;

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

  void _showStickerPickerModal() {
    final gifs = [
      {'name': 'Fiesta Confeti', 'url': 'https://media.giphy.com/media/26tOZbfHHHJVjB3Ww/giphy.gif'},
      {'name': 'Ganador Jackpot', 'url': 'https://media.giphy.com/media/l2JdZOg7N5l1s8s0M/giphy.gif'},
      {'name': 'Fuego & Celebración', 'url': 'https://media.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif'},
      {'name': 'Fichas Casino', 'url': 'https://media.giphy.com/media/l0HlHJGHe3yAMhdQY/giphy.gif'},
      {'name': 'Gato Bailando', 'url': 'https://media.giphy.com/media/vFKqnCdLPNOKc/giphy.gif'},
      {'name': 'Aplausos', 'url': 'https://media.giphy.com/media/111ebonMs90YLu/giphy.gif'},
      {'name': 'Slots Win', 'url': 'https://media.giphy.com/media/3o6Zt8qDiPE2dRy5tC/giphy.gif'},
      {'name': 'Ruleta Dinero', 'url': 'https://media.giphy.com/media/l41lFw057l4e7MQdG/giphy.gif'},
      {'name': 'Cartas Poker', 'url': 'https://media.giphy.com/media/26ufcVAp3AiJJsrIs/giphy.gif'},
      {'name': 'Celebración Woohoo', 'url': 'https://media.giphy.com/media/lz67zcX2C39GURpRU1/giphy.gif'},
      {'name': 'Minions Fiesta', 'url': 'https://media.giphy.com/media/MOWPkhRAUbR7i/giphy.gif'},
      {'name': 'Dinero Volando', 'url': 'https://media.giphy.com/media/h0MTqLyvgG0Wk/giphy.gif'},
      {'name': 'Gato con Lentes', 'url': 'https://media.giphy.com/media/C9x8gX5j5q227MI4mc/giphy.gif'},
      {'name': 'Éxito Baile', 'url': 'https://media.giphy.com/media/12B39IawiNSDMQ/giphy.gif'},
      {'name': 'Brindis Copas', 'url': 'https://media.giphy.com/media/BPR6NwBUWoO3u/giphy.gif'},
      {'name': 'Mate Patagónico', 'url': 'https://media.giphy.com/media/M33UV4F9i2TR6/giphy.gif'},
      {'name': 'Nieve Patagonia', 'url': 'https://media.giphy.com/media/3o6Zt481isntZOnd60/giphy.gif'},
      {'name': 'Felicidad Perro', 'url': 'https://media.giphy.com/media/xT0xezQGU5xCDJuCPe/giphy.gif'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2230),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: 340,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with Gallery Pick Option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enviar Sticker o GIF',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickCustomStickerFromGallery();
                  },
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: const Text('Galería / Sticker Propio', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: gifs.length,
                itemBuilder: (context, index) {
                  final item = gifs[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendStickerComment(item['url']!);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item['url']!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.amber)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadAttachment(Uint8List bytes, String mimeType) async {
    try {
      final extension = mimeType.split('/').last;
      final fileName = 'comment_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}.$extension';
      final refStorage = FirebaseStorage.instance
          .ref()
          .child('comment_attachments')
          .child(fileName);

      final uploadTask = refStorage.putData(
        bytes,
        SettableMetadata(contentType: mimeType),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('Error uploading comment attachment to Storage', e);
      return null;
    }
  }

  Future<void> _pickCustomStickerFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() {
          _isSubmitting = true;
        });
        final bytes = await file.readAsBytes();
        final mimeType = file.mimeType ?? 'image/jpeg';

        final url = await _uploadAttachment(bytes, mimeType);
        if (url != null) {
          _sendStickerComment(url);
        } else {
          setState(() {
            _isSubmitting = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al subir imagen a Firebase Storage')),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error picking custom sticker from gallery', e);
    }
  }

  Future<void> _sendStickerComment(String stickerOrGifUrl) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ref.read(userProvider);
      final userId = user.email.isEmpty ? 'anonymous' : user.email;

      await ref.read(feedProvider.notifier).addComment(
            widget.postId,
            stickerOrGifUrl,
            userId,
            user.name,
            user.profileImageUrl,
            collectionPath: widget.collectionPath,
            replyToUserName: _replyingToUserName,
            parentId: _replyingToCommentId,
          );

      setState(() {
        _replyingToUserName = null;
        _replyingToCommentId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar sticker: $e')),
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
                        backgroundImage: _resolveAvatar(user.profileImageUrl),
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
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.sticky_note_2_rounded, color: Colors.amber, size: 22),
                                onPressed: _showStickerPickerModal,
                                tooltip: 'Enviar Sticker o GIF',
                              ),
                              _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : IconButton(
                                      icon: const Icon(Icons.send, color: Colors.blue),
                                      onPressed: _submitComment,
                                    ),
                            ],
                          ),
                        ),
                        onSubmitted: (_) => _submitComment(),
                        enabled: !_isSubmitting,
                        contentInsertionConfiguration: ContentInsertionConfiguration(
                          allowedMimeTypes: const [
                            'image/gif',
                            'image/png',
                            'image/webp',
                            'image/jpeg',
                          ],
                          onContentInserted: (KeyboardInsertedContent content) async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (content.data != null) {
                              setState(() {
                                _isSubmitting = true;
                              });
                              final url = await _uploadAttachment(content.data!, content.mimeType);
                              if (url != null) {
                                _sendStickerComment(url);
                              } else {
                                setState(() {
                                  _isSubmitting = false;
                                });
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Error al procesar el archivo del teclado')),
                                );
                              }
                            } else if (content.uri.isNotEmpty) {
                              if (content.uri.startsWith('http')) {
                                _sendStickerComment(content.uri);
                              } else {
                                // For content:// paths, inform the user they cannot be uploaded directly
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Formato de teclado local no soportado')),
                                );
                              }
                            }
                          },
                        ),
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
