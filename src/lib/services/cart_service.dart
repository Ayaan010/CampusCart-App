import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'auth_service.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get cart items for current user
  Stream<List<CartItem>> getCartItems() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CartItem.fromFirestore(doc))
              .toList();
        });
  }

  // Add item to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Start a transaction
    return _firestore.runTransaction((transaction) async {
      // Get the product document
      final productRef = _firestore.collection('products').doc(product.id);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final productData = productDoc.data()!;
      final currentQuantity = productData['quantity'] as int;

      // Check if item already exists in cart
      final cartQuery =
          await _firestore
              .collection('carts')
              .where('userId', isEqualTo: userId)
              .where('productId', isEqualTo: product.id)
              .get();

      if (cartQuery.docs.isNotEmpty) {
        // Update existing cart item
        final cartDoc = cartQuery.docs.first;
        final currentCartQuantity = cartDoc.data()['quantity'] as int;
        final newCartQuantity = currentCartQuantity + quantity;

        // Check if the requested quantity plus what's already in the cart exceeds available stock
        if (quantity > currentQuantity) {
          throw Exception('Not enough stock available');
        }

        transaction.update(cartDoc.reference, {'quantity': newCartQuantity});
      } else {
        // For new cart items, just check against current stock
        if (quantity > currentQuantity) {
          throw Exception('Not enough stock available');
        }

        // Add new cart item
        final cartRef = _firestore.collection('carts').doc();
        transaction.set(cartRef, {
          'productId': product.id,
          'userId': userId,
          'productName': product.name,
          'price': product.price,
          'quantity': quantity,
          'category': product.category,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update product quantity
      transaction.update(productRef, {
        'quantity': currentQuantity - quantity,
        'inStock': (currentQuantity - quantity) > 0,
      });
    });
  }

  // Remove item from cart
  Future<void> removeFromCart(CartItem cartItem) async {
    return _firestore.runTransaction((transaction) async {
      // Get the product document
      final productRef = _firestore
          .collection('products')
          .doc(cartItem.productId);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final productData = productDoc.data()!;
      final currentQuantity = productData['quantity'] as int;

      // Delete cart item
      final cartRef = _firestore.collection('carts').doc(cartItem.id);
      transaction.delete(cartRef);

      // Restore product quantity
      transaction.update(productRef, {
        'quantity': currentQuantity + cartItem.quantity,
        'inStock': true,
      });
    });
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(
    CartItem cartItem,
    int newQuantity,
  ) async {
    if (newQuantity <= 0) {
      return removeFromCart(cartItem);
    }

    return _firestore.runTransaction((transaction) async {
      // Get the product document
      final productRef = _firestore
          .collection('products')
          .doc(cartItem.productId);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final productData = productDoc.data()!;
      final currentProductQuantity = productData['quantity'] as int;
      final quantityDifference = newQuantity - cartItem.quantity;

      if (currentProductQuantity < quantityDifference) {
        throw Exception('Not enough stock available');
      }

      // Update cart item quantity
      final cartRef = _firestore.collection('carts').doc(cartItem.id);
      transaction.update(cartRef, {'quantity': newQuantity});

      // Update product quantity
      transaction.update(productRef, {
        'quantity': currentProductQuantity - quantityDifference,
        'inStock': (currentProductQuantity - quantityDifference) > 0,
      });
    });
  }

  // Clear cart
  Future<void> clearCart() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final cartQuery =
        await _firestore
            .collection('carts')
            .where('userId', isEqualTo: userId)
            .get();

    final batch = _firestore.batch();
    for (var doc in cartQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
