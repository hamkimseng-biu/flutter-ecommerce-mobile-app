import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/product_controller.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../models/product_model.dart';
import '../../../../../config/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../../routes/app_routes.dart';

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
  final List<String> _selectedCategories = [];
  double _minPrice = 0;
  double _maxPrice = 1000;
  double _minRating = 0;
  final RxBool _showFilters = false.obs;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search();
    });
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty &&
        _selectedCategories.isEmpty &&
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
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
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
    final pc = Get.find<ProductController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSec = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                _showFilters.value
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: _showFilters.value ? AppTheme.primaryColor : null,
              ),
              onPressed: () => _showFilters.toggle(),
              splashRadius: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search bar — matches home page exactly
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 4, 16, 4),
            child: SearchBarWidget(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) {
                setState(() {});
                _onSearchChanged(v);
              },
              onSubmitted: (_) => _search(),
            ),
          ),
          // Filters bar
          Obx(() {
            if (!_showFilters.value) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chips
                  if (pc.categories.length > 1) ...[
                    Row(
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSec,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pc.categories.length,
                        itemBuilder: (_, i) {
                          final cat = pc.categories[i];
                          // index 0 = "All" — selecting it clears others
                          final isAll = i == 0;
                          final active = isAll
                              ? _selectedCategories.isEmpty
                              : _selectedCategories.contains(cat.name);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: active ? Colors.white : textSec,
                                ),
                              ),
                              selected: active,
                              onSelected: (_) {
                                setState(() {
                                  if (isAll) {
                                    _selectedCategories.clear();
                                  } else {
                                    if (active) {
                                      _selectedCategories.remove(cat.name);
                                    } else {
                                      _selectedCategories.add(cat.name);
                                    }
                                  }
                                });
                                _search();
                              },
                              selectedColor: AppTheme.primaryColor,
                              checkmarkColor: Colors.white,
                              backgroundColor: isDark
                                  ? AppTheme.darkSurface2
                                  : const Color(0xFFF1F3F5),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFD0D0D6),
                                width: 0.5,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Price range
                  Row(
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSec,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '\$${_minPrice.toInt()}',
                        style: TextStyle(fontSize: 11, color: textSec),
                      ),
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 1000,
                          divisions: 50,
                          activeColor: AppTheme.primaryColor,
                          inactiveColor: isDark
                              ? AppTheme.darkSurface2
                              : const Color(0xFFE0E0E0),
                          onChanged: (v) => setState(() {
                            _minPrice = v.start;
                            _maxPrice = v.end;
                          }),
                          onChangeEnd: (_) => _search(),
                        ),
                      ),
                      Text(
                        '\$${_maxPrice.toInt()}',
                        style: TextStyle(fontSize: 11, color: textSec),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating filter
                  Row(
                    children: [
                      Text(
                        'Min Rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSec,
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
                            size: 24,
                            color: i < _minRating
                                ? AppTheme.secondaryColor
                                : (isDark
                                      ? AppTheme.darkSurface2
                                      : Colors.grey.shade300),
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
          Expanded(child: _buildResults(context, cc, isDark, textPri, textSec)),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    CartController cc,
    bool isDark,
    Color textPri,
    Color textSec,
  ) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (!_hasSearched) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Searches',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPri,
              ),
            ),
            const SizedBox(height: 14),
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
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkSurface2
                                  : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : const Color(0xFF555555),
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
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPri,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try different filters or keywords',
              style: TextStyle(fontSize: 13, color: textSec),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
