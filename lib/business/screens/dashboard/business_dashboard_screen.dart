import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../products/product_details_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  final String businessId;
  final void Function(int index)? onNavigate; // 3 -> Products tab

  const BusinessDashboardScreen({super.key, required this.businessId, this.onNavigate});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalOrders = 0;
  int totalProducts = 0;
  double totalRevenue = 0.0;
  int pendingOrders = 0;
  List<double> revenueSeries = List.filled(7, 0.0);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Get all products for this business
      final productsSnapshot = await _firestore
          .collection('products')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      totalProducts = productsSnapshot.docs.length;

      // Get all orders
      final ordersSnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      totalOrders = 0;
      totalRevenue = 0.0;
      pendingOrders = 0;

      final productIds = productsSnapshot.docs.map((doc) => doc.id).toSet();

      // prepare 7-day revenue buckets (today .. 6 days ago)
      final now = DateTime.now();
      revenueSeries = List.filled(7, 0.0);

      for (var orderDoc in ordersSnapshot.docs) {
        final order = OrderModel.fromMap(orderDoc.data(), orderDoc.id);

        // Check if order contains any of this business's products
        bool hasBusinessProduct = false;
        double orderBusinessAmount = 0.0;

        for (var item in order.items) {
          if (productIds.contains(item.productId)) {
            hasBusinessProduct = true;
            orderBusinessAmount += item.price * item.quantity;
          }
        }

        if (hasBusinessProduct) {
          totalOrders++;
          // Only add revenue if order is completed
          if (order.status == 'completed') {
            totalRevenue += orderBusinessAmount;
            // bucket into revenueSeries by day (createdAt is non-nullable on OrderModel)
            final daysAgo = now.difference(order.createdAt).inDays;
            if (daysAgo >= 0 && daysAgo < 7) {
              revenueSeries[daysAgo] += orderBusinessAmount;
            }
          }

          if (order.status == 'pending') {
            pendingOrders++;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.darkBrown),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row (Total Sales + Total Orders)
                const SizedBox(height: 4),
                _buildStatsRow(),

                const SizedBox(height: 12),
                _buildRevenueChart(),

                const SizedBox(height: 20),

                // Recent Orders Section
                _buildRecentOrdersSection(),

                const SizedBox(height: 32),

                // Recent Products Section
                _buildRecentProductsSection(),
              ],
            ),
          );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Sales', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text('\$${totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
              const SizedBox(height: 6),
              Text('$totalProducts products • $pendingOrders pending', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Orders', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text('$totalOrders', style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
              const SizedBox(height: 6),
              Text('Revenue shown below', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ),
      ],
    );
  }

  // Simple line chart painter to avoid overflow and look better than bars
  Widget _buildRevenueChart() {
    final maxVal = revenueSeries.isEmpty ? 1.0 : revenueSeries.reduce((a, b) => a > b ? a : b);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Orders & Revenue (last 7 days)', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: LayoutBuilder(builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _onChartTap(details, constraints.maxWidth, 140, revenueSeries.reversed.toList(), maxVal),
              child: CustomPaint(
                size: Size(constraints.maxWidth, 140),
                painter: _LineChartPainter(revenueSeries.reversed.toList(), maxVal),
              ),
            );
          }),
        ),
      ]),
    );
  }

  void _onChartTap(TapDownDetails details, double width, double height, List<double> painterData, double maxVal) {
    final int count = painterData.length;
    final denom = count > 1 ? (count - 1) : 1;
    final w = width / denom;
    final dx = details.localPosition.dx.clamp(0.0, width);
    int idx = (dx / w).round();
    if (idx < 0) idx = 0;
    if (idx >= count) idx = count - 1;

    // painterData is oldest-first; map to daysAgo (0 = today)
    final daysAgo = (count - 1) - idx;
    final amount = painterData[idx];

    final label = daysAgo == 0 ? 'Today' : (daysAgo == 1 ? '1 day ago' : '$daysAgo days ago');

    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(label, style: const TextStyle(fontFamily: 'Poppins')),
        content: Text('Revenue: \$${amount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      );
    });
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
            ),
            TextButton.icon(
              onPressed: () {
                if (widget.onNavigate != null) widget.onNavigate!(0);
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All', style: TextStyle(fontFamily: 'Poppins')),
              style: TextButton.styleFrom(foregroundColor: AppColors.darkBrown),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<OrderModel>>(
          future: _getBusinessOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.darkBrown));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState('No orders yet');

            final orders = snapshot.data!.take(4).toList();
            return SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 4),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(width: 300, child: _buildOrderCard(orders[index])),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<List<OrderModel>> _getBusinessOrders() async {
    final productsSnapshot = await _firestore.collection('products').where('businessId', isEqualTo: widget.businessId).get();
    final productIds = productsSnapshot.docs.map((d) => d.id).toSet();

    final ordersSnapshot = await _firestore.collection('orders').orderBy('createdAt', descending: true).get();
    final list = <OrderModel>[];
    for (var doc in ordersSnapshot.docs) {
      final order = OrderModel.fromMap(doc.data(), doc.id);
      final has = order.items.any((it) => productIds.contains(it.productId));
      if (has) list.add(order);
    }
    return list;
  }

  Widget _buildRecentProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Products', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
            TextButton.icon(
              onPressed: () {
                if (widget.onNavigate != null) widget.onNavigate!(3);
                Navigator.pushNamed(context, '/business/products');
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All', style: TextStyle(fontFamily: 'Poppins')),
              style: TextButton.styleFrom(foregroundColor: AppColors.darkBrown),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('products').where('businessId', isEqualTo: widget.businessId).limit(4).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.darkBrown));
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState('No products yet');
            final docs = snapshot.data!.docs;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: docs.map((d) {
                final product = ProductModel.fromMap(d.data() as Map<String, dynamic>, d.id);
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product, businessId: widget.businessId))),
                  child: Container(width: 260, margin: const EdgeInsets.only(right: 12), child: _buildProductCardWidget(product)),
                );
              }).toList()),
            );
          },
        )
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final items = order.items;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------ HEADER ------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // LEFT INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${order.id.substring(0, 10)}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // STATUS BADGE (now tight)
              _buildStatusBadge(order.status),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ------------------ SCROLLABLE PRODUCTS ------------------
          SizedBox(
            height: items.length == 1 ? 70 : 140, // FIXES OVERFLOW
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.productImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),

                      SizedBox(width: 10),

                      // LEFT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Qty: ${item.quantity}",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // PRICE (close to product)
                      Text(
                        "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 24),

          // ------------------ FOOTER ------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment: ${order.paymentMethod.toUpperCase()}",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey.shade600),
                      SizedBox(width: 4),
                      SizedBox(
                        width: 160, // keeps it inside card
                        child: Text(
                          order.deliveryAddress['address'] ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // RIGHT SIDE PRICE (on SAME LINE)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "\$${order.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    switch (status.toLowerCase()) {
      case 'pending': bgColor = Colors.orange; break;
      case 'paid': bgColor = Colors.blue; break;
      case 'completed': bgColor = Colors.green; break;
      case 'cancelled': bgColor = Colors.red; break;
      default: bgColor = Colors.grey; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)));
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': newStatus});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: AppColors.darkBrown));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating order: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCardWidget(ProductModel product, {VoidCallback? viewCallback}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        if (product.imageUrl.isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product.imageUrl.first, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: AppColors.lightBrown, child: const Icon(Icons.image, color: AppColors.darkBrown))))
        else
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.lightBrown, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory, color: AppColors.darkBrown)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Stock: ${product.quantity}', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: product.quantity > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
            TextButton(onPressed: viewCallback, child: const Text('View'))
          ])
        ]))
      ]),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data; // reversed (oldest first)
  final double maxVal;
  _LineChartPainter(this.data, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF5C4033)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = Color.fromRGBO(234, 216, 192, 0.6)
      ..style = PaintingStyle.fill;

    final int count = data.length;
    final denom = count > 1 ? (count - 1) : 1;
    final w = size.width / denom;
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * w;
      final y = maxVal == 0 ? size.height : size.height - ((data[i] / maxVal) * (size.height - 20)) - 10;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // fill area under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // draw small dots on data points
    final dotPaint = Paint()..color = const Color(0xFF5C4033);
    for (var p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
