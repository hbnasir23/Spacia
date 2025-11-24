import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'home/widgets/custom_topbar.dart';
import 'home/widgets/bottom_navbar.dart';
import 'search/search_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // default: Home

  final List<Widget> _screens = const [
    OrdersScreen(),
    SearchScreen(),
    HomeScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,

      body: Column(
        children: [
          // ✅ Top bar sits at absolute top (no SafeArea)
          const CustomTopBar(),

          // ✅ Only the inner content respects SafeArea
          Expanded(
            child: SafeArea(
              top: false, // we already handled the top with CustomTopBar
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),

      // ✅ Single global bottom nav bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }
}
