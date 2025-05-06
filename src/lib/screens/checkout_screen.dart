import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final List<OrderItem> items;
  final int totalAmount;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  bool _isLoading = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _placeOrder();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_MZAghr8n20yGna',
      'amount': widget.totalAmount * 100, // Convert to paise
      'name': 'Campus Cart',
      'description': 'Order Payment',
      'prefill': {'contact': '9999999999', 'email': 'test@test.com'},
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _orderService.createOrder(widget.items, widget.totalAmount);
      await _cartService.clearCart();

      if (mounted) {
        Navigator.pop(context); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFAB40),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Checkout',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.textScalerOf(context).scale(24),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        item.product.name,
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Quantity: ${item.quantity}',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(14),
                        ),
                      ),
                      trailing: Text(
                        '₹${item.price * item.quantity}',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(16),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFAB40),
                        ),
                      ),
                    ),
                  );
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
                    color: Colors.black.withAlpha(26),
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
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${widget.totalAmount}',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(20),
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
                      onPressed: _isLoading ? null : _openCheckout,
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
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Pay Now',
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
        ),
      ),
    );
  }
}
