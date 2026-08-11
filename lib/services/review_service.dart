import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

/// ============================================================
/// REVIEW SERVICE
/// ------------------------------------------------------------
/// Lưu đánh giá sản phẩm của người mua vào Firestore collection
/// `reviews` (đã có sẵn security rules cho phép buyer đọc tất cả, nhưng
/// chỉ tạo/sửa đúng đánh giá của chính mình — xem firestore.rules).
///
/// docId = "{orderId}_{itemIndex}" -> mỗi sản phẩm trong 1 đơn chỉ có
/// đúng 1 đánh giá, gửi lại (sửa) sẽ ghi đè lên đánh giá cũ thay vì tạo
/// bản ghi trùng.
/// ============================================================
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef => _db.collection('reviews');

  String docIdFor({required String orderId, required int itemIndex}) => '${orderId}_$itemIndex';

  /// Stream tất cả đánh giá CỦA 1 NGƯỜI MUA (dùng cho tab "Đã đánh giá"
  /// và để tính "Chưa đánh giá" = đơn hoàn thành - đã đánh giá).
  Stream<List<Review>> watchMyReviews({required String buyerUid}) {
    return _reviewsRef
        .where('buyerUid', isEqualTo: buyerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList());
  }

  Future<void> submitReview({
    required String buyerUid,
    required String orderId,
    required int itemIndex,
    required String shopName,
    required String productName,
    required String productImage,
    required String variant,
    required int productRating,
    required int sellerServiceRating,
    required int deliveryRating,
    required int shipperRating,
    required String content,
    required List<String> shipperTags,
    required bool isAnonymous,
    required int rewardCoins,
  }) async {
    final id = docIdFor(orderId: orderId, itemIndex: itemIndex);
    await _reviewsRef.doc(id).set({
      'orderId': orderId,
      'itemIndex': itemIndex,
      'buyerUid': buyerUid,
      'shopName': shopName,
      'productName': productName,
      'productImage': productImage,
      'variant': variant,
      'productRating': productRating,
      'sellerServiceRating': sellerServiceRating,
      'deliveryRating': deliveryRating,
      'shipperRating': shipperRating,
      'content': content,
      'shipperTags': shipperTags,
      'isAnonymous': isAnonymous,
      'rewardCoins': rewardCoins,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
