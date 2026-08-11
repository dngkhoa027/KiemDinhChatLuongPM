import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../models/cart_models.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../auth/login_screen.dart';

/// Màn hình "Đánh giá sản phẩm" — mở từ nút "Đánh giá" ở thẻ đơn hàng
/// (Đơn đã mua) hoặc trang chi tiết đơn hàng, chỉ áp dụng cho đơn ở
/// trạng thái [OrderStatus.completed]. Cho phép đánh giá TỪNG sản phẩm
/// trong đơn (đơn có thể nhiều sản phẩm/nhiều shop) trong cùng 1 màn
/// hình, giống luồng thật của Shopee, rồi gửi tất cả cùng lúc.
class ReviewScreen extends StatefulWidget {
  final Order order;

  const ReviewScreen({super.key, required this.order});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  late final List<_ItemReviewState> _itemStates;
  bool _loadingExisting = true;
  bool _submitting = false;

  User? get _firebaseUser => AuthService.instance.currentFirebaseUser;

  @override
  void initState() {
    super.initState();
    _itemStates = List.generate(
      widget.order.items.length,
      (i) => _ItemReviewState(controller: TextEditingController()),
    );
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) {
      setState(() => _loadingExisting = false);
      return;
    }
    try {
      final existing = await ReviewService.instance.fetchOrderReviews(
        buyerUid: uid,
        orderId: widget.order.id,
      );
      for (final entry in existing.entries) {
        if (entry.key < 0 || entry.key >= _itemStates.length) continue;
        final state = _itemStates[entry.key];
        state.rating = entry.value.rating;
        state.controller.text = entry.value.comment;
        state.alreadySubmitted = true;
      }
    } catch (_) {
      // Không tải được đánh giá cũ (VD: lần đầu chưa có) -> bỏ qua, coi
      // như đơn này chưa được đánh giá lần nào.
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    for (final s in _itemStates) {
      s.controller.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit => _itemStates.any((s) => s.rating > 0) && !_submitting;

  Future<void> _handleSubmit() async {
    final uid = _firebaseUser?.uid;
    if (uid == null || !_canSubmit) return;

    setState(() => _submitting = true);
    try {
      final items = widget.order.items;
      for (int i = 0; i < items.length; i++) {
        final state = _itemStates[i];
        if (state.rating <= 0) continue; // bỏ qua sản phẩm chưa chấm sao
        final item = items[i];
        await ReviewService.instance.submitReview(
          buyerUid: uid,
          orderId: widget.order.id,
          itemIndex: i,
          productName: item.name,
          productImage: item.image,
          productVariant: item.variant,
          shopName: item.shopName,
          rating: state.rating,
          comment: state.controller.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá sản phẩm!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi đánh giá thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          title: const Text('Đánh giá sản phẩm'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Bạn cần đăng nhập để đánh giá sản phẩm',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: shopeeOrange, foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShopeeLoginPage()),
                  ),
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text('Đánh giá sản phẩm', style: TextStyle(fontSize: 16)),
      ),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator(color: shopeeOrange))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: widget.order.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ProductReviewCard(
                item: widget.order.items[index],
                state: _itemStates[index],
                onChanged: () => setState(() {}),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: shopeeOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: _canSubmit ? _handleSubmit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Hoàn Thành', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}

/// State đánh giá cục bộ (chưa gửi) cho 1 sản phẩm trong đơn.
class _ItemReviewState {
  int rating;
  final TextEditingController controller;
  bool alreadySubmitted;

  _ItemReviewState({this.rating = 0, required this.controller, this.alreadySubmitted = false});
}

class _ProductReviewCard extends StatelessWidget {
  final CheckoutLineItem item;
  final _ItemReviewState state;
  final VoidCallback onChanged;

  const _ProductReviewCard({required this.item, required this.state, required this.onChanged});

  static const Color shopeeOrange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    if (item.variant.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Phân loại: ${item.variant}',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    final filled = starIndex <= state.rating;
                    return IconButton(
                      onPressed: () {
                        state.rating = starIndex;
                        onChanged();
                      },
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: shopeeOrange,
                        size: 32,
                      ),
                      splashRadius: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    );
                  }),
                ),
                if (state.rating > 0)
                  Text(
                    _ratingLabel(state.rating),
                    style: const TextStyle(fontSize: 12.5, color: shopeeOrange, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: state.controller,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Hãy chia sẻ nhận xét của bạn cho sản phẩm này nhé!',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 13.5),
          ),
          if (state.alreadySubmitted) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Bạn đã đánh giá sản phẩm này — gửi lại để sửa đánh giá',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Tệ';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Tuyệt vời';
      default:
        return '';
    }
  }
}
