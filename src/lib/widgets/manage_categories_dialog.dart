import 'package:flutter/material.dart';
import '../services/category_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCategoriesDialog extends StatefulWidget {
  const ManageCategoriesDialog({super.key});

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  final CategoryService _categoryService = CategoryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _categoryController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  List<Map<String, dynamic>> _categoryProducts = [];

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryProducts(String categoryName) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = categoryName;
    });

    try {
      final products = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryName)
          .get();

      setState(() {
        _categoryProducts = products.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _categoryService.addCategory(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _categoryController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCategory(String name) async {
    setState(() => _isLoading = true);

    try {
      await _categoryService.deleteCategory(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3250),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter category name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFAB40),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _categoryService.getAllCategories(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = snapshot.data!;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteCategory(category),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                onTap: () => _loadCategoryProducts(category),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_selectedCategory != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Products in $_selectedCategory',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3250),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_isLoading)
                                  const Center(child: CircularProgressIndicator())
                                else if (_categoryProducts.isEmpty)
                                  const Center(
                                    child: Text(
                                      'No products in this category',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _categoryProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = _categoryProducts[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            product['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '₹${product['price']?.toStringAsFixed(2) ?? '0.00'} - Stock: ${product['quantity'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
