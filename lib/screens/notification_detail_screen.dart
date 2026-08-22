import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/providers/notification_provider.dart';
import 'package:casinoloyalty_flutter/models/notification_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  Map<String, dynamic>? _notificationData;
  List<WonPrize>? _userPrizes;
  bool _isLoading = true;
  String? _error;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchNotificationDetails();
    // Eliminar la notificación del listado local ya que se está revisando en detalle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationsProvider.notifier)
          .removeNotification(widget.notificationId);
    });
  }

  Future<void> _fetchNotificationDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.notificationId)
          .get();

      if (doc.exists && doc.data() != null) {
        final user = ref.read(userProvider);
        final userId = user.email.isNotEmpty ? user.email : (user.rut ?? '');

        List<WonPrize> userPrizes = [];
        try {
          final querySnap = await FirebaseFirestore.instance
              .collection('user_prizes')
              .where('userId', isEqualTo: userId)
              .get();
          userPrizes =
              querySnap.docs.map((d) => WonPrize.fromJson(d.data())).toList();
        } catch (_) {}

        if (mounted) {
          setState(() {
            _notificationData = doc.data();
            _userPrizes = userPrizes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = "La notificación no existe o fue eliminada.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error al cargar los detalles: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSaveNotification() {
    if (_notificationData == null) return;

    final user = ref.read(userProvider);
    final userName = user.name.isNotEmpty ? user.name : 'Socio';

    final rawTitle = _notificationData!['title']?.toString() ?? 'Dreams Club';
    final rawBody = _notificationData!['body']?.toString() ?? '';

    String body =
        rawBody.replaceAll('{name}', userName).replaceAll('{nombre}', userName);

    if (body.contains('{pending_prize}') || body.contains('{pendingPrize}')) {
      final activePrize = (_userPrizes ?? []).firstWhereOrNull(
        (p) => p.status == 'disponible' && !p.isRedeemed && !p.isExpired,
      );

      if (activePrize != null) {
        body = body
            .replaceAll('{pending_prize}',
                "recuerda que tienes tu '${activePrize.prize.name}' por cobrar. ")
            .replaceAll('{pendingPrize}',
                "recuerda que tienes tu '${activePrize.prize.name}' por cobrar. ");
      } else {
        body = body
            .replaceAll('{pending_prize}', '')
            .replaceAll('{pendingPrize}', '');
      }
    }

    String title = rawTitle
        .replaceAll('{name}', userName)
        .replaceAll('{nombre}', userName);

    final typeStr = _notificationData!['type']?.toString() ?? 'info';
    final createdAt = _notificationData!['createdAt'];

    DateTime timestamp = DateTime.now();
    if (createdAt is Timestamp) {
      timestamp = createdAt.toDate();
    }

    NotificationType type = NotificationType.info;
    if (typeStr.toLowerCase() == 'promo' || typeStr.toLowerCase() == 'event') {
      type = NotificationType.promo;
    } else if (typeStr.toLowerCase() == 'birthday') {
      type = NotificationType.birthday;
    }

    final appNotification = AppNotification(
      id: widget.notificationId,
      title: title,
      message: body,
      type: type,
      timestamp: timestamp,
      actionRoute: '/notification-detail/${widget.notificationId}',
      actionData: {
        'imageUrl': _notificationData!['imageUrl'],
      },
    );

    setState(() {
      _isSaved = !_isSaved;
    });

    if (_isSaved) {
      ref
          .read(notificationsProvider.notifier)
          .restoreNotification(appNotification);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notificación guardada en el listado"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ref
          .read(notificationsProvider.notifier)
          .removeNotification(widget.notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notificación eliminada del listado"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark aesthetic matching casino theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: const Text(
          "Notificación",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: _isLoading || _error != null || _notificationData == null
            ? null
            : [
                IconButton(
                  icon: Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isSaved ? AppTheme.kPrimaryBlue : Colors.white,
                  ),
                  tooltip:
                      _isSaved ? "Mantener en listado" : "Guardar en listado",
                  onPressed: _toggleSaveNotification,
                ),
              ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.kPrimaryBlue),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/feed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Volver al Inicio"),
              ),
            ],
          ),
        ),
      );
    }

    if (_notificationData == null) {
      return const SizedBox.shrink();
    }

    final rawTitle = _notificationData!['title']?.toString() ?? 'Dreams Club';
    final rawBody = _notificationData!['body']?.toString() ?? '';
    final imageUrl = _notificationData!['imageUrl']?.toString();
    final type = _notificationData!['type']?.toString() ?? 'info';
    final createdAt = _notificationData!['createdAt'];

    final user = ref.read(userProvider);
    final userName = user.name.isNotEmpty ? user.name : 'Socio';

    String body =
        rawBody.replaceAll('{name}', userName).replaceAll('{nombre}', userName);

    if (body.contains('{pending_prize}') || body.contains('{pendingPrize}')) {
      final activePrize = (_userPrizes ?? []).firstWhereOrNull(
        (p) => p.status == 'disponible' && !p.isRedeemed && !p.isExpired,
      );

      if (activePrize != null) {
        body = body
            .replaceAll('{pending_prize}',
                "recuerda que tienes tu '${activePrize.prize.name}' por cobrar en caja. ")
            .replaceAll('{pendingPrize}',
                "recuerda que tienes tu '${activePrize.prize.name}' por cobrar en caja. ");
      } else {
        body = body
            .replaceAll('{pending_prize}', '')
            .replaceAll('{pendingPrize}', '');
      }
    }

    String title = rawTitle
        .replaceAll('{name}', userName)
        .replaceAll('{nombre}', userName);

    DateTime timestamp = DateTime.now();
    if (createdAt is Timestamp) {
      timestamp = createdAt.toDate();
    }

    // Category Styling
    Color categoryColor = Colors.blueAccent;
    String categoryName = "Información";
    IconData categoryIcon = Icons.info_outline;

    switch (type.toLowerCase()) {
      case 'promo':
        categoryColor = Colors.orangeAccent;
        categoryName = "Promoción";
        categoryIcon = Icons.local_offer_outlined;
        break;
      case 'event':
        categoryColor = Colors.purpleAccent;
        categoryName = "Evento";
        categoryIcon = Icons.celebration_outlined;
        break;
      case 'alert':
        categoryColor = Colors.redAccent;
        categoryName = "Alerta";
        categoryIcon = Icons.warning_amber_outlined;
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image if present
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white12,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrl),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.kPrimaryBlue,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white10,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: Colors.white38, size: 48),
                          SizedBox(height: 8),
                          Text(
                            "Error al cargar la imagen",
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Tag & Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, color: categoryColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            categoryName.toUpperCase(),
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Body Message
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

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
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.kPrimaryBlue,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        );
      },
    ));
  }
}
