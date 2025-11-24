import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/product_model.dart';
import '../../constants/app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _show3DModel = false;

  late Future<ProductModel?> _futureProduct;

  Future<ProductModel?> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  void initState() {
    super.initState();
    _futureProduct = _load();  // IMPORTANT!!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: AppBar(
        title: const Text('Product'),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),

      ),
      body: FutureBuilder<ProductModel?>(
        future: _futureProduct,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data == null) {
            return const Center(child: Text('Product not found'));
          }

          final p = snap.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                if (p.imageUrl.isNotEmpty)
                  Image.network(
                    p.imageUrl.first,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 260,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image, size: 64),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Stock: ${p.quantity}',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      Text(p.description),

                      const SizedBox(height: 12),

                      // 3D Model Button
                      if (p.modelUrl != null && p.modelUrl!.isNotEmpty)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _show3DModel = !_show3DModel;
                            });
                          },
                          child: Text(
                            _show3DModel
                                ? 'Hide 3D Model'
                                : 'View 3D Model',
                          ),
                        ),

                      // Animated 3D Model Section
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _show3DModel &&
                            p.modelUrl != null &&
                            p.modelUrl!.isNotEmpty
                            ? Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '3D Model',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              SizedBox(
                                height: 300,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: ModelViewer(
                                    key: ValueKey(p.modelUrl),
                                    src: p.modelUrl!,
                                    alt: "3D model of ${p.name}",
                                    autoRotate: true,
                                    cameraControls: true,
                                    ar: false,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),

                      // Delete Button ONLY
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirm delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this product?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(p.id)
                                    .delete();

                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
