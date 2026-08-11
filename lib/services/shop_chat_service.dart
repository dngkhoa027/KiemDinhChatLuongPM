import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

/// ============================================================
/// SHOP CHAT SERVICE
/// ------------------------------------------------------------
/// Xử lý nhắn tin giữa NGƯỜI MUA và 1 SHOP (tên shop lấy từ dữ liệu sản
/// phẩm trả về bởi ProductApiService — `Product.shopName`). Vì các shop
/// trong app là shop "ảo" dựng theo brand của API, chưa có tài khoản
/// seller thật đứng sau để trả lời trực tiếp, nên khi người mua gửi tin,
/// SHOP sẽ tự động trả lời sau vài giây (giống chatbot CSKH) dựa trên từ
/// khoá trong tin nhắn — không cần seller online.
///
/// Dữ liệu lưu ở Firestore:
///   shop_chats/{conversationId}                  -> thông tin hội thoại
///   shop_chats/{conversationId}/messages/{msgId}  -> từng tin nhắn
///
/// [conversationId] = "{buyerUid}_{shopSlug}" để 1 người mua chỉ có
/// đúng 1 luồng chat với 1 shop, dù bấm "Chat" từ bất kỳ sản phẩm nào
/// của shop đó.
/// ============================================================
class ShopChatService {
  ShopChatService._();
  static final ShopChatService instance = ShopChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _db.collection('shop_chats');

  /// Chuẩn hoá tên shop thành 1 slug ổn định để làm khoá hội thoại
  /// (VD "Nike Official" -> "nike-official").
  String _slugOf(String shopName) {
    final lower = shopName.trim().toLowerCase();
    final slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'shop' : slug;
  }

  String conversationIdFor({required String buyerUid, required String shopName}) {
    return '${buyerUid}_${_slugOf(shopName)}';
  }

  /// Stream toàn bộ tin nhắn của 1 hội thoại, sắp theo thời gian gửi.
  Stream<List<ChatMessage>> watchMessages({
    required String buyerUid,
    required String shopName,
  }) {
    final convId = conversationIdFor(buyerUid: buyerUid, shopName: shopName);
    return _conversationsRef
        .doc(convId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  /// Gửi tin nhắn của NGƯỜI MUA, đảm bảo hội thoại tồn tại, rồi tự động
  /// lên lịch cho shop "trả lời" sau một khoảng trễ ngắn để giống thật.
  Future<void> sendMessage({
    required String buyerUid,
    required String buyerName,
    required String shopName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final convId = conversationIdFor(buyerUid: buyerUid, shopName: shopName);
    final convRef = _conversationsRef.doc(convId);
    final messagesRef = convRef.collection('messages');

    // Tạo/cập nhật thông tin hội thoại (để sau này có thể liệt kê danh
    // sách các shop đã từng nhắn tin ở 1 màn hình "Hộp thoại" riêng).
    await convRef.set({
      'buyerUid': buyerUid,
      'buyerName': buyerName,
      'shopName': shopName,
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderIsShop': false,
    }, SetOptions(merge: true));

    await messagesRef.add({
      'text': trimmed,
      'type': 'text',
      'isFromShop': false,
      'sentAt': FieldValue.serverTimestamp(),
    });

    _scheduleAutoReply(convRef: convRef, messagesRef: messagesRef, shopName: shopName, buyerMessage: trimmed);
  }

  /// Gửi card sản phẩm vào chat (khi người mua bấm "Chat ngay" từ trang
  /// chi tiết sản phẩm). Card hiển thị hình + tên + giá giống Shopee.
  Future<void> sendProductMessage({
    required String buyerUid,
    required String buyerName,
    required String shopName,
    required int productId,
    required String productName,
    required String productImage,
    required int productPrice,
    required String productPriceText,
  }) async {
    final convId = conversationIdFor(buyerUid: buyerUid, shopName: shopName);
    final convRef = _conversationsRef.doc(convId);
    final messagesRef = convRef.collection('messages');

    final preview = productName.length > 40 ? '${productName.substring(0, 40)}…' : productName;

    await convRef.set({
      'buyerUid': buyerUid,
      'buyerName': buyerName,
      'shopName': shopName,
      'lastMessage': '[Sản phẩm] $preview',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderIsShop': false,
    }, SetOptions(merge: true));

    await messagesRef.add({
      'text': productName,
      'type': 'product',
      'isFromShop': false,
      'sentAt': FieldValue.serverTimestamp(),
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'productPriceText': productPriceText,
    });

    // Shop tự động phản hồi khi nhận được card sản phẩm
    _scheduleAutoReply(
      convRef: convRef,
      messagesRef: messagesRef,
      shopName: shopName,
      buyerMessage: 'sản phẩm $productName',
    );
  }

  /// Gửi sẵn lời chào đầu tiên từ shop nếu đây là lần đầu người mua mở
  /// khung chat với shop này (hội thoại chưa có tin nhắn nào).
  Future<void> ensureGreeting({
    required String buyerUid,
    required String shopName,
  }) async {
    final convId = conversationIdFor(buyerUid: buyerUid, shopName: shopName);
    final convRef = _conversationsRef.doc(convId);
    final messagesRef = convRef.collection('messages');
    final existing = await messagesRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    await convRef.set({
      'buyerUid': buyerUid,
      'shopName': shopName,
      'lastMessage': 'Shop đã sẵn sàng hỗ trợ bạn!',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderIsShop': true,
    }, SetOptions(merge: true));

    await messagesRef.add({
      'text':
          'Chào bạn, Shop $shopName xin chào! 👋 Shop luôn online hỗ trợ bạn 24/7. '
          'Bạn cần tư vấn gì về sản phẩm cứ nhắn ạ.',
      'type': 'text',
      'isFromShop': true,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  void _scheduleAutoReply({
    required DocumentReference<Map<String, dynamic>> convRef,
    required CollectionReference<Map<String, dynamic>> messagesRef,
    required String shopName,
    required String buyerMessage,
  }) {
    // Độ trễ 1.2-2.5s giống thời gian shop gõ phím trả lời thật.
    final delayMs = 1200 + Random().nextInt(1300);
    Future.delayed(Duration(milliseconds: delayMs), () async {
      final reply = _buildAutoReply(shopName: shopName, buyerMessage: buyerMessage);
      try {
        await messagesRef.add({
          'text': reply,
          'type': 'text',
          'isFromShop': true,
          'sentAt': FieldValue.serverTimestamp(),
        });
        await convRef.set({
          'lastMessage': reply,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderIsShop': true,
        }, SetOptions(merge: true));
      } catch (_) {
        // Bỏ qua nếu người dùng đã thoát app / mất mạng khi tới lượt trả lời.
      }
    });
  }

  /// Sinh câu trả lời tự động dựa theo từ khoá trong tin nhắn của người
  /// mua — mô phỏng một trợ lý CSKH cơ bản, không cần seller thật online.
  String _buildAutoReply({required String shopName, required String buyerMessage}) {
    final msg = buyerMessage.toLowerCase();

    bool has(List<String> keywords) => keywords.any(msg.contains);

    if (has(['giá', 'bao nhiêu tiền', 'giảm giá', 'sale'])) {
      return 'Dạ giá sản phẩm shop để hiển thị đúng như trên trang là đã áp giá tốt nhất rồi ạ. '
          'Bạn theo dõi Shop $shopName để nhận thêm voucher giảm giá cho lần mua sau nhé! 🎉';
    }
    if (has(['ship', 'giao hàng', 'vận chuyển', 'bao lâu'])) {
      return 'Đơn hàng thường được Shop $shopName đóng gói và bàn giao cho đơn vị vận chuyển '
          'trong 24h, thời gian giao dự kiến 2-4 ngày tuỳ khu vực bạn nhé.';
    }
    if (has(['còn hàng', 'còn không', 'hết hàng', 'size', 'màu'])) {
      return 'Sản phẩm hiện vẫn còn hàng ạ. Nếu cần loại size/màu cụ thể bạn nhắn rõ giúp shop, '
          'shop kiểm tra kho rồi phản hồi ngay nhé!';
    }
    if (has(['bảo hành', 'đổi trả', 'lỗi', 'hỏng'])) {
      return 'Shop $shopName hỗ trợ đổi trả trong 7 ngày nếu sản phẩm lỗi do nhà sản xuất, '
          'bạn cứ yên tâm đặt hàng nha. Có vấn đề gì cứ nhắn shop hỗ trợ liền.';
    }
    if (has(['cảm ơn', 'thanks', 'ok', 'oke'])) {
      return 'Dạ không có gì ạ, cảm ơn bạn đã ủng hộ Shop $shopName! Chúc bạn một ngày tốt lành 🥰';
    }
    if (has(['chào', 'hi', 'hello', 'alo'])) {
      return 'Chào bạn! Shop $shopName đang online, bạn cần hỗ trợ gì cứ nhắn ạ 😊';
    }

    final generic = [
      'Dạ shop đã nhận được tin nhắn của bạn, shop sẽ kiểm tra và phản hồi ngay ạ!',
      'Cảm ơn bạn đã nhắn tin cho Shop $shopName, bạn đợi shop chút xíu nhé.',
      'Dạ vâng ạ, bạn cho shop xin thêm thông tin (mã đơn/sản phẩm) để hỗ trợ nhanh hơn nha.',
    ];
    return generic[Random().nextInt(generic.length)];
  }
}
