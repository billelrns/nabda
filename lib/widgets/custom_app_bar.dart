import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final bool showActions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onNotificationTap,
    this.onSettingsTap,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      elevation: 0,
      centerTitle: true,
      actions: showActions
          ? [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationTap,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettingsTap,
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}






