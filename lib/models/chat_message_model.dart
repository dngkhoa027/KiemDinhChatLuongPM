/// Dữ liệu 1 tin nhắn trong cuộc trò chuyện giữa người mua và 1 shop.
/// Lưu ở Firestore: `shop_chats/{conversationId}/messages/{messageId}`.
///
/// Hỗ trợ 2 loại:
/// - text: tin nhắn chữ thường
/// - product: card sản phẩm (khi người mua bấm Chat từ trang chi tiết SP)
class ChatMessage {
  final String id;
  final String text;
  // true  = tin nhắn do SHOP gửi (tự động trả lời)
  // false = tin nhắn do NGƯỜI MUA gửi
  final bool isFromShop;
  final DateTime sentAt;

  /// 'text' | 'product'
  final String type;

  // ---- Trường dành cho tin nhắn kiểu product ----
  final int? productId;
  final String? productName;
  final String? productImage;
  final int? productPrice; // VNĐ
  final String? productPriceText;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isFromShop,
    required this.sentAt,
    this.type = 'text',
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    this.productPriceText,
  });

  bool get isProduct => type == 'product';

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['sentAt'];
    DateTime sentAt;
    if (ts is DateTime) {
      sentAt = ts;
    } else if (ts != null && ts.runtimeType.toString() == 'Timestamp') {
      // Tránh phụ thuộc cloud_firestore trực tiếp trong model.
      sentAt = (ts as dynamic).toDate() as DateTime;
    } else {
      sentAt = DateTime.now();
    }
    return ChatMessage(
      id: id,
      text: (data['text'] as String?) ?? '',
      isFromShop: (data['isFromShop'] as bool?) ?? false,
      sentAt: sentAt,
      type: (data['type'] as String?) ?? 'text',
      productId: data['productId'] as int?,
      productName: data['productName'] as String?,
      productImage: data['productImage'] as String?,
      productPrice: data['productPrice'] as int?,
      productPriceText: data['productPriceText'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isFromShop': isFromShop,
      'sentAt': sentAt,
      'type': type,
      if (productId != null) 'productId': productId,
      if (productName != null) 'productName': productName,
      if (productImage != null) 'productImage': productImage,
      if (productPrice != null) 'productPrice': productPrice,
      if (productPriceText != null) 'productPriceText': productPriceText,
    };
  }
}

/// Thông tin tóm tắt 1 hội thoại giữa người mua và 1 shop, dùng để hiển thị
/// trong màn hình "Danh sách Chat" (giống tab Chat của Shopee) — mỗi shop
/// đã từng nhắn tin sẽ là 1 dòng, kèm tin nhắn gần nhất + thời gian.
/// Đọc từ document `shop_chats/{conversationId}`.
class ShopConversationSummary {
  final String id;
  final String shopName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool lastSenderIsShop;

  const ShopConversationSummary({
    required this.id,
    required this.shopName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderIsShop,
  });

  factory ShopConversationSummary.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['lastMessageAt'];
    DateTime lastMessageAt;
    if (ts is DateTime) {
      lastMessageAt = ts;
    } else if (ts != null && ts.runtimeType.toString() == 'Timestamp') {
      lastMessageAt = (ts as dynamic).toDate() as DateTime;
    } else {
      lastMessageAt = DateTime.now();
    }
    return ShopConversationSummary(
      id: id,
      shopName: (data['shopName'] as String?) ?? 'Shop',
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: lastMessageAt,
      lastSenderIsShop: (data['lastSenderIsShop'] as bool?) ?? false,
    );
  }
}
