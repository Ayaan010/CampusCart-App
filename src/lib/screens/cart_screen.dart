import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
// import '../services/order_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFAB40),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cart',
          style: TextStyle(
            color: const Color(0xFF2D3250),
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.textScalerOf(context).scale(20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3250)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF628673),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: StreamBuilder<List<CartItem>>(
          stream: _cartService.getCartItems(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.textScalerOf(context).scale(16),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            final cartItems = snapshot.data!;
            if (cartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: MediaQuery.of(context).size.width * 0.2,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.textScalerOf(context).scale(18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some items to your cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.textScalerOf(context).scale(14),
                      ),
                    ),
                  ],
                ),
              );
            }

            final total = cartItems.fold<double>(
              0,
              (sum, item) => sum + item.totalPrice,
            );

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(cartItems[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).toInt()),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: MediaQuery.textScalerOf(
                                context,
                              ).scale(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: MediaQuery.textScalerOf(
                                context,
                              ).scale(20),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF004D40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              cartItems.isEmpty
                                  ? null
                                  : () {
                                    final orderItems =
                                        cartItems.map((item) {
                                          return OrderItem(
                                            product: item.toProduct(),
                                            quantity: item.quantity,
                                            price: item.price.toInt(),
                                          );
                                        }).toList();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CheckoutScreen(
                                              items: orderItems,
                                              totalAmount: total.toInt(),
                                            ),
                                      ),
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3250),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Product Image or Icon
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.width * 0.2,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(16),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toString()}',
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(14),
                      color: const Color(0xFFFFAB40),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity Controls
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            () => _updateQuantity(item, item.quantity - 1),
                        iconSize: MediaQuery.of(context).size.width * 0.06,
                      ),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed:
                            () => _updateQuantity(item, item.quantity + 1),
                        iconSize: MediaQuery.of(context).size.width * 0.06,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeFromCart(item),
                        color: Colors.red,
                        iconSize: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(CartItem item, int newQuantity) async {
    try {
      await _cartService.updateCartItemQuantity(item, newQuantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeFromCart(CartItem item) async {
    try {
      await _cartService.removeFromCart(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
