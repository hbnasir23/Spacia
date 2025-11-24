import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../business/screens/dashboard/business_dashboard_screen.dart';
import '../business/screens/orders/all_orders_screen.dart';
import '../business/screens/products/all_products_screen.dart';
import '../business/screens/products/add_product_screen.dart';
import '../business/screens/transactions/transactions_screen.dart';
import '../business/screens/profile/business_profile_screen.dart';
import 'widgets/business_navbar.dart';
import 'widgets/business_top_bar.dart';

class BusinessMainScreen extends StatefulWidget {
  final String businessId;

  const BusinessMainScreen({super.key, required this.businessId});

  @override
  State<BusinessMainScreen> createState() => _BusinessMainScreenState();
}

class _BusinessMainScreenState extends State<BusinessMainScreen> {
  int _selectedIndex = 2; // default to Dashboard

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AllOrdersScreen(businessId: widget.businessId),
      AddProductScreen(businessId: widget.businessId),
      BusinessDashboardScreen(businessId: widget.businessId, onNavigate: _onNavigateFromDashboard),
      AllProductsScreen(businessId: widget.businessId),
      TransactionsScreen(businessId: widget.businessId),
    ];
  }

  void _onNavigateFromDashboard(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: BusinessTopBar(
        title: _getTitle(),
        onProfilePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessProfileScreen(businessId: widget.businessId),
            ),
          );
        },
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BusinessNavBar(currentIndex: _selectedIndex, onTap: (index) => setState(() => _selectedIndex = index)),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Orders';
      case 1:
        return 'Add Product';
      case 3:
        return 'Products';
      case 4:
        return 'Transactions';
      default:
        return 'Dashboard';
    }
  }
}
