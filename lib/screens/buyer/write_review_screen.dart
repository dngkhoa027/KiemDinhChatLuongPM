import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/review_model.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';

/// Màn hình "Đánh giá sản phẩm" — mở khi người mua bấm nút "Đánh giá" ở
/// 1 sản phẩm trong tab "Chưa đánh giá" của [MyReviewsScreen]. Giao diện
/// bám sát Shopee: sao đánh giá sản phẩm, ô thêm hình ảnh/video (placeholder,
/// vì app demo chưa nối kho ảnh thật), ô viết nhận xét, đánh giá ẩn danh,
/// rồi tới 3 mục sao phụ (Dịch vụ người bán / Tốc độ giao hàng / Tài xế)
/// kèm gợi ý tag nhanh cho shipper.
class WriteReviewScreen extends StatefulWidget {
  final ReviewableItem item;

  const WriteReviewScreen({super.key, required this.item});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color starYellow = Color(0xFFFFB800);

  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _shipperNoteCtrl = TextEditingController();
  final ReviewService _reviewService = ReviewService.instance;

  int _productRating = 5;
  int _sellerRating = 5;
  int _deliveryRating = 5;
  int _shipperRating = 5;
  bool _anonymous = false;
  bool _submitting = false;

  final List<String> _allShipperTags = const [
    'Chuyên nghiệp, chu đáo',
    'Cập nhật trạng thái giao hàng thường xuyên',
    'Bảo quản hàng hóa tốt',
    'Giao hàng đúng hẹn',
    'Đồng phục gọn gàng, chỉn chu',
    'Đáng tin cậy',
    'Hỗ trợ khách hàng nhiệt tình',
    'Thân thiện, linh hoạt',
  ];
  final Set<String> _selectedShipperTags = {};

  @override
  void dispose() {
    _contentCtrl.dispose();
    _shipperNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null || _submitting) return;

    if (_contentCtrl.text.trim().length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng viết nhận xét từ 50 ký tự trở lên.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _reviewService.submitReview(
        buyerUid: uid,
        orderId: widget.item.orderId,
        itemIndex: widget.item.itemIndex,
        shopName: widget.item.shopName,
        productName: widget.item.productName,
        productImage: widget.item.productImage,
        variant: widget.item.variant,
        productRating: _productRating,
        sellerServiceRating: _sellerRating,
        deliveryRating: _deliveryRating,
        shipperRating: _shipperRating,
        content: _contentCtrl.text.trim(),
        shipperTags: _selectedShipperTags.toList(),
        isAnonymous: _anonymous,
        rewardCoins: widget.item.rewardCoins,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đánh giá thành công! Bạn nhận được +${widget.item.rewardCoins} Xu 🎉')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi đánh giá thất bại, vui lòng thử lại.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.4,
        title: const Text('Đánh giá sản phẩm', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildCoinBanner(),
          _buildProductCard(),
          const SizedBox(height: 8),
          _buildServiceRatingsCard(),
          const SizedBox(height: 8),
          _buildShipperCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _submitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: shopeeOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Gửi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                children: [
                  const TextSpan(text: 'Xem Hướng dẫn đánh giá chuẩn để nhận đến '),
                  TextSpan(
                    text: '${widget.item.rewardCoins} xu',
                    style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' !'),
                ],
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: widget.item.productImage.isNotEmpty
                    ? Image.network(
                        widget.item.productImage,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                        ),
                      )
                    : Container(width: 56, height: 56, color: Colors.grey.shade200),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.item.variant, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text('Đánh giá sản phẩm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          _StarRow(rating: _productRating, size: 34, onChanged: (v) => setState(() => _productRating = v)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('Thêm ít nhất 1 hình ảnh/video về sản phẩm', style: TextStyle(fontSize: 13, color: Colors.black87)),
              ),
              Text('+200', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
              const SizedBox(width: 2),
              const Icon(Icons.monetization_on, size: 15, color: Color(0xFFFFB800)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đính kèm ảnh/video sẽ sớm được cập nhật.')),
              );
            },
            child: Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 28, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text('Hình ảnh/Video/Video theo mẫu', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Viết đánh giá từ 50 ký tự', style: TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _contentCtrl,
                  minLines: 5,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Hãy chia sẻ nhận xét cho sản phẩm này bạn nhé!',
                    hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey),
                  ),
                  style: const TextStyle(fontSize: 13.5),
                ),
                Text(
                  '${_contentCtrl.text.trim().length} ký tự',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _anonymous,
                  activeColor: shopeeOrange,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => setState(() => _anonymous = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Đánh giá ẩn danh', style: TextStyle(fontSize: 13.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRatingsCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          _labeledStarRow('Dịch vụ của người bán', _sellerRating, (v) => setState(() => _sellerRating = v)),
          const SizedBox(height: 14),
          _labeledStarRow('Tốc độ giao hàng', _deliveryRating, (v) => setState(() => _deliveryRating = v)),
          const SizedBox(height: 14),
          _labeledStarRow('Tài xế', _shipperRating, (v) => setState(() => _shipperRating = v)),
        ],
      ),
    );
  }

  Widget _labeledStarRow(String label, int rating, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        _StarRow(rating: rating, size: 22, onChanged: onChanged),
      ],
    );
  }

  Widget _buildShipperCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Color(0xFFEE4D2D), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.two_wheeler, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('SPX Express', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allShipperTags.map((tag) {
              final selected = _selectedShipperTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedShipperTags.remove(tag);
                    } else {
                      _selectedShipperTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? shopeeOrange.withValues(alpha: 0.1) : const Color(0xFFF7F7F7),
                    border: Border.all(color: selected ? shopeeOrange : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: selected ? shopeeOrange : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(6)),
            child: TextField(
              controller: _shipperNoteCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Thêm đánh giá chi tiết tại đây',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int> onChanged;

  const _StarRow({required this.rating, required this.onChanged, this.size = 28});

  static const Color starYellow = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: EdgeInsets.only(right: size * 0.14),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: filled ? starYellow : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }
}
