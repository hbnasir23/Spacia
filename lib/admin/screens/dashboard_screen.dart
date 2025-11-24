import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spacia/admin/screens/order_detail_screen.dart';
import 'package:spacia/admin/screens/orders_screen.dart';
import 'package:spacia/admin/widgets/admin_order_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<Map<String, dynamic>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _fetchCounts();
  }

  Future<Map<String, dynamic>> _fetchCounts() async {
    try {
      final businesses =
      await _firestore.collection('businesses').where('approved', isEqualTo: true).get();
      final products = await _firestore.collection('products').get();
      final orders = await _firestore.collection('orders').get();

      double revenue = 0;
      for (var doc in orders.docs) {
        final data = doc.data();
        final amt = data['totalAmount'] ?? 0;
        revenue += (amt is num)
            ? amt.toDouble()
            : (double.tryParse(amt.toString()) ?? 0.0);
      }

      return {
        'totalBusinesses': businesses.docs.length,
        'totalProducts': products.docs.length,
        'totalOrders': orders.docs.length,
        'totalRevenue': revenue,
      };
    } catch (_) {
      return {
        'totalBusinesses': 0,
        'totalProducts': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _countsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          );
        }

        final data = snapshot.data ?? {};
        final totalBusinesses = data['totalBusinesses'] ?? 0;
        final totalProducts = data['totalProducts'] ?? 0;
        final totalOrders = data['totalOrders'] ?? 0;
        final totalRevenue = (data['totalRevenue'] ?? 0.0).toDouble();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------------
                // ⭐ Dashboard Header
                // ---------------------------------------------------------
                const Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                // ---------------------------------------------------------
                // ⭐ Summary Cards Section
                // ---------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _statCard(
                            title: "Total Businesses",
                            value: totalBusinesses.toString(),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            title: "Total Profit",
                            value: "\$${(totalRevenue * 0.10).toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            title: "Total Orders",
                            value: totalOrders.toString(),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            title: "Revenue",
                            value: "\$${totalRevenue.toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // ---------------------------------------------------------
                // ⭐ Recent Orders Header
                // ---------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Orders",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                      ),
                      child: const Text(
                        "View All",
                        style: TextStyle(fontFamily: "Poppins"),
                      ),
                    ),
                  ],
                ),

                // ---------------------------------------------------------
                // ⭐ Recent Orders List
                // ---------------------------------------------------------
                SizedBox(
                  height: 320,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('orders')
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.brown),
                        );
                      }

                      final docs = snap.data!.docs;

                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final raw = docs[index];
                          final d = raw.data() as Map<String, dynamic>;
                          final id = raw.id;

                          final status = (d['status'] ?? '').toString();
                          final amount = (d['totalAmount'] ?? 0).toString();

                          return AdminOrderCard(
                            id: id,
                            title: "Order #${id.substring(0, 8)}",
                            subtitle: "Amount: \$$amount",
                            status: status,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(orderId: id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------------
  // ⭐ Single Stat Card Widget
  // ----------------------------------------------------------------------------
  Widget _statCard({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
