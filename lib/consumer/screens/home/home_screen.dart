import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/product_model.dart';
import '../products/product_detail_screen.dart';
import '../../widgets/categories_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final firestore = FirebaseFirestore.instance;

  // Cache for business names
  final Map<String, String> _businessNameCache = {};

  Future<String> _getBusinessName(String businessId) async {
    if (_businessNameCache.containsKey(businessId)) {
      return _businessNameCache[businessId]!;
    }

    try {
      final doc = await firestore.collection('businesses').doc(businessId).get();
      if (doc.exists) {
        final name = doc.data()?['businessName']?.toString() ?? 'Unknown';
        _businessNameCache[businessId] = name;
        return name;
      }
    } catch (e) {
      print('Error fetching business name: $e');
    }
    return 'Unknown';
  }
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  final List<String> promoImages = [
    'assets/images/promo1.png',
    'assets/images/promo2.png',
    'assets/images/promo3.png',
    'assets/images/promo4.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBrown, // ✅ fixes the black background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child:// Hero section (FULL WIDTH slider, no cut, no padding)
            SizedBox(
              width: double.infinity,
              height: AppSizes.h(context, 0.25), // perfect ratio
              child: CarouselSlider(
                options: CarouselOptions(
                  height: AppSizes.h(context, 0.25),
                  autoPlay: true,
                  viewportFraction: 1.0, // full width
                  enlargeCenterPage: false,
                ),
                items: promoImages.map((image) {
                  return Image.asset(
                    image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover, // full image stretch, no weird cuts
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Categories
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w(context, 0.04)),
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

          const SizedBox(height: 10),

          // Products
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.w(context, 0.04)),
              child: StreamBuilder<QuerySnapshot>(
                stream: (_selectedCategoryId == null)
                    ? firestore.collection('products').snapshots()
                    : firestore
                        .collection('products')
                        .where('category', isEqualTo: _selectedCategoryId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.darkBrown),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No products available."));
                  }

                  final products = snapshot.data!.docs.map((doc) {
                    return ProductModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();

                  return GridView.builder(
                    itemCount: products.length,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _productCard(product);
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

  Widget _categoryChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _productCard(ProductModel product) {
    final firstImage = product.imageUrl.isNotEmpty ? product.imageUrl.first : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBrown.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  firstImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (product.businessId != null)
                    FutureBuilder<String>(
                      future: _getBusinessName(product.businessId!),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                "\$${product.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
