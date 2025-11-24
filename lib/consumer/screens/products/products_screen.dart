// filepath: c:\spacia\lib\consumer\screens\products\products_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/product_model.dart';
import '../../widgets/categories_list.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final firestore = FirebaseFirestore.instance;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Cache for business names to avoid repeated Firestore calls
  final Map<String, String> _businessNameCache = {};

  Future<String> _getBusinessName(String businessId) async {
    // Check cache first
    if (_businessNameCache.containsKey(businessId)) {
      return _businessNameCache[businessId]!;
    }

    try {
      final doc = await firestore.collection('businesses').doc(businessId).get();
      if (doc.exists) {
        final name = doc.data()?['businessName']?.toString() ?? 'Unknown Business';
        _businessNameCache[businessId] = name;
        return name;
      }
    } catch (e) {
      print('Error fetching business name: $e');
    }
    return 'Unknown Business';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        title: Text(_selectedCategoryName ?? 'Products', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w(context, 0.04), vertical: 8),
            child: CategoriesList(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (id, name) {
                setState(() {
                  if (_selectedCategoryId == id) {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  } else {
                    _selectedCategoryId = id;
                    _selectedCategoryName = name;
                  }
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.w(context, 0.04)),
              child: StreamBuilder<QuerySnapshot>(
                stream: (_selectedCategoryId == null)
                    ? firestore.collection('products').snapshots()
                    : firestore.collection('products').where('category', isEqualTo: _selectedCategoryId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.darkBrown));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products available.'));
                  }

                  final products = snapshot.data!.docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    itemCount: products.length,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.7),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final image = p.imageUrl.isNotEmpty ? p.imageUrl.first : '';
                      final isOutOfStock = p.quantity <= 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkBrown.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            image,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                          ),
                                          if (isOutOfStock)
                                            Container(
                                              color: Colors.black54,
                                              child: const Center(
                                                child: Text(
                                                  'OUT OF STOCK',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        if (p.businessId != null)
                                          FutureBuilder<String>(
                                            future: _getBusinessName(p.businessId!),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Text(
                                                  'by ${snapshot.data}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${p.price.toStringAsFixed(2)}',
                                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkBrown),
                                        ),
                                        Text(
                                          'Qty: ${p.quantity}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            color: isOutOfStock ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
