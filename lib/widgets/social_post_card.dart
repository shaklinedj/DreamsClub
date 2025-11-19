import 'package:flutter/material.dart';

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

  final Map<String, String> reactions = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
  };

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
  }

  void _handleReaction(String reaction) {
    setState(() {
      if (selectedReaction == reaction) {
        // Toggle off
        selectedReaction = null;
        likes--;
      } else {
        if (selectedReaction == null) {
          likes++;
        }
        selectedReaction = reaction;
      }
    });
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
              backgroundImage: AssetImage(widget.userImage), // Asumiendo assets locales por ahora
              onBackgroundImageError: (_, __) => const Icon(Icons.person),
            ),
            title: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.timeAgo),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {},
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
                  : Image.asset(widget.imageUrl!, fit: BoxFit.cover), // Support local assets too
            ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (selectedReaction != null) 
                      Text(reactions[selectedReaction] ?? '👍', style: const TextStyle(fontSize: 16)),
                    if (selectedReaction == null && likes > 0)
                      const Text('👍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('$likes'),
                  ],
                ),
                Text('${widget.initialComments} comentarios • 5 compartidos'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _ReactionButton(
                  selectedReaction: selectedReaction,
                  onReactionSelected: _handleReaction,
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  label: const Text('Comentar', style: TextStyle(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compartido en tu muro simulado')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  label: const Text('Compartir', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String? selectedReaction;
  final Function(String) onReactionSelected;

  const _ReactionButton({
    required this.selectedReaction,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Mapa de iconos y colores para el botón principal según la reacción
    IconData iconData = Icons.thumb_up_outlined;
    Color color = Colors.grey;
    String label = 'Me gusta';

    if (selectedReaction != null) {
      switch (selectedReaction) {
        case 'like':
          iconData = Icons.thumb_up;
          color = Colors.blue;
          label = 'Me gusta';
          break;
        case 'love':
          iconData = Icons.favorite;
          color = Colors.red;
          label = 'Me encanta';
          break;
        case 'haha':
          iconData = Icons.sentiment_very_satisfied;
          color = Colors.amber;
          label = 'Me divierte';
          break;
        case 'wow':
          iconData = Icons.sentiment_very_dissatisfied; // Closest to wow
          color = Colors.amber;
          label = 'Me asombra';
          break;
        case 'sad':
          iconData = Icons.sentiment_dissatisfied;
          color = Colors.amber;
          label = 'Me entristece';
          break;
        case 'angry':
          iconData = Icons.sentiment_very_dissatisfied;
          color = Colors.deepOrange;
          label = 'Me enoja';
          break;
      }
    }

    return GestureDetector(
      onLongPress: () {
        _showReactionMenu(context);
      },
      child: TextButton.icon(
        onPressed: () {
          if (selectedReaction == null) {
            onReactionSelected('like');
          } else {
            onReactionSelected(selectedReaction!); // Toggle off logic handled in parent
          }
        },
        icon: Icon(iconData, color: color),
        label: Text(label, style: TextStyle(color: color)),
      ),
    );
  }

  void _showReactionMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: position.dy - 60,
            left: 20, // Fixed left for simplicity or calculate based on button
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReactionIcon(context, '👍', 'like', Colors.blue),
                    _buildReactionIcon(context, '❤️', 'love', Colors.red),
                    _buildReactionIcon(context, '😂', 'haha', Colors.amber),
                    _buildReactionIcon(context, '😮', 'wow', Colors.amber),
                    _buildReactionIcon(context, '😢', 'sad', Colors.amber),
                    _buildReactionIcon(context, '😡', 'angry', Colors.deepOrange),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionIcon(BuildContext context, String emoji, String reactionKey, Color color) {
    return GestureDetector(
      onTap: () {
        onReactionSelected(reactionKey);
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
