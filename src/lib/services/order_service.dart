import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

class OrderService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createOrder(List<OrderItem> items, int totalAmount) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final orderNumber = _generateOrderNumber();
    final order = Order(
      id: '', // Will be set by Firestore
      orderNumber: orderNumber,
      items: items,
      totalAmount: totalAmount,
      status: 'pending',
      createdAt: DateTime.now(),
      userId: user.uid,
    );

    // Start a batch write
    final batch = _firestore.batch();

    // Add the order
    final orderRef = _firestore.collection('orders').doc();
    batch.set(orderRef, order.toMap());

    // Update product quantities
    for (var item in items) {
      final productRef = _firestore.collection('products').doc(item.product.id);
      batch.update(productRef, {
        'quantity': firestore.FieldValue.increment(-item.quantity),
      });
    }

    // Commit the batch
    await batch.commit();
  }

  String _generateOrderNumber() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = DateTime.now().microsecondsSinceEpoch % chars.length;
    String result = '';

    // Generate a 3-digit alphanumeric ID
    for (var i = 0; i < 3; i++) {
      final index = (random + i * 7) % chars.length;
      result += chars[index];
    }

    return result;
  }

  Stream<List<Order>> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Order.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  Stream<List<Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Order.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (orderId.isEmpty) throw Exception('Invalid order ID');
    if (status.isEmpty) throw Exception('Invalid status');

    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }
}
