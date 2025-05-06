import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/logger_util.dart';
import '../login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Add this for Base64 encoding
import 'orders_screen.dart';
import '../../services/category_service.dart';
import '../../widgets/manage_categories_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = false;
  List<DocumentSnapshot> _products = [];
  File? _selectedImage;
  String? _base64Image;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterCategory = 'All';
  List<String> _categories = ['All'];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedCategory = '';
  String? _selectedImageBase64;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadInitialCategory();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadInitialCategory() async {
    final categories = await _categoryService.getAllCategories().first;
    if (categories.isNotEmpty && mounted) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories().first;
      if (mounted) {
        setState(() {
          _categories = ['All', ...categories];
        });
      }
    } catch (e) {
      LoggerUtil.error('Error loading categories', e);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Smaller size for Base64
        maxHeight: 800,
        imageQuality: 70, // Lower quality to reduce size
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        // Convert to Base64
        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImage = File(image.path);
          _base64Image = base64String;
        });
      }
    } catch (e) {
      LoggerUtil.error('Error picking image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<DocumentSnapshot> get filteredProducts {
    if (_searchQuery.isEmpty && _selectedFilterCategory == 'All') {
      return _products;
    }
    return _products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final category = data['category']?.toString().toLowerCase() ?? '';

      final matchesCategory =
          _selectedFilterCategory == 'All' ||
          category == _selectedFilterCategory.toLowerCase();

      if (_searchQuery.isEmpty) {
        return matchesCategory;
      }

      return matchesCategory &&
          (name.contains(_searchQuery) ||
              description.contains(_searchQuery) ||
              category.contains(_searchQuery));
    }).toList();
  }

  Widget _buildAddProductDialog() {
    return AlertDialog(
      title: const Text('Add New Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<String>>(
                stream: _categoryService.getAllCategories(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return const Text(
                      'Please add categories first',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  // Update selected category if not set or not in the list
                  if (_selectedCategory.isEmpty ||
                      !categories.contains(_selectedCategory)) {
                    _selectedCategory = categories.first;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectedCategory = newValue;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedImageBase64 != null
                      ? 'Change Image'
                      : 'Select Image',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3250),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D3250),
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Add Product'),
        ),
      ],
    );
  }

  Future<void> _addProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate price and quantity
      final int quantity = int.parse(_quantityController.text.trim());

      if (quantity < 0) {
        throw Exception('Quantity must be positive');
      }

      // Add product to Firestore with Base64 image
      await _firestore.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'quantity': quantity,
        'category': _selectedCategory,
        'imageBase64': _base64Image,
        'hasImage': _base64Image != null,
        'inStock': quantity > 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form and image
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _quantityController.clear();
      _selectedCategory = '';
      setState(() {
        _selectedImage = null;
        _base64Image = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadProducts();
      }
    } catch (e) {
      LoggerUtil.error('Error adding product', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: ${e.toString()}'),
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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot productsSnapshot =
          await _firestore
              .collection('products')
              .orderBy('createdAt', descending: true)
              .get();

      setState(() {
        _products = productsSnapshot.docs;
      });
    } catch (e) {
      LoggerUtil.error('Error loading products', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('products').doc(productId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadProducts(); // Reload the products list
    } catch (e) {
      LoggerUtil.error('Error deleting product', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: ${e.toString()}'),
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

  void _showEditProductDialog(DocumentSnapshot product) {
    final data = product.data() as Map<String, dynamic>;
    String localSelectedCategory = data['category'] ?? '';

    // Pre-fill the form with existing data
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _quantityController.text = data['quantity']?.toString() ?? '';
    _base64Image = data['imageBase64'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image picker button and preview
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _pickImage();
                          setDialogState(() {}); // Refresh dialog to show image
                        },
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Text(
                          'Select Product Image',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImage != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ] else if (data['hasImage'] == true &&
                          data['imageBase64'] != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(data['imageBase64']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (₹)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          final int? price = int.tryParse(value);
                          if (price == null) {
                            return 'Please enter a valid number';
                          }
                          if (price < 0) {
                            return 'Price cannot be negative';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<String>>(
                        stream: _categoryService.getAllCategories(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final categories = snapshot.data ?? [];
                          if (categories.isEmpty) {
                            return const Text(
                              'Please add categories first',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          // Initialize the local category if needed
                          if (localSelectedCategory.isEmpty ||
                              !categories.contains(localSelectedCategory)) {
                            localSelectedCategory = categories.first;
                          }

                          return DropdownButtonFormField<String>(
                            value: localSelectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                categories.map((String category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  localSelectedCategory = newValue;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear form
                    _nameController.clear();
                    _descriptionController.clear();
                    _priceController.clear();
                    _quantityController.clear();
                    _base64Image = null;
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _selectedCategory =
                        localSelectedCategory; // Update the global category before updating
                    _updateProduct(product.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Update Product',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProduct(String productId) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Validate price and quantity
        final int quantity = int.parse(_quantityController.text.trim());

        if (quantity < 0) {
          throw Exception('Quantity must be positive');
        }

        // Create update data
        final Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': int.parse(_priceController.text.trim()),
          'quantity': quantity,
          'category': _selectedCategory,
          'inStock': quantity > 0,
        };

        // Add image data if a new image was selected
        if (_selectedImage != null && _base64Image != null) {
          updateData['imageBase64'] = _base64Image;
          updateData['hasImage'] = true;
        }

        // Update product in Firestore
        await _firestore
            .collection('products')
            .doc(productId)
            .update(updateData);

        // Clear form and close dialog
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _quantityController.clear();
        _selectedCategory = '';
        setState(() {
          _selectedImage = null;
          _base64Image = null;
        });

        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload products
          await _loadProducts();
        }
      } catch (e) {
        LoggerUtil.error('Error updating product', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating product: ${e.toString()}'),
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text(
                  'Exit Admin Dashboard',
                  style: TextStyle(
                    color: Color(0xFF2D3250),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Are you sure you want to exit the admin dashboard?',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF2D3250)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3250),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Exit'),
                  ),
                ],
              ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFAB40),
          elevation: 0,
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Color(0xFF2D3250),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Color(0xFF2D3250),
                  size: 28,
                ),
                onPressed: _signOut,
                tooltip: 'Sign Out',
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3250),
                          ),
                        ),
                        if (!_isLoading)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadProducts,
                            tooltip: 'Refresh Products',
                            color: const Color(0xFF2D3250),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFAB40),
                          ),
                        ),
                      )
                    else if (_products.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Color(0xFF2D3250),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No products available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF2D3250),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => _buildAddProductDialog(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFAB40),
                                foregroundColor: const Color(0xFF2D3250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Add Your First Product'),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final data = product.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(13),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child:
                                          data['hasImage'] == true &&
                                                  data['imageBase64'] != null
                                              ? Image.memory(
                                                base64Decode(
                                                  data['imageBase64'],
                                                ),
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    color: Colors.grey[100],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Color(0xFF2D3250),
                                                    ),
                                                  );
                                                },
                                              )
                                              : Container(
                                                color: Colors.grey[100],
                                                child: const Icon(
                                                  Icons.image,
                                                  color: Color(0xFF2D3250),
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unnamed Product',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D3250),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['description'] ??
                                              'No description',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFFFAB40,
                                                ).withAlpha(26),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '₹${data['price']?.toString() ?? '0'}',
                                                style: const TextStyle(
                                                  color: Color(0xFF2D3250),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF2D3250,
                                                ).withAlpha(26),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Stock: ${data['quantity']?.toString() ?? '0'}',
                                                style: const TextStyle(
                                                  color: Color(0xFF2D3250),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: const Color(0xFF2D3250),
                                        onPressed:
                                            () =>
                                                _showEditProductDialog(product),
                                        tooltip: 'Edit Product',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        onPressed:
                                            () => _deleteProduct(product.id),
                                        tooltip: 'Delete Product',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFAB40),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3250),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 48) / 3;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionCard(
                    icon: Icons.add_box,
                    label: 'Add\nProduct',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _buildAddProductDialog(),
                      );
                    },
                    width: cardWidth,
                  ),
                  _buildActionCard(
                    icon: Icons.category,
                    label: 'Manage\nCategories',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ManageCategoriesDialog(),
                      );
                    },
                    width: cardWidth,
                  ),
                  _buildActionCard(
                    icon: Icons.shopping_cart,
                    label: 'Manage\nOrders',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersScreen(),
                        ),
                      );
                    },
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Add Search Bar and Category Filter
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF2D3250),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButton<String>(
                    value: _selectedFilterCategory,
                    icon: const Icon(
                      Icons.filter_list,
                      color: Color(0xFF2D3250),
                    ),
                    underline: Container(),
                    items: [
                      ..._categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFilterCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required double width,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2D3250)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3250),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
