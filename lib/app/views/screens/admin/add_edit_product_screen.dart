import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/product_model.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';

/// Full-screen page for adding or editing a product.
/// Receives an optional ProductModel via Get.arguments for edit mode.
class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _firestore = FirebaseFirestore.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountPctCtrl;
  late final TextEditingController _flashDiscountCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _soldCountCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _reviewCountCtrl;

  List<String> _images = [];
  List<String> _detailImages = [];
  List<String> _sizes = ['S', 'M', 'L', 'XL'];
  List<String> _colors = [];
  bool _isFeatured = false;
  bool _isFlashSale = false;
  bool _showSoldCount = true;
  bool _showRating = true;
  bool _showReviewCount = true;
  bool _freeShipping = false;
  bool _saving = false;
  bool _isEdit = false;
  ProductModel? _existing;
  String _sellerId = '';
  String _sellerName = 'Tiny Chicken Official';
  String _sellerAvatar = '🏪';

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is ProductModel) {
      _isEdit = true;
      _existing = arg;
      _nameCtrl = TextEditingController(text: arg.name);
      _descCtrl = TextEditingController(text: arg.description);
      _priceCtrl = TextEditingController(text: arg.price.toString());
      _discountPctCtrl = TextEditingController(
        text: arg.discountPercent > 0 ? arg.discountPercent.toString() : '',
      );
      _categoryCtrl = TextEditingController(text: arg.category);
      _stockCtrl = TextEditingController(text: arg.stock.toString());
      _flashDiscountCtrl = TextEditingController(
        text: arg.isFlashSale && arg.flashSalePrice > 0
            ? ((1 - arg.flashSalePrice / arg.price) * 100).toStringAsFixed(0)
            : '',
      );
      _soldCountCtrl = TextEditingController(text: arg.soldCount.toString());
      _ratingCtrl = TextEditingController(text: arg.rating.toString());
      _reviewCountCtrl = TextEditingController(
        text: arg.reviewCount.toString(),
      );
      _images = List<String>.from(arg.images);
      _detailImages = List<String>.from(arg.detailImages);
      _sizes = List<String>.from(arg.sizes);
      _colors = List<String>.from(arg.colors);
      _isFeatured = arg.isFeatured;
      _isFlashSale = arg.isFlashSale;
      _showSoldCount = arg.showSoldCount;
      _showRating = arg.showRating;
      _showReviewCount = arg.showReviewCount;
      _freeShipping = arg.freeShipping;
      _sellerId = arg.sellerId;
      _sellerName = arg.sellerName;
      _sellerAvatar = arg.sellerAvatar;
    } else {
      _nameCtrl = TextEditingController();
      _descCtrl = TextEditingController();
      _priceCtrl = TextEditingController();
      _discountPctCtrl = TextEditingController();
      _flashDiscountCtrl = TextEditingController();
      _categoryCtrl = TextEditingController(text: 'Clothing');
      _stockCtrl = TextEditingController(text: '50');
      _soldCountCtrl = TextEditingController(text: '0');
      _ratingCtrl = TextEditingController(text: '0.0');
      _reviewCountCtrl = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountPctCtrl.dispose();
    _flashDiscountCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _soldCountCtrl.dispose();
    _ratingCtrl.dispose();
    _reviewCountCtrl.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final urlCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                hintText: 'https://picsum.photos/400/400',
                labelText: 'Image URL',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Paste any direct image URL (picsum.photos works best).\nURLs like unsplash.com/images/... or imgur.com/...\nshould work too. Pinterest & Instagram are blocked.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                setState(() => _images.add(url));
              }
              Get.back();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Product name is required.');
      return;
    }
    if (_priceCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Price is required.');
      return;
    }
    if (_images.isEmpty) {
      AppSnack.error('Required', 'At least one product image is required.');
      return;
    }

    setState(() => _saving = true);

    try {
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
      final discountPct = double.tryParse(_discountPctCtrl.text.trim()) ?? 0.0;
      final flashDiscountPct =
          double.tryParse(_flashDiscountCtrl.text.trim()) ?? 0.0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 50;
      final soldCount = int.tryParse(_soldCountCtrl.text.trim()) ?? 0;
      final rating = double.tryParse(_ratingCtrl.text.trim()) ?? 0.0;
      final reviewCount = int.tryParse(_reviewCountCtrl.text.trim()) ?? 0;

      // Auto-calculate original price from discount percentage
      final originalPrice = discountPct > 0
          ? (price / (1 - discountPct / 100)).roundToDouble()
          : 0.0;

      // Auto-calculate flash sale price from flash discount percentage
      final flashPrice = _isFlashSale && flashDiscountPct > 0
          ? (price * (1 - flashDiscountPct / 100)).roundToDouble()
          : 0.0;

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': price,
        'originalPrice': originalPrice,
        'images': _images,
        'detailImages': _detailImages,
        'category': _categoryCtrl.text.trim().isEmpty
            ? 'Clothing'
            : _categoryCtrl.text.trim(),
        'rating': rating,
        'reviewCount': reviewCount,
        'sizes': _sizes,
        'colors': _colors,
        'stock': stock,
        'sellerId': _sellerId.isEmpty
            ? (_existing?.sellerId ?? 'admin')
            : _sellerId,
        'sellerName': _sellerName,
        'sellerAvatar': _sellerAvatar,
        'soldCount': soldCount,
        'isFeatured': _isFeatured,
        'isFlashSale': _isFlashSale,
        'flashSalePrice': _isFlashSale ? flashPrice : 0.0,
        'discountPercent': discountPct,
        'showSoldCount': _showSoldCount,
        'showRating': _showRating,
        'showReviewCount': _showReviewCount,
        'freeShipping': _freeShipping,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit && _existing != null) {
        await _firestore.collection('products').doc(_existing!.id).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('products').add(data);
      }

      if (mounted) {
        setState(() => _saving = false);
        Get.back(result: _isEdit ? 'updated' : 'added');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error('Error', 'Failed to save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            tooltip: 'Preview',
            onPressed: _showPreview,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Images section ─────────────────────────────
                  const Text(
                    'Product Images',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add up to 6 images. First image is the main display.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length + (_images.length < 6 ? 1 : 0),
                      itemBuilder: (_, i) {
                        // Add-image button
                        if (i == _images.length) {
                          return GestureDetector(
                            onTap: _addImageUrl,
                            child: Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.03,
                                ),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppTheme.primaryColor,
                                      size: 30,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add Image',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        // Image preview
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: _images[i],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (i == 0)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Main',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 6,
                              right: 16,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Detail Images (description-only, not in slideshow) ──
                  const Text(
                    'Detail Images',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Extra images shown in description. Not in the main slideshow.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _detailImages.length +
                          (_detailImages.length < 8 ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _detailImages.length) {
                          return GestureDetector(
                            onTap: _addDetailImageUrl,
                            child: Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.03,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: _detailImages[i],
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _detailImages.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Basic info — full width, no Rows to avoid overflow ──
                  _sectionLabel('Basic Info'),
                  const SizedBox(height: 10),
                  _field(
                    _nameCtrl,
                    'Product Name',
                    Icons.shopping_bag_outlined,
                    fillColor,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _descCtrl,
                    'Description',
                    Icons.description_outlined,
                    fillColor,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _priceCtrl,
                    'Price (\$)',
                    Icons.attach_money,
                    fillColor,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _discountPctCtrl,
                    'Discount (%) — auto-calculates original price',
                    Icons.percent,
                    fillColor,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 20 = 20% off',
                  ),
                  const SizedBox(height: 12),
                  _categoryDropdown(fillColor),
                  const SizedBox(height: 20),

                  // ── Stats & Shop (tap to expand) ─────────────
                  ExpansionTile(
                    title: const Text(
                      'Stats & Shop',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      _field(
                        _stockCtrl,
                        'Stock Quantity',
                        Icons.inventory_2_outlined,
                        fillColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        _soldCountCtrl,
                        'Sold Count',
                        Icons.trending_up,
                        fillColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        _ratingCtrl,
                        'Rating (0-5)',
                        Icons.star_half,
                        fillColor,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _field(
                        _reviewCountCtrl,
                        'Review Count',
                        Icons.rate_review_outlined,
                        fillColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore
                            .collection('shops')
                            .orderBy('name')
                            .get(),
                        builder: (ctx, snap) {
                          final shops = snap.data?.docs ?? [];
                          if (shops.isEmpty) return const SizedBox.shrink();
                          String curId = _sellerId.isNotEmpty
                              ? _sellerId
                              : (_existing?.sellerId ?? shops.first.id);
                          final idx = shops.indexWhere((s) => s.id == curId);
                          final curShop = idx >= 0 ? shops[idx] : shops.first;
                          return DropdownButtonFormField<String>(
                            value: curShop.id,
                            decoration: InputDecoration(
                              labelText: 'Shop / Seller',
                              prefixIcon: const Icon(
                                Icons.store_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: fillColor,
                              isDense: true,
                            ),
                            items: shops.map((s) {
                              final d = s.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: s.id,
                                child: Row(
                                  children: [
                                    Text(
                                      d['avatar'] ?? '🏪',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      d['name'] ?? 'Shop',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                final idx2 = shops.indexWhere((s) => s.id == v);
                                if (idx2 < 0) return;
                                final s = shops[idx2];
                                final d = s.data() as Map<String, dynamic>;
                                setState(() {
                                  _sellerId = v;
                                  _sellerName = d['name'] ?? 'Tiny Chicken';
                                  _sellerAvatar = d['avatar'] ?? '🏪';
                                });
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  // ── Sizes & Colors (tap to expand) ──────────
                  ExpansionTile(
                    title: const Text(
                      'Sizes & Colors',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    initiallyExpanded: _isEdit,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      _buildChipSection(
                        'Sizes',
                        _sizes,
                        'size',
                        Icons.straighten_outlined,
                        fillColor,
                        isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildChipSection(
                        'Colors',
                        _colors,
                        'color',
                        Icons.palette_outlined,
                        fillColor,
                        isDark,
                      ),
                    ],
                  ),

                  // ── Settings (tap to expand) ─────────────────
                  ExpansionTile(
                    title: const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    initiallyExpanded: _isFlashSale,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Featured Product',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Shown on home page featured section',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _isFeatured,
                        onChanged: (v) => setState(() => _isFeatured = v),
                        activeColor: AppTheme.primaryColor,
                        dense: true,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Flash Sale',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Shown in flash sale with countdown',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _isFlashSale,
                        onChanged: (v) => setState(() => _isFlashSale = v),
                        activeColor: AppTheme.flashSaleColor,
                        dense: true,
                      ),
                      if (_isFlashSale) ...[
                        const SizedBox(height: 8),
                        _field(
                          _flashDiscountCtrl,
                          'Flash Discount (%) — auto-calc flash price',
                          Icons.bolt,
                          fillColor,
                          keyboardType: TextInputType.number,
                          hint: 'e.g. 30 = 30% off',
                        ),
                      ],
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Free Shipping',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Customer pays no shipping for this product',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _freeShipping,
                        onChanged: (v) => setState(() => _freeShipping = v),
                        activeColor: AppTheme.primaryColor,
                        dense: true,
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Badge Visibility',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Show Sold Count',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _showSoldCount,
                        onChanged: (v) => setState(() => _showSoldCount = v),
                        activeColor: AppTheme.primaryColor,
                        dense: true,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Show Rating Stars',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _showRating,
                        onChanged: (v) => setState(() => _showRating = v),
                        activeColor: AppTheme.primaryColor,
                        dense: true,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Show Review Count',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _showReviewCount,
                        onChanged: (v) => setState(() => _showReviewCount = v),
                        activeColor: AppTheme.primaryColor,
                        dense: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Saving...'
                    : (_isEdit ? 'Update Product' : 'Add Product'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  Widget _buildChipSection(
    String label,
    List<String> items,
    String type,
    IconData icon,
    Color fillColor,
    bool isDark,
  ) {
    final chipTextColor = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: chipTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.start,
          children: [
            ...items.map(
              (val) => Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: InputChip(
                  label: Text(
                    val,
                    style: TextStyle(fontSize: 12, color: chipTextColor),
                  ),
                  onDeleted: () => setState(() => items.remove(val)),
                  deleteIcon: Icon(Icons.close, size: 16, color: chipTextColor),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: fillColor,
                  side: BorderSide(color: chipTextColor.withValues(alpha: 0.2)),
                ),
              ),
            ),
            ActionChip(
              avatar: Icon(icon, size: 16, color: chipTextColor),
              label: Text(
                'Add $label',
                style: TextStyle(fontSize: 12, color: chipTextColor),
              ),
              onPressed: () => _addChip(type),
              visualDensity: VisualDensity.compact,
              backgroundColor: fillColor,
              side: BorderSide(color: chipTextColor.withValues(alpha: 0.3)),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => setState(() => items.clear()),
            icon: const Icon(Icons.clear_all, size: 14),
            label: Text(
              'Clear all ${label.toLowerCase()}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color fillColor, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        isDense: true,
      ),
    );
  }

  void _addDetailImageUrl() {
    final urlCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Detail Image URL'),
        content: TextField(
          controller: urlCtrl,
          decoration: InputDecoration(
            hintText: 'https://...',
            labelText: 'Image URL',
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                setState(() => _detailImages.add(url));
              }
              Get.back();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addChip(String type) {
    final ctrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add ${type == 'size' ? 'Size' : 'Color'}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: type == 'size' ? 'e.g. XL' : 'e.g. Red',
            prefixIcon: Icon(
              type == 'size'
                  ? Icons.straighten_outlined
                  : Icons.palette_outlined,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  if (type == 'size') {
                    _sizes.add(val);
                  } else {
                    _colors.add(val);
                  }
                });
              }
              Get.back();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPreview() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final discountPct = double.tryParse(_discountPctCtrl.text.trim()) ?? 0.0;
    final flashDiscountPct =
        double.tryParse(_flashDiscountCtrl.text.trim()) ?? 0.0;
    final originalPrice = discountPct > 0
        ? (price / (1 - discountPct / 100)).roundToDouble()
        : 0.0;
    final flashPrice = _isFlashSale && flashDiscountPct > 0
        ? (price * (1 - flashDiscountPct / 100)).roundToDouble()
        : 0.0;
    final effectivePrice = _isFlashSale && flashPrice > 0 ? flashPrice : price;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Price breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Calculation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _previewRow('Base Price', '\$${price.toStringAsFixed(2)}'),
                    if (discountPct > 0)
                      _previewRow('Discount', '$discountPct%'),
                    if (discountPct > 0)
                      _previewRow(
                        'Original (calc)',
                        '\$${originalPrice.toStringAsFixed(2)}',
                      ),
                    if (_isFlashSale && flashDiscountPct > 0)
                      _previewRow('Flash Discount', '$flashDiscountPct%'),
                    if (_isFlashSale && flashPrice > 0)
                      _previewRow(
                        'Flash Price',
                        '\$${flashPrice.toStringAsFixed(2)}',
                      ),
                    const Divider(height: 16),
                    _previewRow(
                      'Customer Pays',
                      '\$${effectivePrice.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Mini product card preview
              if (_images.isNotEmpty) ...[
                const Text(
                  'Product Card',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 280,
                    child: _buildPreviewCard(
                      effectivePrice: effectivePrice,
                      originalPrice: originalPrice,
                      discountPct: discountPct > 0 ? discountPct : null,
                      isFlash: _isFlashSale,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Close Preview'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: bold ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard({
    required double effectivePrice,
    required double originalPrice,
    double? discountPct,
    bool isFlash = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: _images.isNotEmpty
                      ? Image.network(
                          _images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                ),
              ),
              if (discountPct != null && discountPct > 3)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isFlash
                          ? AppTheme.flashSaleColor
                          : AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '-${discountPct.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isFlash)
                Positioned(
                  top: (discountPct != null && discountPct > 3) ? 22 : 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'FLASH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameCtrl.text.trim().isEmpty
                        ? 'Product Name'
                        : _nameCtrl.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (originalPrice > 0)
                            Text(
                              '\$${originalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9E9EAA),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Colors.white,
                          size: 16,
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

  Widget _categoryDropdown(Color fillColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('categories').orderBy('order').snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        final names = docs
            .map((d) => (d.data() as Map<String, dynamic>)['name'] as String)
            .toList();
        if (names.isEmpty) {
          // Fallback if no categories in Firestore
          names.addAll([
            'Clothing',
            'Electronics',
            'Accessories',
            'Shoes',
            'Home & Living',
            'Beauty',
          ]);
        }
        final cur = _categoryCtrl.text.trim();
        final value = names.contains(cur) ? cur : names.first;
        return DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: 'Category',
            prefixIcon: const Icon(Icons.category_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            isDense: true,
          ),
          items: names
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) _categoryCtrl.text = v;
          },
        );
      },
    );
  }
}
