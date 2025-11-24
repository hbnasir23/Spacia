import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  const AdminProductCard({super.key, required this.product, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.03), blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // image on top
          if (product.imageUrl.isNotEmpty)
            ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)), child: Image.network(product.imageUrl.first, width: double.infinity, height: 120, fit: BoxFit.cover))
          else
            Container(width: double.infinity, height: 120, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))), child: const Icon(Icons.image)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              FutureBuilder<DocumentSnapshot?>(
                future: product.businessId == null ? Future.value(null) : FirebaseFirestore.instance.collection('businesses').doc(product.businessId!).get(),
                builder: (ctx, snap) {
                  String businessName = '';
                  if (snap.hasData && snap.data != null && snap.data!.data() != null) {
                    final data = snap.data!.data() as Map<String, dynamic>?;
                    businessName = data?['businessName']?.toString() ?? '';
                  }
                  return Text('\$${product.price.toStringAsFixed(2)} • Stock: ${product.quantity}${businessName.isNotEmpty ? ' • $businessName' : ''}', style: TextStyle(color: Colors.grey.shade700));
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

