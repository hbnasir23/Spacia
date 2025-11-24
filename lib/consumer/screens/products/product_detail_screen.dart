import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spacia/consumer/screens/products/product_ar_view_screen.dart';
import '../../../constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? product;
  bool loading = true;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
    if (doc.exists) {
      setState(() {
        product = ProductModel.fromMap(doc.data()!, doc.id);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.lightBrown,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.darkBrown),
        ),
      );
    }

    if (product == null) {
      return const Scaffold(
        backgroundColor: AppColors.lightBrown,
        body: Center(
          child: Text("Product not found",
              style: TextStyle(fontFamily: 'Poppins')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- makes the arrow white
        ),
        title: Text(
          product!.name,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel for multiple images
            if (product!.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: product!.imageUrl.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        product!.imageUrl[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // --- SINGLE AR BUTTON ---
            // Only show this button if a 3D model URL exists
            if (product!.modelUrl != null && product!.modelUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the screen that has the ModelViewer + AR functionality
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductARViewScreen(
                          modelUrl: product!.modelUrl!,
                          name: product!.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar_rounded, size: 22),
                  label: const Text(
                    'View in My Space',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White background to stand out
                    foregroundColor: AppColors.darkBrown, // Dark text
                    elevation: 2,
                    side: const BorderSide(color: AppColors.darkBrown, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Add some spacing if the button is visible
            if (product!.modelUrl != null && product!.modelUrl!.isNotEmpty)
              const SizedBox(height: 20),
            // ------------------------

            // Text(
            //   product!.name,
            //   style: const TextStyle(
            //     fontFamily: 'Poppins',
            //     fontWeight: FontWeight.bold,
            //     fontSize: 22,
            //     color: AppColors.darkBrown,
            //   ),
            // ),
            // const SizedBox(height: 4),
            // Business name
            // BUSINESS NAME - CLEAN LEFT/RIGHT LAYOUT
            if (product!.businessId != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(product!.businessId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final businessName = data['businessName'] ?? 'Unknown Business';

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LEFT: PRODUCT NAME
                          Expanded(
                            child: Text(
                              product!.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: AppColors.darkBrown,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // RIGHT: BUSINESS NAME IN WHITE BOX
                          Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.darkBrown, width: 1.5),
                            ),
                            child: Text(
                              businessName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 12),
            Text(
              "\$${product!.price.toStringAsFixed(2)}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 16),

            // Available Stock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: product!.quantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: product!.quantity > 0 ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    product!.quantity > 0 ? Icons.check_circle : Icons.cancel,
                    color: product!.quantity > 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product!.quantity > 0
                        ? 'Available: ${product!.quantity} in stock'
                        : 'Out of Stock',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: product!.quantity > 0 ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              "Description",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product!.description.isNotEmpty
                  ? product!.description
                  : "No description available.",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Quantity Selector
            if (product!.quantity > 0) ...[
              const Text(
                "Quantity",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBrown.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() => quantity--);
                        }
                      },
                      icon: const Icon(Icons.remove),
                      color: AppColors.darkBrown,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < product!.quantity ? () {
                        setState(() => quantity++);
                      } : null,
                      icon: const Icon(Icons.add),
                      color: quantity < product!.quantity ? AppColors.darkBrown : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: product!.quantity > 0 ? () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addItem(product!, quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$quantity ${quantity == 1 ? 'item' : 'items'} added to cart',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: AppColors.darkBrown,
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'View Cart',
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                } : null,
                icon: const Icon(Icons.shopping_cart_outlined, size: 24),
                label: Text(
                  product!.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: product!.quantity > 0 ? AppColors.darkBrown : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shop Now Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addItem(product!, quantity);
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Product added! Please navigate to cart tab to view.',
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: AppColors.darkBrown,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                label: const Text(
                  'Shop Now',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBrown,
                  side: const BorderSide(color: AppColors.darkBrown, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}