import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/app_theme.dart';
import '../../../models/review_model.dart';

class AllReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;
  const AllReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _scrollCtrl = ScrollController();

  List<ReviewModel> _reviews = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() => _loading = true);
    try {
      final query = await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      _reviews = query.docs.map((d) => ReviewModel.fromFirestore(d)).toList();
      _lastDoc = query.docs.isNotEmpty ? query.docs.last : null;
      _hasMore = query.docs.length >= _pageSize;
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final query = await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

      final newReviews = query.docs
          .map((d) => ReviewModel.fromFirestore(d))
          .toList();
      _reviews.addAll(newReviews);
      _lastDoc = query.docs.isNotEmpty ? query.docs.last : _lastDoc;
      _hasMore = query.docs.length >= _pageSize;
      setState(() => _loadingMore = false);
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface2 = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F3F5);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Reviews', style: TextStyle(fontSize: 16)),
            Text(
              widget.productName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _reviews.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Be the first to review this product!',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: _reviews.length + (_hasMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _reviews.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }
                final r = _reviews[i];
                return _buildReviewCard(r, surface2);
              },
            ),
    );
  }

  Widget _buildReviewCard(ReviewModel r, Color surface2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    r.userAvatar.isNotEmpty && r.userAvatar.startsWith('http')
                    ? Image.network(
                        r.userAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            r.userName.isNotEmpty
                                ? r.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          r.userName.isNotEmpty
                              ? r.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(r.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9EAA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.comment, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
