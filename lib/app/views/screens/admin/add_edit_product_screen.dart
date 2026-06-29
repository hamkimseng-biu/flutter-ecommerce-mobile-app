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

class _AddEditProductScreenState extends State<AddEditProductScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;

  late final TabController _tabController;

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
  List<String> _materials = [];
  Map<String, List<String>> _customVariants = {};
  bool _isFeatured = false;
  bool _isFlashSale = false;
  bool _showSoldCount = true;
  bool _showRating = true;
  bool _showReviewCount = true;
  bool _freeShipping = false;
  bool _saving = false;
  bool _isEdit = false;
  DateTime? _saleEndsAt;
  ProductModel? _existing;
  String _sellerId = '';
  String _sellerName = 'Tiny Chicken Official';
  String _sellerAvatar = '🏪';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        text: arg.isFlashSale && arg.flashSalePrice > 0 && arg.price > 0
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
      _materials = List<String>.from(arg.materials);
      _customVariants = Map<String, List<String>>.from(
        arg.customVariants.map((k, v) => MapEntry(k, List<String>.from(v))),
      );
      _isFeatured = arg.isFeatured;
      _isFlashSale = arg.isFlashSale;
      _saleEndsAt = arg.saleEndsAt;
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
    _tabController.dispose();
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
        content: Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Column(
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
                  'Paste any direct image URL (picsum.photos, Pinterest, Unsplash, Imgur all work).',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            );
          },
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
      final rating = (double.tryParse(_ratingCtrl.text.trim()) ?? 0.0).clamp(
        0.0,
        5.0,
      );
      final reviewCount = (int.tryParse(_reviewCountCtrl.text.trim()) ?? 0)
          .clamp(0, 999999);

      // price is the ORIGINAL price entered by admin.
      // originalPrice mirrors it so the UI can show a strikethrough.
      final originalPrice = price;

      // Auto-calculate flash sale price from flash discount percentage
      final flashPrice = _isFlashSale && flashDiscountPct > 0
          ? (price * (1 - flashDiscountPct / 100) * 100).roundToDouble() / 100
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
        'materials': _materials,
        'customVariants': _customVariants.map((k, v) => MapEntry(k, v)),
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
        'saleEndsAt': _isFlashSale && _saleEndsAt != null
            ? Timestamp.fromDate(_saleEndsAt!)
            : null,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface2 : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? Colors.white38
                    : Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Info', height: 30, iconMargin: EdgeInsets.zero),
                  Tab(text: 'Images', height: 30, iconMargin: EdgeInsets.zero),
                  Tab(text: 'Options', height: 30, iconMargin: EdgeInsets.zero),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ═══ TAB 0: Info ═══
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Basic Info'),
                const SizedBox(height: 16),
                _field(
                  _nameCtrl,
                  'Product Name',
                  Icons.shopping_bag_outlined,
                  fillColor,
                ),
                const SizedBox(height: 16),
                _field(
                  _descCtrl,
                  'Description',
                  Icons.description_outlined,
                  fillColor,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _field(
                  _priceCtrl,
                  'Price (\$)',
                  Icons.attach_money,
                  fillColor,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _field(
                  _discountPctCtrl,
                  'Discount (%)',
                  Icons.percent,
                  fillColor,
                  keyboardType: TextInputType.number,
                  hint: 'e.g. 20 = 20% off',
                ),
                const SizedBox(height: 16),
                _categoryDropdown(fillColor),
                const SizedBox(height: 24),
                _sectionLabel('Stats & Shop'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _stockCtrl,
                        'Stock',
                        Icons.inventory_2_outlined,
                        fillColor,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _soldCountCtrl,
                        'Sold',
                        Icons.trending_up,
                        fillColor,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _ratingCtrl,
                        'Rating (0-5)',
                        Icons.star_half,
                        fillColor,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _reviewCountCtrl,
                        'Reviews',
                        Icons.rate_review_outlined,
                        fillColor,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<QuerySnapshot>(
                  future: _firestore.collection('shops').orderBy('name').get(),
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
                        prefixIcon: const Icon(Icons.store_outlined, size: 20),
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
                            _sellerAvatar = d['logoUrl'] ?? d['avatar'] ?? '🏪';
                          });
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // ═══ TAB 1: Images ═══
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Images',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add up to 6 images. First image is the main display. Drag to reorder or move between sections.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                _ImageDragSection(
                  key: ValueKey('prod_${_images.length}_${_images.hashCode}'),
                  images: _images,
                  maxCount: 6,
                  imageSize: 100,
                  borderRadius: 14,
                  sectionLabel: 'product',
                  isDark: isDark,
                  onAdd: _addImageUrl,
                  onRemove: (i) => setState(() => _images.removeAt(i)),
                  onMove: (url, fromSection, toIndex) {
                    setState(() {
                      if (fromSection == 'product') {
                        final oldIdx = _images.indexOf(url);
                        if (oldIdx >= 0) {
                          _images.removeAt(oldIdx);
                          final insertAt = toIndex > oldIdx
                              ? toIndex - 1
                              : toIndex;
                          _images.insert(
                            insertAt.clamp(0, _images.length),
                            url,
                          );
                        }
                      } else {
                        _detailImages.remove(url);
                        _images.insert(toIndex.clamp(0, _images.length), url);
                      }
                    });
                  },
                  onAcceptFromOther: (url) {
                    setState(() {
                      _detailImages.remove(url);
                      _images.add(url);
                    });
                  },
                  childBuilder: (i, url) => _buildProductImageTile(i, url),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Detail Images',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Extra images shown in description. Not in the main slideshow.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                _ImageDragSection(
                  key: ValueKey(
                    'det_${_detailImages.length}_${_detailImages.hashCode}',
                  ),
                  images: _detailImages,
                  maxCount: 8,
                  imageSize: 100,
                  borderRadius: 12,
                  sectionLabel: 'detail',
                  isDark: isDark,
                  onAdd: _addDetailImageUrl,
                  onRemove: (i) => setState(() => _detailImages.removeAt(i)),
                  onMove: (url, fromSection, toIndex) {
                    setState(() {
                      if (fromSection == 'detail') {
                        final oldIdx = _detailImages.indexOf(url);
                        if (oldIdx >= 0) {
                          _detailImages.removeAt(oldIdx);
                          final insertAt = toIndex > oldIdx
                              ? toIndex - 1
                              : toIndex;
                          _detailImages.insert(
                            insertAt.clamp(0, _detailImages.length),
                            url,
                          );
                        }
                      } else {
                        _images.remove(url);
                        _detailImages.insert(
                          toIndex.clamp(0, _detailImages.length),
                          url,
                        );
                      }
                    });
                  },
                  onAcceptFromOther: (url) {
                    setState(() {
                      _images.remove(url);
                      _detailImages.add(url);
                    });
                  },
                  childBuilder: (i, url) => _buildDetailImageTile(i, url),
                ),
              ],
            ),
          ),
          // ═══ TAB 2: Options ═══
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Variants'),
                const SizedBox(height: 16),
                _buildChipSection(
                  'Sizes',
                  _sizes,
                  'size',
                  Icons.straighten_outlined,
                  fillColor,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildChipSection(
                  'Materials',
                  _materials,
                  'material',
                  Icons.texture_outlined,
                  fillColor,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildChipSection(
                  'Colors',
                  _colors,
                  'color',
                  Icons.palette_outlined,
                  fillColor,
                  isDark,
                ),
                ..._customVariants.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildChipSection(
                      entry.key,
                      entry.value,
                      entry.key,
                      Icons.tune_rounded,
                      fillColor,
                      isDark,
                      onDeleteSection: () =>
                          setState(() => _customVariants.remove(entry.key)),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _buildAddVariantType(fillColor, isDark),
                const SizedBox(height: 24),
                _sectionLabel('Settings'),
                const SizedBox(height: 16),
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
                    'Flash Discount (%)',
                    Icons.bolt,
                    fillColor,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 30 = 30% off',
                  ),
                  const SizedBox(height: 8),
                  // Sale end date picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _saleEndsAt ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            _saleEndsAt ??
                                DateTime.now().add(
                                  const Duration(hours: 23, minutes: 59),
                                ),
                          ),
                        );
                        if (time != null) {
                          setState(
                            () => _saleEndsAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        } else {
                          setState(() => _saleEndsAt = date);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 20,
                            color: AppTheme.flashSaleColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _saleEndsAt != null
                                  ? 'Ends: ${_saleEndsAt!.day}/${_saleEndsAt!.month}/${_saleEndsAt!.year} at ${_saleEndsAt!.hour.toString().padLeft(2, '0')}:${_saleEndsAt!.minute.toString().padLeft(2, '0')}'
                                  : 'Set sale end date & time (optional)',
                              style: TextStyle(
                                fontSize: 14,
                                color: _saleEndsAt != null
                                    ? null
                                    : (isDark ? Colors.white54 : Colors.grey),
                              ),
                            ),
                          ),
                          if (_saleEndsAt != null)
                            GestureDetector(
                              onTap: () => setState(() => _saleEndsAt = null),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: const Text(
                    'Badge Visibility',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildProductImageTile(int i, String url) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image, size: 28, color: Colors.grey),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            right: 6,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailImageTile(int i, String url) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url,
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
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _detailImages.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
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
    bool isDark, {
    VoidCallback? onDeleteSection,
  }) {
    final chipTextColor = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: chipTextColor,
              ),
            ),
            if (onDeleteSection != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: onDeleteSection,
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ],
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
        title: Text(
          'Add ${type == 'size'
              ? 'Size'
              : type == 'color'
              ? 'Color'
              : 'Material'}',
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: type == 'size'
                ? 'e.g. XL'
                : type == 'color'
                ? 'e.g. Red'
                : 'e.g. Cotton',
            prefixIcon: Icon(
              type == 'size'
                  ? Icons.straighten_outlined
                  : type == 'color'
                  ? Icons.palette_outlined
                  : Icons.texture_outlined,
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
                  } else if (type == 'color') {
                    _colors.add(val);
                  } else if (type == 'material') {
                    _materials.add(val);
                  } else {
                    _customVariants[type] ??= [];
                    _customVariants[type]!.add(val);
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

  Widget _buildAddVariantType(Color fillColor, bool isDark) {
    return ActionChip(
      avatar: const Icon(
        Icons.add_circle_outline,
        size: 16,
        color: AppTheme.primaryColor,
      ),
      label: const Text(
        'Add Custom Variant',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => _showAddVariantTypeDialog(),
      visualDensity: VisualDensity.compact,
      backgroundColor: fillColor,
      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
    );
  }

  void _showAddVariantTypeDialog() {
    final nameCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('New Variant Type'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Style, Weight, Fit',
            labelText: 'Variant Name',
            prefixIcon: const Icon(Icons.tune_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty && !_customVariants.containsKey(name)) {
                setState(() => _customVariants[name] = []);
              }
              Get.back();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Create'),
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

    double _calcDiscounted(double p, double pct) =>
        (p * (1 - pct / 100) * 100).roundToDouble() / 100;
    final effectivePrice = _isFlashSale && flashDiscountPct > 0
        ? _calcDiscounted(price, flashDiscountPct)
        : (discountPct > 0 && discountPct <= 100
              ? _calcDiscounted(price, discountPct)
              : price);
    final flashPrice = _isFlashSale && flashDiscountPct > 0
        ? _calcDiscounted(price, flashDiscountPct)
        : 0.0;
    final originalPrice = price;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreviewSheet(
        name: _nameCtrl.text.trim().isEmpty
            ? 'Product Name'
            : _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? 'Product description'
            : _descCtrl.text.trim(),
        images: _images,
        price: price,
        originalPrice: originalPrice,
        effectivePrice: effectivePrice,
        discountPct: discountPct > 0 ? discountPct : null,
        flashDiscountPct: _isFlashSale && flashDiscountPct > 0
            ? flashDiscountPct
            : null,
        flashPrice: _isFlashSale && flashPrice > 0 ? flashPrice : null,
        isFlashSale: _isFlashSale,
        freeShipping: _freeShipping,
        category: _categoryCtrl.text.trim().isEmpty
            ? 'Clothing'
            : _categoryCtrl.text.trim(),
        sizes: _sizes,
        colors: _colors,
        materials: _materials,
        customVariants: _customVariants,
        rating: double.tryParse(_ratingCtrl.text.trim()) ?? 0.0,
        reviewCount: int.tryParse(_reviewCountCtrl.text.trim()) ?? 0,
        soldCount: int.tryParse(_soldCountCtrl.text.trim()) ?? 0,
        sellerName: _sellerName,
        sellerAvatar: _sellerAvatar,
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

// ═══════════════════════════════════════════════════════════════
// DRAGGABLE IMAGE SECTION — supports reorder & cross-list drag
// ═══════════════════════════════════════════════════════════════

class _ImageDragSection extends StatefulWidget {
  final List<String> images;
  final int maxCount;
  final double imageSize;
  final double borderRadius;
  final String sectionLabel;
  final bool isDark;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(String url, String fromSection, int toIndex) onMove;
  final void Function(String url) onAcceptFromOther;
  final Widget Function(int index, String url) childBuilder;

  const _ImageDragSection({
    super.key,
    required this.images,
    required this.maxCount,
    required this.imageSize,
    required this.borderRadius,
    required this.sectionLabel,
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
    required this.onAcceptFromOther,
    required this.childBuilder,
  });

  @override
  State<_ImageDragSection> createState() => _ImageDragSectionState();
}

class _ImageDragSectionState extends State<_ImageDragSection> {
  int? _hoverIndex;
  bool _isDragOver = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Calculate insertion index from a local x coordinate.
  int _indexAt(double localX) {
    final w = widget;
    final slotWidth = w.imageSize + 10;
    final idx = (localX / slotWidth).round();
    return idx.clamp(0, w.images.length);
  }

  void _onDragStarted(int draggedIdx) {
    setState(() {
      _isDragOver = true;
      _hoverIndex = draggedIdx + 1;
    });
  }

  void _onDragEnded() {
    setState(() {
      _isDragOver = false;
      _hoverIndex = null;
    });
  }

  void _acceptDrop(String data) {
    final w = widget;
    final parts = data.split('|');
    if (parts.length != 2) return;
    final url = parts[0];
    final fromSection = parts[1];
    final toIdx = (_hoverIndex ?? w.images.length).clamp(0, w.images.length);
    _onDragEnded();
    if (fromSection == w.sectionLabel) {
      final oldIdx = w.images.indexOf(url);
      if (oldIdx >= 0 && oldIdx != toIdx) {
        final adjusted = (toIdx > oldIdx) ? toIdx - 1 : toIdx;
        w.onMove(url, fromSection, adjusted);
      }
    } else {
      if (w.images.length < w.maxCount) {
        w.onMove(url, fromSection, toIdx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        if (!_isDragOver) setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) {
        // Keep _hoverIndex — don't reset it on leave, only on drag end
        setState(() => _isDragOver = false);
      },
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX =
            box.globalToLocal(details.offset).dx + _scrollCtrl.offset;
        setState(() {
          _isDragOver = true;
          _hoverIndex = _indexAt(localX);
        });
      },
      onAcceptWithDetails: (details) => _acceptDrop(details.data),
      builder: (ctx, candidateData, rejectedData) {
        final showIndicator = _isDragOver && candidateData.isNotEmpty;
        return SizedBox(
          height: w.imageSize + 10,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(w.images.length, (i) {
                  final url = w.images[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: LongPressDraggable<String>(
                      delay: const Duration(milliseconds: 200),
                      data: '$url|${w.sectionLabel}',
                      onDragStarted: () => _onDragStarted(i),
                      onDragEnd: (_) => _onDragEnded(),
                      feedback: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(w.borderRadius),
                        child: SizedBox(
                          width: w.imageSize,
                          height: w.imageSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(w.borderRadius),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: w.childBuilder(i, url),
                      ),
                      child: Stack(
                        children: [
                          w.childBuilder(i, url),
                          // Drop indicator overlay
                          if (showIndicator && _hoverIndex == i)
                            Positioned(
                              left: -3,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                // Indicator at end
                if (showIndicator && _hoverIndex == w.images.length)
                  Container(
                    width: 6,
                    height: w.imageSize,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                // Add button
                if (w.images.length < w.maxCount)
                  GestureDetector(
                    onTap: w.onAdd,
                    child: Container(
                      width: w.imageSize,
                      height: w.imageSize,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(w.borderRadius),
                        color: AppTheme.primaryColor.withValues(alpha: 0.03),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppTheme.primaryColor,
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PREVIEW BOTTOM SHEET — Card · Detail Page · Numbers
// ═══════════════════════════════════════════════════════════════

class _PreviewSheet extends StatefulWidget {
  final String name, description, category, sellerName, sellerAvatar;
  final List<String> images, sizes, colors, materials;
  final Map<String, List<String>> customVariants;
  final double price, originalPrice, effectivePrice, rating;
  final double? discountPct, flashDiscountPct, flashPrice;
  final bool isFlashSale, freeShipping;
  final int reviewCount, soldCount;

  const _PreviewSheet({
    required this.name,
    required this.description,
    required this.images,
    this.sizes = const [],
    this.colors = const [],
    this.materials = const [],
    this.customVariants = const {},
    required this.price,
    required this.originalPrice,
    required this.effectivePrice,
    this.discountPct,
    this.flashDiscountPct,
    this.flashPrice,
    required this.isFlashSale,
    required this.freeShipping,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.sellerName,
    required this.sellerAvatar,
  });

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget;
    final hasDiscount = d.discountPct != null;
    final hasFlash = d.isFlashSale && d.flashPrice != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.preview,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(0, 'Card'),
                const SizedBox(width: 16),
                _dot(1, 'Detail'),
                const SizedBox(width: 16),
                _dot(2, 'Numbers'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _cardView(isDark),
                  _detailView(isDark),
                  _numbersView(isDark),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E2E)
                    : const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Customer Pays',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                        Text(
                          '\$${d.effectivePrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (hasDiscount || hasFlash)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${d.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (hasDiscount)
                            Text(
                              'Save \$${(d.price - d.effectivePrice).toStringAsFixed(2)} (${d.discountPct!.round()}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _dot(int i, String label) {
    final a = _page == i;
    return GestureDetector(
      onTap: () => _pageCtrl.animateToPage(
        i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: a
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: a ? 8 : 6,
              height: a ? 8 : 6,
              decoration: BoxDecoration(
                color: a ? AppTheme.primaryColor : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: a ? FontWeight.w600 : FontWeight.w400,
                color: a ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String t, Color c, {IconData? icon, double sz = 9}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(5),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: sz, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    t,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                t,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sz,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );

  Widget _cardView(bool isDark) {
    final d = widget;
    final hd = d.discountPct != null;
    final hf = d.isFlashSale && d.flashPrice != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'How it looks in the product grid',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 180,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: d.images.isNotEmpty
                                ? Image.network(
                                    d.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _ph(),
                                  )
                                : _ph(),
                          ),
                        ),
                        if (hf)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: _badge(
                              d.flashDiscountPct != null
                                  ? 'FLASH -${d.flashDiscountPct!.round()}%'
                                  : 'FLASH',
                              AppTheme.errorColor,
                              icon: Icons.bolt,
                            ),
                          ),
                        if (!hf && hd && d.discountPct! > 3)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: _badge(
                              '-${d.discountPct!.round()}%',
                              Colors.amber,
                            ),
                          ),
                        if (d.soldCount > 1000)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: _badge(
                              '${(d.soldCount / 1000).toStringAsFixed(1)}k sold',
                              Colors.black54,
                            ),
                          ),
                        if (d.freeShipping)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: _badge(
                              'Free Ship',
                              AppTheme.successColor,
                              sz: 8,
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.sellerName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                          if (d.rating > 0)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.secondaryColor,
                                  size: 13,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${d.rating} (${d.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${d.effectivePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  if (hd || hf)
                                    Text(
                                      '\$${d.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF9E9EAA),
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '← Swipe →  |  Tap dots',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailView(bool isDark) {
    final d = widget;
    final hd = d.discountPct != null;
    final hf = d.isFlashSale && d.flashPrice != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'How it looks on the product page',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: d.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: d.images.length.clamp(1, 6),
                      itemBuilder: (_, i) => Image.network(
                        d.images[i.clamp(0, d.images.length - 1)],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ph(),
                      ),
                    )
                  : _ph(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      d.sellerAvatar.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                d.sellerAvatar,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  '🏪',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                          : Text(
                              d.sellerAvatar,
                              style: const TextStyle(fontSize: 16),
                            ),
                      const SizedBox(width: 6),
                      Text(
                        d.sellerName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${d.rating}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${d.reviewCount} reviews) · ${d.soldCount} sold',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${d.effectivePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (hf) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '\$${d.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9E9EAA),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 12,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                d.flashDiscountPct != null
                                    ? 'FLASH -${d.flashDiscountPct!.round()}%'
                                    : 'FLASH',
                                style: const TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (!hf && hd) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '\$${d.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9E9EAA),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${d.discountPct!.round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB8860B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
                ),
                const SizedBox(height: 12),
                Text(
                  d.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.white70 : const Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 12),
                // Variants preview
                if (d.sizes.isNotEmpty ||
                    d.colors.isNotEmpty ||
                    d.materials.isNotEmpty ||
                    d.customVariants.isNotEmpty) ...[
                  _buildPreviewVariants(isDark),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.7,
                      ),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '← Swipe →  |  Tap dots',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _numbersView(bool isDark) {
    final d = widget;
    final hd = d.discountPct != null;
    final hf = d.isFlashSale && d.flashDiscountPct != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Price Calculation',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _num(
                  'Original Price',
                  '\$${d.price.toStringAsFixed(2)}',
                  isDark,
                ),
                if (hd) ...[
                  const SizedBox(height: 6),
                  _num('Discount', '${d.discountPct!.round()}%', isDark),
                  const SizedBox(height: 6),
                  _num(
                    'After Discount',
                    '\$${d.effectivePrice.toStringAsFixed(2)}',
                    isDark,
                    hl: true,
                  ),
                ],
                if (hf) ...[
                  const SizedBox(height: 6),
                  _num(
                    'Flash Discount',
                    '${d.flashDiscountPct!.round()}%',
                    isDark,
                  ),
                  const SizedBox(height: 6),
                  _num(
                    'Flash Price',
                    '\$${d.flashPrice!.toStringAsFixed(2)}',
                    isDark,
                    hl: true,
                    c: AppTheme.flashSaleColor,
                  ),
                ],
                const Divider(height: 24),
                _num(
                  'Customer Pays',
                  '\$${d.effectivePrice.toStringAsFixed(2)}',
                  isDark,
                  bold: true,
                  big: true,
                ),
                if (hd && !hf)
                  _num(
                    'You Save',
                    '\$${(d.price - d.effectivePrice).toStringAsFixed(2)} (${d.discountPct!.round()}%)',
                    isDark,
                    c: AppTheme.successColor,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _sr('Name', d.name, isDark),
                _sr('Category', d.category, isDark),
                _sr(
                  'Rating',
                  '${d.rating} ★ (${d.reviewCount} reviews)',
                  isDark,
                ),
                _sr('Sold', '${d.soldCount}', isDark),
                _sr('Seller', d.sellerName, isDark),
                _sr('Sale', d.isFlashSale ? '⚡ Flash' : 'No', isDark),
                _sr('Free Ship', d.freeShipping ? '✅ Yes' : '❌ No', isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '← Swipe →  |  Tap dots',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreviewVariants(bool isDark) {
    final d = widget;
    final bg = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F3F5);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (d.sizes.isNotEmpty)
          _variantChip(
            'Size',
            d.sizes.join(', '),
            Icons.straighten_outlined,
            bg,
            isDark,
          ),
        if (d.colors.isNotEmpty)
          _variantChip(
            'Color',
            d.colors.join(', '),
            Icons.palette_outlined,
            bg,
            isDark,
          ),
        if (d.materials.isNotEmpty)
          _variantChip(
            'Material',
            d.materials.join(', '),
            Icons.texture_outlined,
            bg,
            isDark,
          ),
        for (final entry in d.customVariants.entries)
          _variantChip(
            entry.key,
            entry.value.join(', '),
            Icons.tune_rounded,
            bg,
            isDark,
          ),
      ],
    );
  }

  Widget _variantChip(
    String label,
    String value,
    IconData icon,
    Color bg,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _num(
    String l,
    String v,
    bool d, {
    bool bold = false,
    bool big = false,
    bool hl = false,
    Color? c,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(fontSize: 13)),
      Text(
        v,
        style: TextStyle(
          fontSize: big ? 18 : 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color:
              c ??
              (hl
                  ? AppTheme.primaryColor
                  : d
                  ? Colors.white70
                  : Colors.black87),
        ),
      ),
    ],
  );
  Widget _sr(String l, String v, bool d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l,
          style: TextStyle(
            fontSize: 12,
            color: d ? Colors.white54 : Colors.grey,
          ),
        ),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: d ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _ph() => Container(
    color: Colors.grey.shade200,
    child: const Center(child: Icon(Icons.image, size: 36, color: Colors.grey)),
  );
}
