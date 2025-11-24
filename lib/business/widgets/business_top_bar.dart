import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class BusinessTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfilePressed;
  const BusinessTopBar({super.key, required this.title, this.onProfilePressed});

  // Slightly taller top bar per request
  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: AppColors.darkBrown,
      // push content a bit down from top
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onProfilePressed,
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }
}
