import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger_util.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  // Get all categories as a stream
  Stream<List<String>> getAllCategories() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Try to get the name field, if not available, use the document ID
          return data['name']?.toString() ?? doc.id;
        }).toList();
      } catch (e) {
        LoggerUtil.error('Error getting categories', e);
        return [];
      }
    });
  }

  // Add a new category
  Future<void> addCategory(String name) async {
    try {
      // Check if category already exists
      final existingCategory =
          await _firestore
              .collection(_collection)
              .where('name', isEqualTo: name)
              .get();

      if (existingCategory.docs.isNotEmpty) {
        throw Exception('Category already exists');
      }

      await _firestore.collection(_collection).add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      LoggerUtil.error('Error adding category', e);
      rethrow;
    }
  }

  // Delete a category
  Future<void> deleteCategory(String name) async {
    try {
      final categoryDocs =
          await _firestore
              .collection(_collection)
              .where('name', isEqualTo: name)
              .get();

      if (categoryDocs.docs.isEmpty) {
        throw Exception('Category not found');
      }

      // Check if any products are using this category
      final productsWithCategory =
          await _firestore
              .collection('products')
              .where('category', isEqualTo: name)
              .get();

      if (productsWithCategory.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete category: Products are using this category',
        );
      }

      await _firestore
          .collection(_collection)
          .doc(categoryDocs.docs.first.id)
          .delete();
    } catch (e) {
      LoggerUtil.error('Error deleting category', e);
      rethrow;
    }
  }

  // Update a category
  Future<void> updateCategory(String oldName, String newName) async {
    try {
      final categoryDocs =
          await _firestore
              .collection(_collection)
              .where('name', isEqualTo: oldName)
              .get();

      if (categoryDocs.docs.isEmpty) {
        throw Exception('Category not found');
      }

      // Check if new name already exists
      final existingCategory =
          await _firestore
              .collection(_collection)
              .where('name', isEqualTo: newName)
              .get();

      if (existingCategory.docs.isNotEmpty) {
        throw Exception('Category with new name already exists');
      }

      // Update category name
      await _firestore
          .collection(_collection)
          .doc(categoryDocs.docs.first.id)
          .update({'name': newName});

      // Update all products with this category
      final batch = _firestore.batch();
      final productsWithCategory =
          await _firestore
              .collection('products')
              .where('category', isEqualTo: oldName)
              .get();

      for (var doc in productsWithCategory.docs) {
        batch.update(doc.reference, {'category': newName});
      }

      await batch.commit();
    } catch (e) {
      LoggerUtil.error('Error updating category', e);
      rethrow;
    }
  }

  // Add sample coffee products
  Future<void> addSampleCoffeeProducts() async {
    try {
      final products = [
        // Hot Coffee
        {
          'name': 'Classic Espresso',
          'description': 'Rich and bold hot espresso',
          'price': 150,
          'quantity': 10,
          'category': 'Coffee',
          'subcategory': 'Hot Coffee',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Hot Latte',
          'description': 'Smooth hot coffee with steamed milk',
          'price': 200,
          'quantity': 15,
          'category': 'Coffee',
          'subcategory': 'Hot Coffee',
          'createdAt': FieldValue.serverTimestamp(),
        },
        // Cold Coffee
        {
          'name': 'Iced Americano',
          'description': 'Refreshing cold coffee',
          'price': 180,
          'quantity': 12,
          'category': 'Coffee',
          'subcategory': 'Cold Coffee',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Cold Brew',
          'description': 'Smooth cold brewed coffee',
          'price': 220,
          'quantity': 8,
          'category': 'Coffee',
          'subcategory': 'Cold Coffee',
          'createdAt': FieldValue.serverTimestamp(),
        },
        // Specialty Coffee
        {
          'name': 'Caramel Macchiato',
          'description':
              'Vanilla-flavored drink marked with espresso and caramel',
          'price': 250,
          'quantity': 10,
          'category': 'Coffee',
          'subcategory': 'Specialty Coffee',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Mocha Frappuccino',
          'description': 'Blended coffee with chocolate and whipped cream',
          'price': 280,
          'quantity': 15,
          'category': 'Coffee',
          'subcategory': 'Specialty Coffee',
          'createdAt': FieldValue.serverTimestamp(),
        },
        // Coffee Beans
        {
          'name': 'Arabica Coffee Beans',
          'description': 'Premium coffee beans for brewing',
          'price': 500,
          'quantity': 20,
          'category': 'Coffee',
          'subcategory': 'Coffee Beans',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Robusta Coffee Beans',
          'description': 'Strong and bold coffee beans',
          'price': 450,
          'quantity': 15,
          'category': 'Coffee',
          'subcategory': 'Coffee Beans',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add each product to Firestore
      for (var product in products) {
        await _firestore.collection('products').add(product);
      }

      LoggerUtil.info('Sample coffee products added successfully');
    } catch (e) {
      LoggerUtil.error('Error adding sample coffee products', e);
      rethrow;
    }
  }
}
