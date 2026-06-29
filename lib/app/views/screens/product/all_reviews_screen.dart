import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../models/review_model.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../services/time_service.dart';

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
  final _firestoreService = FirebaseFirestoreService();
  int? _starFilter;
  String _sortBy = 'newest';

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
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: _firestoreService.getReviewsStream(widget.productId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final allReviews = snapshot.data ?? [];

          if (allReviews.isEmpty) {
            return Center(
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
            );
          }

          // Compute stats from ALL reviews (including text-less)
          final dist = _computeDistribution(allReviews);
          final avg = allReviews.isEmpty
              ? 0.0
              : allReviews.map((r) => r.rating).reduce((a, b) => a + b) /
                    allReviews.length;

          // Filter & sort (only reviews WITH comments for display)
          var reviews = allReviews.where((r) => r.comment.isNotEmpty).toList();

          if (_starFilter != null) {
            reviews = reviews
                .where((r) => r.rating.round() == _starFilter)
                .toList();
          }
          switch (_sortBy) {
            case 'highest':
              reviews.sort((a, b) => b.rating.compareTo(a.rating));
              break;
            case 'lowest':
              reviews.sort((a, b) => a.rating.compareTo(b.rating));
              break;
            default:
              reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // ── Summary card ──
              _buildSummaryCard(avg, allReviews.length, dist, surface2, isDark),
              const SizedBox(height: 12),

              // ── Sort ──
              if (allReviews.length > 1) ...[
                _buildSortRow(isDark),
                const SizedBox(height: 8),
              ],

              // ── Filter chip ──
              if (_starFilter != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: Text(
                      '${_starFilter}★ only',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF5D4037),
                      ),
                    ),
                    deleteIcon: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF5D4037),
                    ),
                    onDeleted: () => setState(() => _starFilter = null),
                    backgroundColor: AppTheme.secondaryColor.withValues(
                      alpha: isDark ? 0.35 : 0.15,
                    ),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),

              // ── Stats note ──
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${reviews.length} written ${reviews.length == 1 ? 'review' : 'reviews'}'
                  '${allReviews.where((r) => r.comment.isEmpty).length > 0 ? ' · ${allReviews.where((r) => r.comment.isEmpty).length} rating-only' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF9E9EAA),
                  ),
                ),
              ),

              // ── Review cards ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: reviews.isEmpty
                    ? Container(
                        key: const ValueKey('empty'),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surface2,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'No written reviews match this filter',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9EAA),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        key: const ValueKey('list'),
                        children: reviews
                            .map((r) => _buildReviewCard(r, surface2))
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    double avg,
    int total,
    Map<int, int> dist,
    Color surface2,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < avg.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 12,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total ${total == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF9E9EAA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[star] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                final active = _starFilter == star;
                return GestureDetector(
                  onTap: () => setState(() {
                    _starFilter = _starFilter == star ? null : star;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$star★',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: active
                                  ? AppTheme.secondaryColor
                                  : (isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: active
                                  ? AppTheme.secondaryColor
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade300),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: active
                                      ? AppTheme.secondaryColor
                                      : AppTheme.secondaryColor.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow(bool isDark) {
    final options = {
      'newest': 'Newest',
      'highest': 'Highest',
      'lowest': 'Lowest',
    };
    return Row(
      children: [
        Text(
          'Sort:',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        ...options.entries.map((e) {
          final active = _sortBy == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _sortBy = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryColor.withValues(alpha: 0.4)
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Map<int, int> _computeDistribution(List<ReviewModel> reviews) {
    final map = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final star = r.rating.round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
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
          const SizedBox(height: 8),
          Text(r.comment, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = TimeService().serverNow().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
