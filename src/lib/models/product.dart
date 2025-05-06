import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final int price;
  final int quantity;
  final String category;
  final String? subcategory;
  final String? imageUrl;
  final String? imageBase64;
  final bool hasImage;
  final bool inStock;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
    this.subcategory,
    this.imageUrl,
    this.imageBase64,
    this.hasImage = false,
    this.inStock = true,
    required this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle price conversion more robustly
    int parsePrice(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is double) {
        return value.toInt();
      } else if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: parsePrice(data['price']),
      quantity: (data['quantity'] ?? 0) is int
          ? (data['quantity'] ?? 0)
          : int.parse(data['quantity']?.toString() ?? '0'),
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      imageUrl: data['imageUrl'],
      imageBase64: data['imageBase64'],
      hasImage: data['hasImage'] ?? false,
      inStock: data['inStock'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'subcategory': subcategory,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'hasImage': hasImage,
      'inStock': inStock,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
