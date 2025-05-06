import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
// import '../widgets/quantity_selector_dialog.dart';
import 'auth/login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  int _quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF2D3250),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : const Color(0xFF2D3250),
                size: 20,
              ),
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Product Image with Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                Hero(
                  tag: 'product_${widget.product.id}',
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildProductImage(widget.product),
                  ),
                ),
                // Gradient Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.4),

                // Product Info Container with Curved Top
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name and Category
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.product.name,
                                            style: const TextStyle(
                                              color: Color(0xFF2D3250),
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF628673,
                                              ).withAlpha(26),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getCategoryIcon(
                                                    widget.product.category,
                                                  ),
                                                  color: const Color(
                                                    0xFF628673,
                                                  ),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  widget.product.category,
                                                  style: const TextStyle(
                                                    color: Color(0xFF628673),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2D3250),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF2D3250,
                                            ).withAlpha(30),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '₹${widget.product.price}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFAB40),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Description Section with Card
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'About this product',
                                        style: TextStyle(
                                          color: Color(0xFF2D3250),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Divider
                                      Container(
                                        height: 2,
                                        width: 50,
                                        color: const Color(
                                          0xFFFFAB40,
                                        ).withAlpha(77),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                      ),
                                      // Description
                                      widget.product.description.isNotEmpty
                                          ? Text(
                                            widget.product.description,
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 16,
                                              height: 1.5,
                                            ),
                                          )
                                          : Text(
                                            'No description provided by the seller.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      if (widget.product.description.isNotEmpty)
                                        const SizedBox(height: 16),

                                      // Additional product details that could be added in the future
                                      // Seller information or other metadata could go here
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Quantity Section
                                if (widget.product.quantity > 0)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Quantity',
                                              style: TextStyle(
                                                color: Color(0xFF2D3250),
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${widget.product.quantity} available',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF628673),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.remove,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    onPressed:
                                                        _quantity > 1
                                                            ? () => setState(
                                                              () => _quantity--,
                                                            )
                                                            : null,
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    child: Text(
                                                      _quantity.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    onPressed:
                                                        _quantity <
                                                                widget
                                                                    .product
                                                                    .quantity
                                                            ? () => setState(
                                                              () => _quantity++,
                                                            )
                                                            : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 32),

                                // Add to Cart Button
                                if (widget.product.quantity > 0)
                                  Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF628673),
                                          Color(0xFF466857),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF628673,
                                          ).withAlpha(30),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _addToCart,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Add to Cart • ₹${widget.product.price * _quantity}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Out of Stock',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    Widget imageWidget;
    if (product.hasImage && product.imageBase64 != null) {
      try {
        final bytes = base64Decode(product.imageBase64!);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        imageWidget = _buildPlaceholder();
      }
    } else if (product.imageUrl != null) {
      imageWidget = Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return Container(
      decoration: BoxDecoration(color: Colors.grey[100]),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(Icons.image_outlined, size: 80, color: Colors.grey[400]),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'drinks':
      case 'beverages':
        return Icons.local_drink;
      case 'snacks':
        return Icons.cookie;
      case 'food':
      case 'meals':
        return Icons.restaurant;
      case 'fruits':
        return Icons.apple;
      case 'groceries':
        return Icons.shopping_basket;
      case 'dairy':
        return Icons.egg;
      case 'sweets':
      case 'desserts':
        return Icons.cake;
      default:
        return Icons.local_mall;
    }
  }

  Future<void> _addToCart() async {
    if (_authService.currentUser == null) {
      if (mounted) {
        final shouldLogin = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
        }
        return;
      }
    }

    try {
      await _cartService.addToCart(widget.product, quantity: _quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product added to cart'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
