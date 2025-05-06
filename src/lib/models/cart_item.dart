import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';
// import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  final String userId;
  final String productName;
  final double price;
  int quantity;
  final String category;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.category,
    required this.addedAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      productName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0) as int,
      category: data['category'] ?? '',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'category': category,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  double get totalPrice => price * quantity;

  Product toProduct() {
    return Product(
      id: productId,
      name: productName,
      description: '',
      price: price.toInt(),
      imageUrl: '',
      category: category,
      quantity: quantity,
      createdAt: addedAt,
    );
  }
}
