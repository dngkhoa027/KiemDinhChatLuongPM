import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_message_model.dart';
import '../../services/auth_service.dart';
import '../../services/shop_chat_service.dart';
import '../../widgets/shop_avatar.dart';
import '../auth/login_screen.dart';
import 'shop_chat_screen.dart';

/// Màn hình "Danh sách Chat" — liệt kê tất cả các SHOP mà người mua đang
/// đăng nhập đã từng nhắn tin, giống tab Chat của Shopee. Bấm vào 1 dòng sẽ
/// mở lại toàn bộ lịch sử chat với shop đó (ShopChatScreen).
///
/// Icon "Chat" ở các trang chung (Trang chủ, Cá nhân, Thông báo...) sẽ mở
/// màn hình này. Riêng nút "Chat ngay" ở trang Chi tiết sản phẩm vẫn mở
/// thẳng vào ShopChatScreen của shop đó (kèm gửi card sản phẩm), không đi
/// qua màn hình danh sách này.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final ShopChatService _chatService = ShopChatService.instance;
  User? get _firebaseUser => AuthService.instance.currentFirebaseUser;

  String _filter = 'all'; // 'all' | 'unread' (giống Shopee "Tất cả" / "Đang hoạt động")

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inHours < 24 && now.day == dt.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays < 7) {
      const weekdays = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];
      return weekdays[dt.weekday - 1];
    }
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year.toString().substring(2)}';
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
        titleSpacing: 16,
        title: const Text('Chat', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
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
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để xem danh sách chat với các shop',
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
    );
  }

  Widget _buildBody(String uid) {
    return Column(
      children: [
        _buildFilterTabs(),
        Expanded(
          child: StreamBuilder<List<ShopConversationSummary>>(
            stream: _chatService.watchConversations(buyerUid: uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: shopeeOrange));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Không tải được danh sách chat.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ),
                );
              }
              var conversations = snapshot.data ?? const [];
              if (_filter == 'unread') {
                conversations = conversations.where((c) => c.lastSenderIsShop).toList();
              }
              if (conversations.isEmpty) {
                return _buildEmpty();
              }
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: conversations.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 78, color: Colors.grey.shade100),
                itemBuilder: (context, index) => _ConversationTile(
                  conversation: conversations[index],
                  timeLabel: _relativeTime(conversations[index].lastMessageAt),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopChatScreen(shopName: conversations[index].shopName),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    Widget chip(String label, String value) {
      final selected = _filter == value;
      return GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? shopeeOrange.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? shopeeOrange : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          chip('Tất cả', 'all'),
          chip('Đang hoạt động', 'unread'),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa có cuộc trò chuyện nào với shop',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Vào trang sản phẩm hoặc trang shop và bấm "Chat" để bắt đầu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ShopConversationSummary conversation;
  final String timeLabel;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = conversation.lastSenderIsShop
        ? conversation.lastMessage
        : conversation.lastMessage; // Có thể phân biệt thêm "Bạn: " nếu muốn

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShopAvatar(shopName: conversation.shopName, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (!conversation.lastSenderIsShop)
                        Icon(Icons.done, size: 14, color: Colors.grey.shade400),
                      if (!conversation.lastSenderIsShop) const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeLabel,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
