import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../services/firebase_firestore_service.dart';
import '../../models/product_model.dart';
import '../../../config/app_theme.dart';
import '../widgets/product_card.dart';
import '../../routes/app_routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestoreService = FirebaseFirestoreService();
  final _searchCtrl = TextEditingController();
  List<ProductModel> _results = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 1000;
  double _minRating = 0;
  List<String> _categories = [];
  final RxBool _showFilters = false.obs;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _firestoreService.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty &&
        _selectedCategory == null &&
        _minPrice == 0 &&
        _maxPrice == 1000 &&
        _minRating == 0) {
      setState(() {
        _hasSearched = false;
        _results = [];
      });
      return;
    }
    setState(() => _loading = true);
    final products = await _firestoreService.searchProducts(
      query: query,
      category: _selectedCategory,
      minPrice: _minPrice > 0 ? _minPrice : null,
      maxPrice: _maxPrice < 1000 ? _maxPrice : null,
      minRating: _minRating > 0 ? _minRating : null,
    );
    if (mounted)
      setState(() {
        _results = products;
        _loading = false;
        _hasSearched = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    final cc = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onSubmitted: (_) => _search(),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            hintText: 'Search for products...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        actions: [
          Obx(
            () => _showFilters.value
                ? IconButton(
                    icon: const Icon(
                      Icons.filter_alt,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => _showFilters.value = false,
                  )
                : IconButton(
                    icon: const Icon(Icons.filter_alt_outlined),
                    onPressed: () => _showFilters.value = true,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _search,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters bar
          Obx(() {
            if (!_showFilters.value) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chips
                  if (_categories.isNotEmpty) ...[
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9EAA),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length + 1,
                        itemBuilder: (_, i) {
                          final active = i == 0
                              ? _selectedCategory == null
                              : _selectedCategory == _categories[i - 1];
                          final label = i == 0 ? 'All' : _categories[i - 1];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: active ? Colors.white : null,
                                ),
                              ),
                              selected: active,
                              onSelected: (_) {
                                setState(
                                  () => _selectedCategory = i == 0
                                      ? null
                                      : _categories[i - 1],
                                );
                                _search();
                              },
                              selectedColor: AppTheme.primaryColor,
                              checkmarkColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Price range
                  Row(
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9EAA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 1000,
                          divisions: 50,
                          labels: RangeLabels(
                            '\$${_minPrice.toInt()}',
                            '\$${_maxPrice.toInt()}',
                          ),
                          activeColor: AppTheme.primaryColor,
                          onChanged: (v) => setState(() {
                            _minPrice = v.start;
                            _maxPrice = v.end;
                          }),
                          onChangeEnd: (_) => _search(),
                        ),
                      ),
                    ],
                  ),
                  // Rating filter
                  Row(
                    children: [
                      const Text(
                        'Min Rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9EAA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(
                        5,
                        (i) => GestureDetector(
                          onTap: () {
                            setState(() => _minRating = i + 1.0);
                            _search();
                          },
                          child: Icon(
                            i < _minRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 22,
                            color: i < _minRating
                                ? AppTheme.secondaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (_minRating > 0) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _minRating = 0);
                            _search();
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF9E9EAA),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          // Results
          Expanded(child: _buildResults(context, cc, isDark)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, CartController cc, bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (!_hasSearched) {
      return SingleChildScrollView(
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
                            _searchCtrl.text = tag;
                            _search();
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
    if (_results.isEmpty) {
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
              'Try different filters or keywords',
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
      itemCount: _results.length,
      itemBuilder: (_, i) => ProductCard(
        product: _results[i],
        onTap: () =>
            Get.toNamed(AppRoutes.productDetail, arguments: _results[i]),
        onAddToCart: () => cc.addToCart(_results[i]),
      ),
    );
  }
}
