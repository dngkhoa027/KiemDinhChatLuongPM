/// Model dữ liệu cho tính năng "Đánh giá của tôi".
///
/// [ReviewableItem] = 1 sản phẩm (trong 1 đơn đã hoàn thành) MÀ NGƯỜI MUA
/// CHƯA ĐÁNH GIÁ — dựng trực tiếp từ [Order] (OrderService, in-memory),
/// không lưu riêng ở đâu cả. Khi người mua gửi đánh giá cho đúng
/// [orderId] + [itemIndex] này, nó sẽ tự biến mất khỏi tab "Chưa đánh giá"
/// (vì lúc đó đã có [Review] tương ứng trong Firestore).
///
/// [Review] = 1 đánh giá đã gửi, lưu ở Firestore collection `reviews`
/// (đã có sẵn rule cho phép buyer đọc/tạo/sửa đánh giá của chính mình).
library review_model;

class ReviewableItem {
  final String orderId;
  final int itemIndex;
  final String shopName;
  final String productName;
  final String productImage;
  final String variant;
  final int daysLeftToReview;
  final int rewardCoins;

  const ReviewableItem({
    required this.orderId,
    required this.itemIndex,
    required this.shopName,
    required this.productName,
    required this.productImage,
    required this.variant,
    required this.daysLeftToReview,
    this.rewardCoins = 600,
  });

  /// Khoá định danh duy nhất 1 sản phẩm trong 1 đơn — dùng làm docId cho
  /// review tương ứng, để tra cứu "đã đánh giá chưa" cực nhanh (O(1) qua
  /// Set) thay vì phải so khớp orderId+itemIndex qua vòng lặp.
  String get reviewKey => '${orderId}_$itemIndex';
}

class Review {
  final String id;
  final String orderId;
  final int itemIndex;
  final String buyerUid;
  final String shopName;
  final String productName;
  final String productImage;
  final String variant;

  final int productRating; // 1-5: đánh giá sản phẩm
  final int sellerServiceRating; // 1-5: dịch vụ người bán
  final int deliveryRating; // 1-5: tốc độ giao hàng
  final int shipperRating; // 1-5: tài xế/shipper

  final String content;
  final List<String> shipperTags;
  final bool isAnonymous;
  final int rewardCoins;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.itemIndex,
    required this.buyerUid,
    required this.shopName,
    required this.productName,
    required this.productImage,
    required this.variant,
    required this.productRating,
    required this.sellerServiceRating,
    required this.deliveryRating,
    required this.shipperRating,
    required this.content,
    required this.shipperTags,
    required this.isAnonymous,
    required this.rewardCoins,
    required this.createdAt,
  });

  String get reviewKey => '${orderId}_$itemIndex';

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    DateTime createdAt;
    if (ts is DateTime) {
      createdAt = ts;
    } else if (ts != null && ts.runtimeType.toString() == 'Timestamp') {
      createdAt = (ts as dynamic).toDate() as DateTime;
    } else {
      createdAt = DateTime.now();
    }
    return Review(
      id: id,
      orderId: (data['orderId'] as String?) ?? '',
      itemIndex: (data['itemIndex'] as int?) ?? 0,
      buyerUid: (data['buyerUid'] as String?) ?? '',
      shopName: (data['shopName'] as String?) ?? 'Shop',
      productName: (data['productName'] as String?) ?? '',
      productImage: (data['productImage'] as String?) ?? '',
      variant: (data['variant'] as String?) ?? '',
      productRating: (data['productRating'] as int?) ?? 5,
      sellerServiceRating: (data['sellerServiceRating'] as int?) ?? 5,
      deliveryRating: (data['deliveryRating'] as int?) ?? 5,
      shipperRating: (data['shipperRating'] as int?) ?? 5,
      content: (data['content'] as String?) ?? '',
      shipperTags: ((data['shipperTags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      rewardCoins: (data['rewardCoins'] as int?) ?? 0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'createdAt': createdAt,
    };
  }
}
