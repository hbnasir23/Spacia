import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrl; // changed from String to List<String>
  final String? modelUrl;
  final String? businessId;
  final DateTime? createdAt;
  final int quantity; // Available stock quantity

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.modelUrl,
    this.businessId,
    this.createdAt,
    this.quantity = 0, // Default to 0 if not specified
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    List<String> imageList = [];

    // Handle both old (string) and new (list) structures gracefully
    if (data['imageUrl'] is List) {
      imageList = List<String>.from(data['imageUrl']);
    } else if (data['imageUrl'] is String && data['imageUrl'].isNotEmpty) {
      imageList = [data['imageUrl']];
    }

    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      imageUrl: imageList,
      modelUrl: data['modelUrl'],
      businessId: data['businessId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      quantity: data['quantity'] ?? 0,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl, // list saved directly
      'modelUrl': modelUrl,
      'businessId': businessId,
      'createdAt': createdAt,
      'quantity': quantity,
    };
  }
}
