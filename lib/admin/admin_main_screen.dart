import 'package:flutter/material.dart';
import 'package:spacia/constants/app_colors.dart';
import 'package:spacia/admin/screens/dashboard_screen.dart';
import 'package:spacia/admin/screens/products_screen.dart';
import 'package:spacia/admin/screens/businesses_screen.dart';
import 'package:spacia/admin/screens/orders_screen.dart';
import 'package:spacia/admin/screens/requests_screen.dart';
import 'package:spacia/admin/widgets/admin_top_bar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selected = 0;

  final List<Widget> _pages = [
    AdminDashboardScreen(),
    AdminProductsScreen(),
    AdminBusinessesScreen(),
    AdminOrdersScreen(),
    AdminRequestsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Products',
    'Businesses',
    'Orders',
    'Business Requests',
  ];

  void _onNavTap(int idx) => setState(() => _selected = idx);

  @override
  Widget build(BuildContext context) {
    // Use lightBrown background and BottomNavigationBar (like business dashboard)
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      body: Column(
        children: [
          AdminTopBar(title: _titles[_selected]),
          Expanded(child: IndexedStack(index: _selected, children: _pages)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.darkBrown,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navIconButton(3, Icons.receipt_long), // Orders (left)
                _navIconButton(2, Icons.store), // Businesses
                _centerNavButton(0, Icons.dashboard), // Dashboard center
                _navIconButton(1, Icons.inventory_2), // Products
                _navIconButton(4, Icons.how_to_reg), // Requests
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIconButton(int idx, IconData icon) {
    final selected = idx == _selected;
    return GestureDetector(
      onTap: () => _onNavTap(idx),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.lightBrown : Colors.transparent,
          border: selected ? Border.all(color: AppColors.lightBrown) : null,
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: selected ? AppColors.darkBrown : Colors.transparent,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _centerNavButton(int idx, IconData icon) {
    final selected = idx == _selected;
    return GestureDetector(
      onTap: () => _onNavTap(idx),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.lightBrown : Colors.transparent,
          border: selected ? Border.all(color: AppColors.lightBrown) : null,
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: selected ? AppColors.darkBrown : Colors.white,
          child: Icon(icon, color: selected ? Colors.white : AppColors.darkBrown),
        ),
      ),
    );
  }
}
