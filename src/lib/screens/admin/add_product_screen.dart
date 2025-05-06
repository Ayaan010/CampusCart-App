import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/logger_util.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'category': _categoryController.text.trim(),
        'imageUrl': _imageUrl,
        'inStock': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('products').add(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFAB40),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add Product',
          style: TextStyle(
            color: Color(0xFF2D3250),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF628673),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Product Name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _priceController,
                            label: 'Price (₹)',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product price';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _categoryController,
                            label: 'Category',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child:
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : ElevatedButton(
                                      onPressed: _addProduct,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF004D40,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add Product',
                                        style: TextStyle(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
