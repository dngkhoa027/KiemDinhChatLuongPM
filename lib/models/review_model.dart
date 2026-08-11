/// Đánh giá của người mua cho 1 sản phẩm nằm trong 1 đơn hàng cụ thể.
/// Lưu ở Firestore collection `reviews`, mỗi sản phẩm trong đơn chỉ có
/// đúng 1 đánh giá (doc id ghép từ buyerUid + orderId + itemIndex), gửi
/// lại sẽ ghi đè (sửa đánh giá) chứ không tạo thêm bản ghi mới.
class ProductReview {
  final String id;
  final String orderId;
  final int itemIndex;
  final String buyerUid;
  final String productName;
  final String productImage;
  final String productVariant;
  final String shopName;
  final int rating; // 1-5 sao
  final String comment;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.orderId,
    required this.itemIndex,
    required this.buyerUid,
    required this.productName,
    required this.productImage,
    required this.productVariant,
    required this.shopName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ProductReview.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    DateTime createdAt;
    if (ts is DateTime) {
      createdAt = ts;
    } else if (ts != null && ts.runtimeType.toString() == 'Timestamp') {
      createdAt = (ts as dynamic).toDate() as DateTime;
    } else {
      createdAt = DateTime.now();
    }
    return ProductReview(
      id: id,
      orderId: (data['orderId'] as String?) ?? '',
      itemIndex: (data['itemIndex'] as num?)?.toInt() ?? 0,
      buyerUid: (data['buyerUid'] as String?) ?? '',
      productName: (data['productName'] as String?) ?? '',
      productImage: (data['productImage'] as String?) ?? '',
      productVariant: (data['productVariant'] as String?) ?? '',
      shopName: (data['shopName'] as String?) ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: (data['comment'] as String?) ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'itemIndex': itemIndex,
      'buyerUid': buyerUid,
      'productName': productName,
      'productImage': productImage,
      'productVariant': productVariant,
      'shopName': shopName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
