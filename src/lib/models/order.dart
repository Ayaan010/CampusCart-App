import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';
import '../utils/logger_util.dart';

class OrderItem {
  final Product product;
  final int quantity;
  final int price;

  OrderItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    try {
      return OrderItem(
        product: Product(
          id: map['productId']?.toString() ?? '',
          name: map['productName']?.toString() ?? '',
          description: '',
          price: (map['price'] as num?)?.toInt() ?? 0,
          imageUrl: '',
          category: '',
          quantity: 0,
          createdAt: DateTime.now(),
        ),
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        price: (map['price'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      LoggerUtil.error('Error in OrderItem.fromMap: $e');
      LoggerUtil.error('Map data: $map');
      rethrow;
    }
  }
}

class Order {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final int totalAmount;
  final String status;
  final DateTime createdAt;
  final String userId;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    try {
      final itemsList = map['items'] as List<dynamic>? ?? [];
      final items =
          itemsList.map((item) {
            if (item is Map<String, dynamic>) {
              return OrderItem.fromMap(item);
            } else {
              LoggerUtil.error('Invalid item format: $item');
              return OrderItem(
                product: Product(
                  id: '',
                  name: '',
                  description: '',
                  price: 0,
                  imageUrl: '',
                  category: '',
                  quantity: 0,
                  createdAt: DateTime.now(),
                ),
                quantity: 0,
                price: 0,
              );
            }
          }).toList();

      return Order(
        id: id,
        orderNumber: map['orderNumber']?.toString() ?? '',
        items: items,
        totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
        status: map['status']?.toString() ?? 'pending',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userId: map['userId']?.toString() ?? '',
      );
    } catch (e) {
      LoggerUtil.error('Error in Order.fromMap: $e');
      LoggerUtil.error('Map data: $map');
      rethrow;
    }
  }
}
