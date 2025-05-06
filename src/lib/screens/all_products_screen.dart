import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import '../widgets/quantity_selector_dialog.dart';
import 'dart:convert'; // Add this import for Base64 decoding

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('AllProductsScreen initialized');
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot productsSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .orderBy('createdAt', descending: true)
              .get();

      if (!mounted) return;

      final List<Product> validProducts = [];
      for (var doc in productsSnapshot.docs) {
        try {
          final product = Product.fromFirestore(doc);
          validProducts.add(product);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing product ${doc.id}: $e');
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _products = validProducts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(Product product) async {
    if (_authService.currentUser == null) {
      if (mounted) {
        final shouldLogin = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Login Required'),
                content: const Text('You need to login to add items to cart.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Login'),
                  ),
                ],
              ),
        );

        if (shouldLogin == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          // Refresh data when returning from login
          if (mounted) {
            await _loadProducts();
          }
          return;
        }
      }
    }

    // Show quantity selector dialog
    if (!mounted) return;
    final selectedQuantity = await showDialog<int>(
      context: context,
      builder:
          (context) => QuantitySelectorDialog(maxQuantity: product.quantity),
    );

    if (selectedQuantity == null || selectedQuantity == 0) return;

    try {
      await _cartService.addToCart(product, quantity: selectedQuantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added to cart'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child:
                  product.hasImage && product.imageBase64 != null
                      ? Image.memory(
                        base64Decode(product.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Colors.grey[400],
                          );
                        },
                      )
                      : Icon(Icons.fastfood, size: 40, color: Colors.grey[400]),
            ),
          ),
          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        product.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFAB40),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (product.quantity > 0)
                        GestureDetector(
                          onTap: () => _addToCart(product),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAB40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF628673),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : _products.isEmpty
                ? const Center(
                  child: Text(
                    'No products available',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _buildProductCard(product);
                  },
                ),
      ),
    );
  }
}
