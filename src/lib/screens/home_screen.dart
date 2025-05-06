import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'auth/login_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'all_products_screen.dart';
import '../widgets/quantity_selector_dialog.dart';
import 'dart:convert'; // Add this for Base64 encoding
import 'order_history_screen.dart';
import 'all_categories_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Product> _products = [];
  String _selectedCategory = 'All';
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // Helper methods for responsive font sizes
  double getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSize * 0.8;
    } else if (screenWidth < 400) {
      return baseSize * 0.9;
    } else if (screenWidth < 450) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  TextStyle getTitleStyle(BuildContext context) {
    return TextStyle(
      color: const Color(0xFF2D3250),
      fontSize: getResponsiveFontSize(context, 24),
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    );
  }

  TextStyle getSectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, 20),
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  TextStyle getProductTitleStyle(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: getResponsiveFontSize(context, 16),
    );
  }

  TextStyle getProductCategoryStyle(BuildContext context) {
    return TextStyle(
      color: Colors.grey[600],
      fontSize: getResponsiveFontSize(context, 12),
    );
  }

  TextStyle getProductPriceStyle(BuildContext context) {
    return TextStyle(
      color: const Color(0xFFFFAB40),
      fontWeight: FontWeight.bold,
      fontSize: getResponsiveFontSize(context, 16),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    if (kDebugMode) {
      print('HomeScreen initialized');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >= 400) {
      if (!_showBackToTop) {
        setState(() {
          _showBackToTop = true;
        });
      }
    } else {
      if (_showBackToTop) {
        setState(() {
          _showBackToTop = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
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

      setState(() {
        _products =
            productsSnapshot.docs
                .map((doc) => Product.fromFirestore(doc))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading products: $e');
      }
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
    // Check if user is authenticated
    if (_authService.currentUser == null) {
      if (mounted) {
        // Show dialog to prompt user to login
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

        if (shouldLogin == true) {
          if (mounted) {
            // Navigate to login screen
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
        return;
      }
    }

    // Show quantity selector dialog
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
      // Reload products to update quantities
      await _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;

      if (_searchQuery.isEmpty) {
        return matchesCategory;
      }

      // Split search query into words for more flexible matching
      final searchWords = _searchQuery.toLowerCase().split(' ');

      // Check if any of the search words match the beginning of product fields
      bool matchesSearch = searchWords.every((word) {
        return product.name.toLowerCase().startsWith(word) ||
            product.name.toLowerCase().contains(' $word') ||
            product.description.toLowerCase().startsWith(word) ||
            product.description.toLowerCase().contains(' $word') ||
            product.category.toLowerCase().startsWith(word) ||
            product.category.toLowerCase().contains(' $word');
      });

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Building HomeScreen');
    }

    return WillPopScope(
      onWillPop: () async {
        bool? exitConfirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  'Exit App',
                  style: TextStyle(color: Color(0xFF2D3250)),
                ),
                content: const Text('Do you want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'No',
                      style: TextStyle(color: Color(0xFF2D3250)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Color(0xFFFFAB40)),
                    ),
                  ),
                ],
              ),
        );
        return exitConfirmed ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFAB40),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            color: const Color(0xFF2D3250),
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header with title and actions
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        color: const Color(0xFFFFAB40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CAMPUS CART', style: getTitleStyle(context)),
                            IconButton(
                              icon: const Icon(
                                Icons.history,
                                color: Color(0xFF2D3250),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Search Bar Section
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB40),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: Color(0xFFFFAB40),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search products...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF2D3250),
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _clearSearch,
                                ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFAB40).withAlpha(26),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: Color(0xFFFFAB40),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Main Content with improved spacing and shadows
                      Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 180,
                          maxHeight: MediaQuery.of(context).size.height - 180,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF628673),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCategoriesSection(),

                            // Products Section with improved header
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Products',
                                    style: getSectionTitleStyle(
                                      context,
                                    ).copyWith(
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withAlpha(26),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(26),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(26),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const AllProductsScreen(),
                                          ),
                                        );
                                        if (mounted) {
                                          await _loadProducts();
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.grid_view,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'View All',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: getResponsiveFontSize(
                                            context,
                                            14,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Products Grid with improved loading and empty states
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child:
                                    _isLoading
                                        ? _buildLoadingSkeleton()
                                        : filteredProducts.isEmpty
                                        ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.shopping_bag_outlined,
                                                color: Colors.white.withAlpha(
                                                  179,
                                                ),
                                                size: 64,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No products available',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      getResponsiveFontSize(
                                                        context,
                                                        18,
                                                      ),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        : GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                childAspectRatio: 0.65,
                                                mainAxisSpacing: 12,
                                                crossAxisSpacing: 12,
                                              ),
                                          itemCount: filteredProducts.length,
                                          padding: const EdgeInsets.only(
                                            bottom: 80,
                                          ),
                                          itemBuilder: (context, index) {
                                            final product =
                                                filteredProducts[index];
                                            return _buildProductCard(product);
                                          },
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showBackToTop)
                  Positioned(
                    right: 20,
                    bottom: 100,
                    child: FloatingActionButton(
                      onPressed: _scrollToTop,
                      backgroundColor: const Color(0xFF2D3250),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFFFAB40),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) async {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
          await _loadProducts();
        }
      });
    }
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = category == _selectedCategory;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        elevation: isSelected ? 4 : 2,
        borderRadius: BorderRadius.circular(20),
        color: isSelected ? const Color(0xFF2D3250) : Colors.white,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected
                        ? Colors.transparent
                        : const Color(0xFF2D3250).withAlpha(26),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF2D3250),
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF2D3250),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.category;
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

  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(26),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      final selectedCategory = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllCategoriesScreen(),
                        ),
                      );
                      if (selectedCategory != null && mounted) {
                        setState(() {
                          _selectedCategory = selectedCategory;
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.grid_view,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'See All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: StreamBuilder<List<String>>(
              stream: _categoryService.getAllCategories(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = ['All', ...?snapshot.data];

                return ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: categories.map(_buildCategoryChip).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              spreadRadius: 0,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: _buildProductImage(product),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(6),
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
                          style: getProductTitleStyle(context),
                        ),
                        Text(
                          product.category,
                          style: getProductCategoryStyle(context),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price.toString()}',
                          style: getProductPriceStyle(context),
                        ),
                        if (product.quantity > 0)
                          GestureDetector(
                            onTap: () => _addToCart(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3250),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(26),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    color: Color(0xFFFFAB40),
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Color(0xFFFFAB40),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.hasImage && product.imageBase64 != null) {
      try {
        final bytes = base64Decode(product.imageBase64!);
        return Hero(
          tag: 'product_${product.id}',
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[100]),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.fastfood, size: 60, color: Colors.grey[400]);
              },
            ),
          ),
        );
      } catch (e) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[100],
          child: Icon(Icons.fastfood, size: 60, color: Colors.grey[400]),
        );
      }
    } else if (product.imageUrl != null) {
      return Hero(
        tag: 'product_${product.id}',
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[100]),
          child: Image.network(
            product.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.fastfood, size: 60, color: Colors.grey[400]);
            },
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[100],
        child: Icon(Icons.fastfood, size: 60, color: Colors.grey[400]),
      );
    }
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white.withAlpha(51),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      color: Colors.white.withAlpha(51),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 20,
                      width: 40,
                      color: Colors.white.withAlpha(51),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
