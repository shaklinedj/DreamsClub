import 'package:flutter/material.dart';

class NotificationBellIcon extends StatefulWidget {
  final bool hasNotifications;
  final VoidCallback onPressed;
  final int notificationCount;

  const NotificationBellIcon({
    super.key,
    this.hasNotifications = false,
    required this.onPressed,
    this.notificationCount = 0,
  });

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Si hay notificaciones, anima la campana continuamente
    if (widget.hasNotifications) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(NotificationBellIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNotifications && !oldWidget.hasNotifications) {
      _controller.repeat();
    } else if (!widget.hasNotifications && oldWidget.hasNotifications) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_arrow,
            progress: _controller,
          ),
          onPressed: widget.onPressed,
          tooltip: 'Notificaciones',
        ),
        if (widget.hasNotifications && widget.notificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                widget.notificationCount > 99
                    ? '99+'
                    : '${widget.notificationCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
