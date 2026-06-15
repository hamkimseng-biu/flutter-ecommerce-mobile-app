import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../../config/app_theme.dart';
import '../widgets/product_card.dart';
import '../../routes/app_routes.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<ProductController>();
    final cc = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchCtrl = TextEditingController();
    final RxBool searching = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchCtrl,
          autofocus: true,
          onChanged: (v) {
            searching.value = v.isNotEmpty;
            pc.searchProducts(v);
          },
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: 'Search for products...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        actions: [
          Obx(
            () => searching.value
                ? IconButton(
                    onPressed: () {
                      searchCtrl.clear();
                      searching.value = false;
                      pc.searchProducts('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Obx(() {
        if (!searching.value) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Popular Searches',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'T-Shirt',
                            'Dress',
                            'Sneakers',
                            'Jacket',
                            'Bag',
                            'Denim',
                            'Electronics',
                            'Home',
                          ]
                          .map(
                            (tag) => GestureDetector(
                              onTap: () {
                                searchCtrl.text = tag;
                                searching.value = true;
                                pc.searchProducts(tag);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkSurface2
                                      : const Color(0xFFF1F3F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : const Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          );
        }
        final results = pc.filteredProducts;
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 14),
                const Text(
                  'No products found',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: results.length,
          itemBuilder: (ctx, i) => ProductCard(
            product: results[i],
            onTap: () =>
                Get.toNamed(AppRoutes.productDetail, arguments: results[i]),
            onAddToCart: () => cc.addToCart(results[i]),
          ),
        );
      }),
    );
  }
}
