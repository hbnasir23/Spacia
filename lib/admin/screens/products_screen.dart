import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../widgets/admin_product_card.dart';
import 'product_detail_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all'; // all, in_stock, out_of_stock
  double _minPrice = 0;
  double _maxPrice = 1000;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(ProductModel p, String query, String filter) {
    final q = query.toLowerCase();
    if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.category.toLowerCase().contains(q)) return false;
    if (filter == 'out_of_stock' && p.quantity > 0) return false;
    if (filter == 'in_stock' && p.quantity <= 0) return false;
    if (p.price < _minPrice || p.price > _maxPrice) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: fs.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final products = docs.map((d) => ProductModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        final filtered = products.where((p) => _matches(p, _searchCtrl.text, _filter)).toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search products by name or category',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // Removed the stock filter dropdown
              ]),
              const SizedBox(height: 12),

              // Price range inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Min price',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsedValue = double.tryParse(value);
                        if (parsedValue != null) {
                          setState(() {
                            _minPrice = parsedValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Max price',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsedValue = double.tryParse(value);
                        if (parsedValue != null) {
                          setState(() {
                            _maxPrice = parsedValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // summary
              Align(alignment: Alignment.centerLeft, child: Text('Showing ${filtered.length} of ${products.length} products', style: const TextStyle(fontFamily: 'Poppins'))),
              const SizedBox(height: 12),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return AdminProductCard(
                            product: p,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}
