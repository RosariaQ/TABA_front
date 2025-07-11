import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final double avatarScale;
  final VoidCallback? onNotificationsPressed;
  final Function(TapDownDetails) onAvatarTapDown;
  final Function(TapUpDetails) onAvatarTapUp;
  final VoidCallback onAvatarTapCancel;
  final ImageProvider? avatarImage; // ✅ 외부에서 전달받는 이미지

  const DashboardHeader({
    super.key,
    required this.avatarScale,
    this.onNotificationsPressed,
    required this.onAvatarTapDown,
    required this.onAvatarTapUp,
    required this.onAvatarTapCancel,
    this.avatarImage, // ✅ 생성자에 포함
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 28),
                onPressed: onNotificationsPressed,
                color: Colors.black54,
                tooltip: '알림',
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTapDown: onAvatarTapDown,
                onTapUp: onAvatarTapUp,
                onTapCancel: onAvatarTapCancel,
                child: AnimatedScale(
                  scale: avatarScale,
                  duration: const Duration(milliseconds: 150),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: avatarImage ??
                        const AssetImage('assets/image/default_man.png'),
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
