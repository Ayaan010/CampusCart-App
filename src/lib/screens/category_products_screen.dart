import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import 'dart:convert';

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String? _selectedSubcategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF628673),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFAB40),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Color(0xFF2D3250),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (widget.category.toLowerCase() == 'coffee')
            _buildSubcategorySelector(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final products =
                    snapshot.data?.docs
                        .map((doc) => Product.fromFirestore(doc))
                        .toList() ??
                    [];

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.white.withAlpha(179),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products available in ${_selectedSubcategory ?? widget.category}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.category.toLowerCase() == 'coffee') ...[
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await CategoryService()
                                    .addSampleCoffeeProducts();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sample coffee products added successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error adding products: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFAB40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add Sample Products',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategorySelector() {
    final subcategories = [
      'All Coffee',
      'Hot Coffee',
      'Cold Coffee',
      'Specialty Coffee',
      'Coffee Beans',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          final isSelected = _selectedSubcategory == subcategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(subcategory),
              onSelected: (selected) {
                setState(() {
                  _selectedSubcategory = selected ? subcategory : null;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFFAB40),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D3250),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getProductsStream() {
    var query = FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: widget.category)
        .orderBy('createdAt', descending: true);

    if (widget.category.toLowerCase() == 'coffee' &&
        _selectedSubcategory != null) {
      if (_selectedSubcategory == 'All Coffee') {
        return query.snapshots();
      } else {
        return query
            .where('subcategory', isEqualTo: _selectedSubcategory)
            .snapshots();
      }
    }

    return query.snapshots();
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: _buildProductImage(product),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
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
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toString()}',
                        style: const TextStyle(
                          color: Color(0xFFFFAB40),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (product.quantity > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFAB40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'In Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.hasImage && product.imageBase64 != null) {
      try {
        final bytes = base64Decode(product.imageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.fastfood, size: 40, color: Colors.grey[400]);
          },
        );
      } catch (e) {
        return Icon(Icons.fastfood, size: 40, color: Colors.grey[400]);
      }
    } else if (product.imageUrl != null) {
      return Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.fastfood, size: 40, color: Colors.grey[400]);
        },
      );
    } else {
      return Icon(Icons.fastfood, size: 40, color: Colors.grey[400]);
    }
  }
}
