import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_order_card.dart';
import 'order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String statusFilter = 'all'; // all, paid, completed, pending

  Widget _filterChip(String label, String key) {
    final bool selected = statusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: selected ? Colors.white : Colors.brown.shade700,
          ),
        ),
        selected: selected,
        selectedColor: Colors.brown.shade800,
        backgroundColor: Colors.brown.shade200,
        onSelected: (_) => setState(() => statusFilter = key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return Column(
      children: [
        // ---------------- Filters ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("All", "all"),
                _filterChip("Paid", "paid"),
                _filterChip("Completed", "completed"),
                _filterChip("Pending", "pending"),
              ],
            ),
          ),
        ),

        // ---------------- Orders List ----------------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fs
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter orders
              final docs = snapshot.data!.docs.where((d) {
                if (statusFilter == 'all') return true;
                final data = d.data() as Map<String, dynamic>;
                final s = (data['status'] ?? '').toString().toLowerCase();
                return s.contains(statusFilter);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No orders found",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final raw = docs[index];
                  final d = raw.data() as Map<String, dynamic>;
                  final id = raw.id;

                  final String status = d['status']?.toString() ?? '';
                  final String amount = (d['totalAmount'] ?? 0).toString();
                  final String? userId = d['userId']?.toString();
                  final String? businessId = d['businessId']?.toString();

                  return FutureBuilder<List<String>>(
                    future: Future.wait([
                      _resolveUserEmail(fs, userId),
                      _resolveBusinessName(fs, businessId)
                    ]),

                    builder: (ctx, info) {
                      String userEmail = "Loading...";
                      String businessName = "Loading...";

                      if (info.connectionState == ConnectionState.done &&
                          info.hasData) {
                        userEmail = info.data![0];
                        businessName = info.data![1];
                      }

                      return AdminOrderCard(
                        id: id,
                        title: "Order #${id.substring(0, 8)}",
                        subtitle:
                        "By: $userEmail • Business: $businessName • Amount: \$$amount",
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
              );
            },
          ),
        ),
      ],
    );
  }

  Future<String> _resolveUserEmail(
      FirebaseFirestore fs, String? userId) async {
    if (userId == null || userId.isEmpty) return 'Unknown';
    try {
      final doc = await fs.collection('users').doc(userId).get();
      if (!doc.exists) return userId;
      return doc.data()?['email'] ?? userId;
    } catch (_) {
      return userId;
    }
  }

  Future<String> _resolveBusinessName(
      FirebaseFirestore fs, String? businessId) async {
    if (businessId == null || businessId.isEmpty) return 'N/A';
    try {
      final doc = await fs.collection('businesses').doc(businessId).get();
      if (!doc.exists) return businessId;
      return doc.data()?['businessName'] ?? businessId;
    } catch (_) {
      return businessId;
    }
  }
}
