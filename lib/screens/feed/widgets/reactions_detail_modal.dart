import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';

class ReactionsDetailModal extends StatefulWidget {
  final String postId;
  final String collectionPath;

  const ReactionsDetailModal({
    super.key,
    required this.postId,
    this.collectionPath = 'posts',
  });

  @override
  State<ReactionsDetailModal> createState() => _ReactionsDetailModalState();
}

class _ReactionsDetailModalState extends State<ReactionsDetailModal> {
  String _selectedReactionType = 'all'; // 'all' or reaction name (e.g. 'like', 'love')

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161922), // Dark luxury background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Reacciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Content Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collectionPath)
                  .doc(widget.postId)
                  .collection('reactions')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar reacciones: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay reacciones aún.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }

                final List<Map<String, dynamic>> reactions = docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();

                // Compute counts and types present
                final Map<String, int> counts = {};
                for (var r in reactions) {
                  final type = r['reactionType']?.toString() ?? 'like';
                  counts[type] = (counts[type] ?? 0) + 1;
                }

                // Filter list
                final displayed = _selectedReactionType == 'all'
                    ? reactions
                    : reactions
                        .where((r) => r['reactionType'] == _selectedReactionType)
                        .toList();

                // Render filter tabs
                return Column(
                  children: [
                    // Horizontal Filter Bar
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildFilterTab(
                            label: 'Todos',
                            count: reactions.length,
                            isSelected: _selectedReactionType == 'all',
                            onTap: () => setState(() => _selectedReactionType = 'all'),
                          ),
                          ...counts.entries.map((entry) {
                            final typeName = entry.key;
                            final count = entry.value;

                            final reactionType = ReactionType.values.firstWhere(
                              (t) => t.name == typeName,
                              orElse: () => ReactionType.like,
                            );

                            return _buildFilterTab(
                              emoji: reactionType.emoji,
                              label: reactionType.label,
                              count: count,
                              isSelected: _selectedReactionType == typeName,
                              onTap: () => setState(() => _selectedReactionType = typeName),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),

                    // User List
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayed.length,
                        itemBuilder: (context, index) {
                          final r = displayed[index];
                          final userName = r['userName']?.toString() ?? 'Usuario';
                          final typeName = r['reactionType']?.toString() ?? 'like';

                          final reactionType = ReactionType.values.firstWhere(
                            (t) => t.name == typeName,
                            orElse: () => ReactionType.like,
                          );

                          // Initials for avatar
                          final initials = userName.trim().isNotEmpty
                              ? userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                              : 'U';

                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF232738),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF161922),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: reactionType.color.withValues(alpha: 0.2),
                                      child: Text(
                                        reactionType.emoji,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    String? emoji,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.3) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
