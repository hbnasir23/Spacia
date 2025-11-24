import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../constants/app_colors.dart';
import '../../../../providers/cart_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.receipt_long, 'index': 0},
      {'icon': Icons.search_rounded, 'index': 1},
      {'icon': Icons.home_filled, 'index': 2},
      {'icon': Icons.shopping_cart_rounded, 'index': 3},
      {'icon': Icons.person_rounded, 'index': 4},
    ];

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
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(items[0], isCenter: false),
              _navItem(items[1], isCenter: false),
              _navItem(items[2], isCenter: true),   // Center Home
              _navItem(items[3], isCenter: false),  // Cart
              _navItem(items[4], isCenter: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(Map<String, dynamic> item, {required bool isCenter}) {
    final idx = item['index'];
    final selected = idx == currentIndex;
    final isCart = idx == 3;

    return GestureDetector(
      onTap: () => onTap(idx),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.lightBrown : Colors.transparent,
              border: selected ? Border.all(color: AppColors.lightBrown) : null,
            ),
            child: CircleAvatar(
              radius: isCenter ? 20 : 18,
              backgroundColor:
              selected ? AppColors.darkBrown : (isCenter ? Colors.white : Colors.transparent),
              child: Icon(
                item['icon'] as IconData,
                color: selected
                    ? Colors.white
                    : (isCenter
                    ? AppColors.darkBrown
                    : Colors.white),
                size: 20,
              ),
            ),
          ),

          // CART BADGE
          if (isCart)
            Consumer<CartProvider>(
              builder: (ctx, cart, _) {
                if (cart.itemCount == 0) return const SizedBox.shrink();
                return Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
