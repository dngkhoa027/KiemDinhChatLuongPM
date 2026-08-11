import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_message_model.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../../services/shop_chat_service.dart';
import '../../widgets/shop_avatar.dart';
import '../auth/login_screen.dart';
import 'product_detail_screen.dart';

/// Màn hình chat 1-1 giữa người mua đang đăng nhập và 1 SHOP.
/// Giao diện bám sát Shopee Chat (app bar shop, banner cảnh báo, bubble
/// sản phẩm, thanh nhập tin với icon + / túi / emoji).
///
/// Khi mở từ trang chi tiết sản phẩm, truyền [initialProduct] để tự gửi
/// card sản phẩm vào hội thoại (giống Shopee khi "Chat ngay" từ SP).
class ShopChatScreen extends StatefulWidget {
  final String shopName;
  final Product? initialProduct;

  const ShopChatScreen({
    super.key,
    required this.shopName,
    this.initialProduct,
  });

  @override
  State<ShopChatScreen> createState() => _ShopChatScreenState();
}

class _ShopChatScreenState extends State<ShopChatScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ShopChatService _chatService = ShopChatService.instance;

  User? get _firebaseUser => AuthService.instance.currentFirebaseUser;
  bool _sending = false;
  bool _productSent = false;
  bool _showWarning = true;

  @override
  void initState() {
    super.initState();
    final uid = _firebaseUser?.uid;
    if (uid != null) {
      _chatService.ensureGreeting(buyerUid: uid, shopName: widget.shopName);
      // Gửi card sản phẩm nếu mở chat từ trang chi tiết SP
      if (widget.initialProduct != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialProduct());
      }
    }
  }

  Future<void> _sendInitialProduct() async {
    if (_productSent || widget.initialProduct == null) return;
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    _productSent = true;
    final p = widget.initialProduct!;
    try {
      final appUser = await AuthService.instance.fetchCurrentUser();
      await _chatService.sendProductMessage(
        buyerUid: uid,
        buyerName: appUser?.name ?? 'Khách',
        shopName: widget.shopName,
        productId: p.id,
        productName: p.name,
        productImage: p.thumbnail,
        productPrice: p.price,
        productPriceText: p.priceText,
      );
      _scrollToBottom();
    } catch (_) {
      _productSent = false;
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _inputCtrl.text.trim();
    final uid = _firebaseUser?.uid;
    if (text.isEmpty || uid == null || _sending) return;

    setState(() => _sending = true);
    _inputCtrl.clear();
    try {
      final appUser = await AuthService.instance.fetchCurrentUser();
      await _chatService.sendMessage(
        buyerUid: uid,
        buyerName: appUser?.name ?? 'Khách',
        shopName: widget.shopName,
        text: text,
      );
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không gửi được tin nhắn, vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firebaseUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          title: Text('Chat với ${widget.shopName}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Bạn cần đăng nhập để nhắn tin với shop',
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
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_showWarning) _buildWarningBanner(),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.watchMessages(buyerUid: uid, shopName: widget.shopName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: shopeeOrange));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Không tải được cuộc trò chuyện.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ),
                  );
                }
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Hãy gửi lời chào tới Shop ${widget.shopName} nhé 👋',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (msg.isProduct) {
                      return _ProductBubble(message: msg, shopName: widget.shopName);
                    }
                    return _ChatBubble(message: msg, shopName: widget.shopName);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.4,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          ShopAvatar(shopName: widget.shopName, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE4D2D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'Shopee Mall',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Color(0xFF26A69A), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Trực tuyến', style: TextStyle(fontSize: 11.5, color: Color(0xFF26A69A))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.storefront_outlined, color: Colors.grey.shade700, size: 22),
          onPressed: () {},
          tooltip: 'Xem shop',
        ),
        IconButton(
          icon: Icon(Icons.more_horiz, color: Colors.grey.shade700, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE082).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFFF9A825)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"LƯU Ý: Shopee KHÔNG cho phép hành vi: Đặt cọc/Chuyển khoản riêng/Giao dịch ngoài nền tảng/Tuyển CTV/Tặng quà miễn phí/Cung cấp thông tin liên hệ hoặc Hủy đơn theo yêu cầu người Bán, ...\n\n'
                  'Vui lòng chỉ Mua-Bán trực tiếp trên Shopee để tránh bị lừa đảo. Shopee sẽ thu thập và sử dụng lịch sử chat theo Chính sách bảo mật của Shopee."',
                  style: TextStyle(fontSize: 11.5, height: 1.35, color: Colors.grey.shade800),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showWarning = false),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Tìm hiểu thêm', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              const SizedBox(width: 12),
              const Text('Tố cáo người dùng này!', style: TextStyle(fontSize: 11.5, color: Colors.black87)),
              const SizedBox(width: 4),
              const Text('Tìm hiểu thêm', style: TextStyle(fontSize: 11.5, color: Color(0xFF1976D2), fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade600, size: 26),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade600, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Gửi tin nhắn ...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            if (_sending)
              const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2, color: shopeeOrange),
                ),
              )
            else
              IconButton(
                onPressed: _handleSend,
                icon: const Icon(Icons.send_rounded, color: shopeeOrange, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubble tin nhắn chữ thường
// ---------------------------------------------------------------------------
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String shopName;

  const _ChatBubble({required this.message, required this.shopName});

  static const Color shopeeOrange = Color(0xFFEE4D2D);

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isShop = message.isFromShop;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isShop ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isShop) ...[
            ShopAvatar(shopName: shopName, radius: 13),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isShop ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: isShop ? Colors.white : shopeeOrange,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isShop ? 4 : 14),
                      bottomRight: Radius.circular(isShop ? 14 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: isShop ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeLabel(message.sentAt),
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubble card sản phẩm (kiểu Shopee)
// ---------------------------------------------------------------------------
class _ProductBubble extends StatelessWidget {
  final ChatMessage message;
  final String shopName;

  const _ProductBubble({required this.message, required this.shopName});

  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isShop = message.isFromShop;
    final name = message.productName ?? message.text;
    final image = message.productImage ?? '';
    final priceText = message.productPriceText ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isShop ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isShop) ...[
            ShopAvatar(shopName: shopName, radius: 13),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isShop ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header nhỏ
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Text(
                          isShop ? 'Shop gửi sản phẩm' : 'Bạn đang quan tâm sản phẩm này',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ),
                      // Nội dung SP
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image.isNotEmpty
                                  ? Image.network(
                                      image,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 22),
                                      ),
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 22),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    priceText.isNotEmpty ? priceText : '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: shopeeOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Nút xem / mua
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              if (message.productId == null) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    seedId: message.productId!,
                                    fallbackName: name,
                                    fallbackImage: image,
                                    fallbackPrice: message.productPrice ?? 0,
                                    fallbackOriginalPrice: message.productPrice ?? 0,
                                    fallbackDiscount: 0,
                                    fallbackRating: 4.8,
                                    fallbackSoldCount: 100,
                                    fallbackLocation: '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shopeeOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Xem sản phẩm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeLabel(message.sentAt),
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
