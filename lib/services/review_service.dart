import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

/// ============================================================
/// REVIEW SERVICE
/// ------------------------------------------------------------
/// Quản lý đánh giá sản phẩm sau khi đơn hàng đã "Giao hàng thành công"
/// (OrderStatus.completed). Mỗi sản phẩm trong 1 đơn chỉ có đúng 1 đánh
/// giá — doc id ghép từ buyerUid + orderId + itemIndex nên gửi lại sẽ
/// SỬA đánh giá cũ thay vì tạo trùng.
///
/// Lưu ở Firestore: reviews/{buyerUid}_{orderId}_{itemIndex}
/// ============================================================
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef => _db.collection('reviews');

  String _docId({required String buyerUid, required String orderId, required int itemIndex}) {
    return '${buyerUid}_${orderId}_$itemIndex';
  }

  /// Lấy toàn bộ đánh giá NGƯỜI DÙNG HIỆN TẠI đã gửi cho 1 đơn hàng,
  /// key theo [itemIndex] để màn hình đánh giá biết sản phẩm nào đã có
  /// đánh giá (và điền sẵn để sửa).
  Future<Map<int, ProductReview>> fetchOrderReviews({
    required String buyerUid,
    required String orderId,
  }) async {
    final snap = await _reviewsRef
        .where('buyerUid', isEqualTo: buyerUid)
        .where('orderId', isEqualTo: orderId)
        .get();
    final result = <int, ProductReview>{};
    for (final doc in snap.docs) {
      final review = ProductReview.fromMap(doc.id, doc.data());
      result[review.itemIndex] = review;
    }
    return result;
  }

  /// Gửi (hoặc sửa) đánh giá cho 1 sản phẩm trong đơn hàng.
  Future<void> submitReview({
    required String buyerUid,
    required String orderId,
    required int itemIndex,
    required String productName,
    required String productImage,
    required String productVariant,
    required String shopName,
    required int rating,
    required String comment,
  }) {
    final docId = _docId(buyerUid: buyerUid, orderId: orderId, itemIndex: itemIndex);
    return _reviewsRef.doc(docId).set({
      'orderId': orderId,
      'itemIndex': itemIndex,
      'buyerUid': buyerUid,
      'productName': productName,
      'productImage': productImage,
      'productVariant': productVariant,
      'shopName': shopName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// True nếu người dùng đã đánh giá ÍT NHẤT 1 sản phẩm trong đơn hàng
  /// này — dùng để đổi nhãn nút "Đánh giá" -> "Xem đánh giá" trên thẻ
  /// đơn hàng.
  Future<bool> hasAnyReview({required String buyerUid, required String orderId}) async {
    final snap = await _reviewsRef
        .where('buyerUid', isEqualTo: buyerUid)
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
