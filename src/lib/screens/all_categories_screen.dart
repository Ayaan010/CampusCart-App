import 'package:flutter/material.dart';
import '../services/category_service.dart';
// import 'category_products_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF628673),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFAB40),
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: Color(0xFF2D3250),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<String>>(
        stream: CategoryService().getAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white.withAlpha(179),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading categories',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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

          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.white.withAlpha(179),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No categories available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please add some categories to get started',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(context, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String category) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Return the selected category back to the previous screen
            Navigator.pop(context, category);
          },
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 40,
                color: const Color(0xFF2D3250),
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'drinks':
      case 'beverages':
      case 'coffee':
      case 'tea':
      case 'juice':
        return Icons.local_drink;
      case 'snacks':
      case 'chips':
      case 'cookies':
      case 'nuts':
        return Icons.cookie;
      case 'food':
      case 'meals':
      case 'lunch':
      case 'dinner':
      case 'breakfast':
        return Icons.restaurant;
      case 'fruits':
      case 'vegetables':
      case 'produce':
        return Icons.apple;
      case 'groceries':
      case 'household':
      case 'cleaning':
        return Icons.shopping_basket;
      case 'dairy':
      case 'milk':
      case 'cheese':
      case 'yogurt':
        return Icons.egg;
      case 'sweets':
      case 'desserts':
      case 'chocolate':
      case 'candy':
        return Icons.cake;
      case 'bakery':
      case 'bread':
      case 'pastries':
        return Icons.bakery_dining;
      case 'frozen':
      case 'ice cream':
        return Icons.ac_unit;
      case 'pantry':
      case 'canned':
      case 'dry goods':
        return Icons.kitchen;
      case 'personal care':
      case 'toiletries':
      case 'hygiene':
        return Icons.self_improvement;
      case 'electronics':
      case 'gadgets':
        return Icons.devices;
      case 'stationery':
      case 'office':
        return Icons.edit_note;
      case 'health':
      case 'medicine':
      case 'vitamins':
        return Icons.local_pharmacy;
      case 'sports':
      case 'fitness':
        return Icons.sports;
      case 'toys':
      case 'games':
        return Icons.toys;
      case 'clothing':
      case 'fashion':
        return Icons.checkroom;
      case 'books':
      case 'magazines':
        return Icons.book;
      case 'home decor':
      case 'accessories':
        return Icons.home;
      case 'pet supplies':
      case 'pets':
        return Icons.pets;
      case 'baby':
      case 'kids':
        return Icons.child_care;
      case 'garden':
      case 'outdoor':
        return Icons.eco;
      case 'all':
        return Icons.category;
      default:
        return Icons.local_mall;
    }
  }
}
