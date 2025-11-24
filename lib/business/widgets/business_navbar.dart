import 'package:flutter/material.dart';
import 'package:spacia/constants/app_colors.dart';

class BusinessNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BusinessNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.darkBrown,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIconButton(0, Icons.receipt_long),      // Orders
              _navIconButton(1, Icons.add_box_outlined),  // Add product
              _centerNavButton(2, Icons.dashboard),       // Center main dashboard
              _navIconButton(3, Icons.inventory_2),       // Products
              _navIconButton(4, Icons.payments),          // Transactions
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIconButton(int index, IconData icon) {
    final selected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.lightBrown : Colors.transparent,
          border: selected
              ? Border.all(color: AppColors.lightBrown)
              : null,
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor:
          selected ? AppColors.darkBrown : Colors.transparent,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _centerNavButton(int index, IconData icon) {
    final selected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.lightBrown : Colors.transparent,
          border: selected
              ? Border.all(color: AppColors.lightBrown)
              : null,
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor:
          selected ? AppColors.darkBrown : Colors.white,
          child: Icon(
            icon,
            color: selected ? Colors.white : AppColors.darkBrown,
          ),
        ),
      ),
    );
  }
}
