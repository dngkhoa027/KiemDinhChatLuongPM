import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../auth/login_screen.dart';
import 'write_review_screen.dart';

/// Màn hình "Đánh giá của tôi" — bám sát layout Shopee thật:
/// - Header: tổng số đánh giá đã gửi + số Xu đã nhận được từ đánh giá.
/// - Tab "Chưa đánh giá": mọi sản phẩm thuộc đơn ĐÃ HOÀN THÀNH mà người
///   mua chưa gửi đánh giá, nhóm theo shop, kèm nút "Đánh giá +xu Thưởng".
/// - Tab "Đã đánh giá": danh sách đánh giá đã gửi (đọc từ Firestore qua
///   ReviewService).
///
/// "Chưa đánh giá" được tính bằng cách so [OrderService] (đơn hoàn thành,
/// in-memory) với [ReviewService] (đánh giá đã gửi, Firestore) — sản phẩm
/// nào có key orderId_itemIndex CHƯA xuất hiện trong danh sách review thì
/// vẫn còn ở tab "Chưa đánh giá".
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final ReviewService _reviewService = ReviewService.instance;
  int _tabIndex = 0; // 0 = Chưa đánh giá, 1 = Đã đánh giá

  User? get _firebaseUser => AuthService.instance.currentFirebaseUser;

  List<ReviewableItem> _buildReviewableItems() {
    final completed = OrderService.instance.byStatus(OrderStatus.completed);
    final items = <ReviewableItem>[];
    for (final order in completed) {
      final daysSinceCompleted = DateTime.now().difference(order.statusUpdatedAt).inDays;
      final daysLeft = (30 - daysSinceCompleted).clamp(0, 30);
      for (int i = 0; i < order.items.length; i++) {
        final line = order.items[i];
        items.add(ReviewableItem(
          orderId: order.id,
          itemIndex: i,
          shopName: line.shopName,
          productName: line.name,
          productImage: line.image,
          variant: line.variant,
          daysLeftToReview: daysLeft,
          rewardCoins: 600,
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firebaseUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text('Đánh giá của tôi', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: uid == null ? _buildLoggedOut(context) : _buildBody(uid),
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Đăng nhập để xem đánh giá của bạn', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: shopeeOrange, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopeeLoginPage())),
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String uid) {
    return StreamBuilder<List<Review>>(
      stream: _reviewService.watchMyReviews(buyerUid: uid),
      builder: (context, snapshot) {
        final myReviews = snapshot.data ?? const <Review>[];
        final reviewedKeys = myReviews.map((r) => r.reviewKey).toSet();
        final allItems = _buildReviewableItems();
        final unreviewed = allItems.where((i) => !reviewedKeys.contains(i.reviewKey)).toList();

        return AnimatedBuilder(
          animation: OrderService.instance,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeaderStats(myReviews),
                _buildTabs(unreviewed.length, myReviews.length),
                Expanded(
                  child: _tabIndex == 0
                      ? _buildUnreviewedList(unreviewed)
                      : _buildReviewedList(myReviews, snapshot.connectionState),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderStats(List<Review> myReviews) {
    final totalCoins = myReviews.fold<int>(0, (sum, r) => sum + r.rewardCoins);
    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: shopeeOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: shopeeOrange, size: 28),
          ),
          const SizedBox(width: 8),
          stat('${myReviews.length}', 'Đánh giá'),
          stat('$totalCoins', 'Xu đã nhận'),
          stat('0', 'Lượt thích'),
          stat('0', 'Lượt xem'),
        ],
      ),
    );
  }

  Widget _buildTabs(int unreviewedCount, int reviewedCount) {
    Widget tab(String label, int index) {
      final selected = _tabIndex == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tabIndex = index),
          child: Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: selected ? shopeeOrange : Colors.transparent, width: 2)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? shopeeOrange : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [tab('Chưa đánh giá', 0), tab('Đã đánh giá', 1)]),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildUnreviewedList(List<ReviewableItem> items) {
    if (items.isEmpty) {
      return _buildEmpty(icon: Icons.task_alt, text: 'Bạn đã đánh giá hết sản phẩm rồi, cảm ơn bạn!');
    }

    final byShop = <String, List<ReviewableItem>>{};
    for (final item in items) {
      byShop.putIfAbsent(item.shopName, () => []).add(item);
    }
    final maxReward = items.isEmpty ? 0 : items.map((e) => e.rewardCoins).reduce((a, b) => a > b ? a : b) * items.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    children: [
                      const TextSpan(text: 'Đánh giá tất cả sản phẩm và nhận đến '),
                      TextSpan(text: '$maxReward Xu', style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final entry in byShop.entries) _buildShopGroup(entry.key, entry.value),
        const SizedBox(height: 16),
        Center(
          child: Text('Không còn đánh giá nào', style: TextStyle(fontSize: 13, color: shopeeOrange, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildShopGroup(String shopName, List<ReviewableItem> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.storefront, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text(shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          for (final item in items) _buildReviewableTile(item),
        ],
      ),
    );
  }

  Widget _buildReviewableTile(ReviewableItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.productImage.isNotEmpty
                    ? Image.network(
                        item.productImage,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey.shade200),
                      )
                    : Container(width: 64, height: 64, color: Colors.grey.shade200),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(
                      item.daysLeftToReview > 0 ? 'Chỉ còn ${item.daysLeftToReview} ngày để đánh giá' : 'Sắp hết hạn đánh giá',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => _openWriteReview(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: shopeeOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Đánh giá', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.monetization_on, size: 15, color: Colors.white),
                    Text(' +${item.rewardCoins}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openWriteReview(item),
            child: Row(
              children: [
                const Text('Đánh giá', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(Icons.star_rounded, size: 22, color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openWriteReview(ReviewableItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WriteReviewScreen(item: item)),
    );
  }

  Widget _buildReviewedList(List<Review> reviews, ConnectionState state) {
    if (reviews.isEmpty) {
      if (state == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: shopeeOrange));
      }
      return _buildEmpty(icon: Icons.rate_review_outlined, text: 'Bạn chưa gửi đánh giá nào');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildReviewedCard(reviews[index]),
    );
  }

  Widget _buildReviewedCard(Review r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(child: Text(r.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
              Text(_formatDate(r.createdAt), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: r.productImage.isNotEmpty
                    ? Image.network(r.productImage, width: 52, height: 52, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: Colors.grey.shade200))
                    : Container(width: 52, height: 52, color: Colors.grey.shade200),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < r.productRating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 16,
                          color: const Color(0xFFFFB800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.content, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
          ],
          if (r.shipperTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: r.shipperTags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(4)),
                        child: Text(t, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  Widget _buildEmpty({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
