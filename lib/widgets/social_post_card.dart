import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';
import '../utils/share_helper.dart';

class SocialPostCard extends StatefulWidget {
  final String userName;
  final String userImage;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int initialLikes;
  final int initialComments;

  const SocialPostCard({
    super.key,
    required this.userName,
    required this.userImage,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    this.initialLikes = 0,
    this.initialComments = 0,
  });

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  late int likes;
  bool isLiked = false;
  String? selectedReaction; // 'like', 'love', 'haha', 'wow', 'sad', 'angry'
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();
  late List<_Comment> _comments;
  late List<ReactionType>
      _topReactions; // Las reacciones más populares para mostrar

  ReactionType _getReactionTypeFromString(String reaction) {
    return ReactionType.values.firstWhere(
      (e) => e.name == reaction,
      orElse: () => ReactionType.like,
    );
  }

  // Comentarios de ejemplo predefinidos
  static const List<_Comment> _sampleComments = [
    _Comment(
        name: 'María González',
        text: '¡Me encanta este lugar! 🎰',
        timeAgo: 'Hace 1h',
        avatar: '👩'),
    _Comment(
        name: 'Carlos Pérez',
        text: 'La mejor experiencia, siempre vuelvo',
        timeAgo: 'Hace 2h',
        avatar: '👨'),
    _Comment(
        name: 'Ana Martínez',
        text: '¿Alguien sabe si hay promociones hoy?',
        timeAgo: 'Hace 3h',
        avatar: '👩‍🦰'),
  ];

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
    // Agregar comentarios de ejemplo solo si hay comentarios iniciales
    _comments = widget.initialComments > 0
        ? List.from(_sampleComments.take(widget.initialComments.clamp(0, 3)))
        : [];
    // Simular reacciones variadas
    _topReactions = _getRandomReactions();
  }

  List<ReactionType> _getRandomReactions() {
    if (likes > 50) {
      return [ReactionType.like, ReactionType.love, ReactionType.haha];
    }
    if (likes > 20) {
      return [ReactionType.like, ReactionType.love];
    }
    return [ReactionType.like];
  }

  void _handleReaction(String reactionName) {
    setState(() {
      if (selectedReaction == reactionName) {
        // Toggle off
        selectedReaction = null;
        likes--;
      } else {
        if (selectedReaction == null) {
          likes++;
        }
        selectedReaction = reactionName;

        // Update displayed reactions
        final newReaction = _getReactionTypeFromString(reactionName);
        if (!_topReactions.contains(newReaction)) {
          // Keep distinct logic if needed, or just insert at front/end
          // Simplest: add if not present, maybe keeping list small
          if (!_topReactions.contains(newReaction)) {
            if (_topReactions.length >= 3) _topReactions.removeAt(0);
            _topReactions.add(newReaction);
          }
        }
      }
    });
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Compartir publicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      ShareHelper.shareToWhatsApp(
                        '${widget.content}\n\nDescarga Dreams Club y reclama tus bonos por re-visita en tu casino favorito.',
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Compartido en Facebook')),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Compartido en Instagram')),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.link,
                    label: 'Copiar link',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Link copiado al portapapeles')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Guardar publicación'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicación guardada')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Enviar a un amigo'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enviado a un amigo')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(
                  widget.userImage), // Asumiendo assets locales por ahora
              onBackgroundImageError: (_, __) => const Icon(Icons.person),
            ),
            title: Text(widget.userName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.timeAgo),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Más opciones próximamente')),
                );
              },
            ),
          ),
          // Content
          if (widget.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(widget.content),
            ),
          // Image
          if (widget.imageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {}, // Fallback silencioso
                ),
              ),
              child: widget.imageUrl!.startsWith('http')
                  ? null
                  : Image.asset(widget.imageUrl!,
                      fit: BoxFit.cover), // Support local assets too
            ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reacciones con iconos superpuestos estilo Facebook
                Row(
                  children: [
                    // Stack de emojis de reacciones
                    SizedBox(
                      width: 20 + (_topReactions.length - 1) * 15.0,
                      height: 20,
                      child: Stack(
                        children: _topReactions.asMap().entries.map((entry) {
                          return Positioned(
                            left: entry.key * 15.0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 2),
                              ),
                              child: ClipOval(
                                child: Lottie.asset(
                                  entry.value.lottieAsset,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  repeat: false, // Static preview
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('$likes', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                  },
                  child: Text(
                    '${_comments.length} comentarios • ${(likes / 10).floor()} compartidos',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons
          FacebookSocialBar(
            currentReaction: selectedReaction != null
                ? _getReactionTypeFromString(selectedReaction!)
                : null,
            onLikeTap: () {
              if (selectedReaction == null) {
                _handleReaction('like');
              } else {
                // Toggle off
                setState(() {
                  selectedReaction = null;
                  likes--;
                });
              }
            },
            onReactionSelected: (reaction) {
              _handleReaction(reaction.name);
            },
            onCommentTap: () {
              setState(() {
                _showComments = !_showComments;
              });
            },
            onShareTap: () => _showShareOptions(context),
            commentsCount: _comments.length,
            sharesCount: (likes / 10).floor(),
          ),
          // Comments Section
          if (_showComments) ...[
            const Divider(height: 1),
            // Existing comments
            if (_comments.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      child: Text(comment.avatar,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    title: Row(
                      children: [
                        Text(comment.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(comment.timeAgo,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    subtitle: Text(comment.text,
                        style: const TextStyle(fontSize: 13)),
                    dense: true,
                  );
                },
              ),
            // Comment input
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Text('🙂', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario...',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send,
                              color: Theme.of(context).primaryColor),
                          onPressed: () {
                            if (_commentController.text.trim().isNotEmpty) {
                              setState(() {
                                _comments.insert(
                                    0,
                                    _Comment(
                                      name: 'Tú',
                                      text: _commentController.text.trim(),
                                      timeAgo: 'Ahora',
                                      avatar: '🙂',
                                    ));
                                _commentController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            _comments.insert(
                                0,
                                _Comment(
                                  name: 'Tú',
                                  text: value.trim(),
                                  timeAgo: 'Ahora',
                                  avatar: '🙂',
                                ));
                            _commentController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Modelo para comentarios
class _Comment {
  final String name;
  final String text;
  final String timeAgo;
  final String avatar;

  const _Comment({
    required this.name,
    required this.text,
    required this.timeAgo,
    required this.avatar,
  });
}

// Widget para opciones de compartir
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
