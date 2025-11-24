import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../constants/app_colors.dart';
import '../../../models/product_model.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  final String businessId;

  const ProductDetailsScreen({super.key, required this.product, required this.businessId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _show3D = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // Image area with back & edit buttons
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrl.isNotEmpty)
                    PageView(children: product.imageUrl.map((url) => Image.network(url, fit: BoxFit.cover)).toList())
                  else
                    Container(color: AppColors.lightBrown),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(backgroundColor: AppColors.darkBrown, title: const Text('Edit Product')), body: AddProductScreen(businessId: widget.businessId, productId: product.id))));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkBrown)),
                  const SizedBox(height: 12),
                  Text(product.description, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                  const SizedBox(height: 12),
                  Text('Category: ${product.category}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text('Stock: ${product.quantity}', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: product.quantity > 0 ? Colors.green : Colors.red)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if ((product.modelUrl ?? '').isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No 3D model available'), backgroundColor: Colors.orange));
                            return;
                          }
                          setState(() => _show3D = !_show3D);
                        },
                        icon: const Icon(Icons.view_in_ar_rounded),
                        label: Text(_show3D ? 'Hide 3D Model' : 'Show 3D Model'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown, foregroundColor: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(backgroundColor: AppColors.darkBrown, title: const Text('Edit Product')), body: AddProductScreen(businessId: widget.businessId, productId: product.id))));
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _show3D
                        ? Container(
                            key: const ValueKey('3d'),
                            height: 300,
                            margin: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
                            child: product.modelUrl != null && product.modelUrl!.isNotEmpty
                                ? ModelViewer(
                                    src: product.modelUrl!,
                                    alt: '3D model of ${product.name}',
                                    autoRotate: true,
                                    cameraControls: true,
                                    backgroundColor: Colors.white,
                                  )
                                : Center(child: Text('No 3D model available', style: TextStyle(color: Colors.grey.shade600))),
                          )
                        : const SizedBox(key: ValueKey('empty')),
                  ),
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}
