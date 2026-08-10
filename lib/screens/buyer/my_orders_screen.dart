import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';
import 'order_search_screen.dart';

/// Định dạng số tiền theo kiểu Việt Nam: 1.234.000đ
/// (viết riêng ở đây thay vì phụ thuộc file khác, để tránh lỗi import/khai
/// báo hàm bị lệch giữa các phiên bản project).
String _formatVnd(int amount) {
  final digits = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buf.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buf.write('.');
  }
  return '${buf}đ';
}

/// Trang "Đơn mua" — danh sách đơn hàng chia theo tab trạng thái, giống
/// trang Đơn mua thật của Shopee (appbar có tìm kiếm/chat, 7 tab trạng
/// thái, thẻ đơn hàng đầy đủ giá gốc/giá giảm, banner đánh giá + voucher,
/// nút hành động theo từng trạng thái). Mở từ mục "Đơn mua" ở trang Cá
/// nhân, hoặc trực tiếp từ 1 trong các icon Chờ xác nhận / Chờ lấy hàng /
/// Chờ giao hàng / Đánh giá (mỗi icon mở đúng tab tương ứng qua
/// [initialTabIndex]).
class MyOrdersScreen extends StatefulWidget {
  final int initialTabIndex;
  const MyOrdersScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color pageBg = Color(0xFFF5F5F5);

  // Đúng 7 tab như trang "Đơn mua" thật của Shopee. `status == null` nghĩa
  // là tab "Tất cả" (không lọc). Tab "Trả hàng" không có trạng thái tương
  // ứng trong [OrderStatus] hiện tại (app demo chưa có luồng khiếu nại),
  // nên luôn hiển thị rỗng — để sẵn chỗ cho sau này.
  static const List<_OrderTab> _tabs = [
    _OrderTab('Tất cả', null),
    _OrderTab('Chờ xác nhận', OrderStatus.toConfirm),
    _OrderTab('Chờ lấy hàng', OrderStatus.toShip),
    _OrderTab('Chờ giao hàng', OrderStatus.toReceive),
    _OrderTab('Đã giao', OrderStatus.completed),
    _OrderTab('Trả hàng', null, isPlaceholder: true),
    _OrderTab('Đã hủy', OrderStatus.cancelled),
  ];

  late final TabController _tab = TabController(
    length: _tabs.length,
    vsync: this,
    initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
  );

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đơn mua',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: orange),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderSearchScreen()),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: orange),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: orange,
              unselectedLabelColor: Colors.black87,
              indicatorColor: orange,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              // Bỏ nền pill xám mặc định của TabBar Material 3 khi chọn
              // tab — chỉ giữ lại gạch chân cam như thiết kế gốc.
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(width: 2, color: orange),
                insets: const EdgeInsets.symmetric(horizontal: 0),
              ),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              tabs: [for (final t in _tabs) Tab(text: t.label)],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: OrderService.instance,
        builder: (context, _) {
          return TabBarView(
            controller: _tab,
            children: [for (final t in _tabs) _list(t)],
          );
        },
      ),
    );
  }

  Widget _list(_OrderTab tab) {
    final orders = tab.isPlaceholder
        ? const <Order>[]
        : (tab.status == null ? OrderService.instance.orders : OrderService.instance.byStatus(tab.status!));

    if (orders.isEmpty) {
      return _EmptyOrders(scrollable: true);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
      itemCount: orders.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderTab {
  final String label;
  final OrderStatus? status;
  final bool isPlaceholder;
  const _OrderTab(this.label, this.status, {this.isPlaceholder = false});
}

/// Trạng thái "chưa có đơn hàng nào" — giống hệt illustration + dòng chữ
/// của trang Đơn mua thật (khay giấy bút màu be/cam nhạt).
class _EmptyOrders extends StatelessWidget {
  final bool scrollable;
  const _EmptyOrders({this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 4,
                  left: 8,
                  child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFFFE0B2), shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: 8,
                  right: 6,
                  child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFFCCBC), shape: BoxShape.circle)),
                ),
                Container(
                  width: 78,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD9A0), width: 1.4),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(height: 4, width: double.infinity, color: const Color(0xFFFFD9A0)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: 26,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DB6AC),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Bạn chưa có đơn hàng nào cả', style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5)),
        ],
      ),
    );

    if (!scrollable) return Center(child: content);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [content],
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  static const Color orange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    final shopGroups = order.itemsByShop;
    final firstShopName = shopGroups.first.key;
    final items = order.items;
    final firstItem = items.first;
    final moreCount = items.length - 1;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop + trạng thái
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 16, color: Colors.black87),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    firstShopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  order.status.shortLabel,
                  style: const TextStyle(color: orange, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 18),

            // Sản phẩm đầu tiên
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    firstItem.image,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 68,
                      height: 68,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    firstItem.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'x${firstItem.quantity > 0 ? firstItem.quantity : 1}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (moreCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'và $moreCount sản phẩm khác',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                ),
              ),

            // Giá gốc gạch ngang + giá sau giảm
            if (firstItem.originalPrice > firstItem.price) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatVnd(firstItem.originalPrice),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatVnd(firstItem.price),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],

            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Tổng số tiền (${items.length} sản phẩm): ',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                Text(
                  _formatVnd(order.grandTotal),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: orange),
                ),
              ],
            ),

            ..._actionButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _actionButtons(BuildContext context) {
    Widget outline(String text, {bool filled = false}) => OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: filled ? orange : Colors.black87,
            side: BorderSide(color: filled ? orange : Colors.grey.shade400),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {},
          child: Text(text, style: const TextStyle(fontSize: 13)),
        );

    switch (order.status) {
      case OrderStatus.toConfirm:
        return [
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [outline('Hủy đơn hàng')]),
        ];
      case OrderStatus.completed:
        return [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              outline('Trả hàng/Hoàn tiền'),
              const SizedBox(width: 8),
              outline('Đánh giá', filled: true),
            ],
          ),
        ];
      case OrderStatus.cancelled:
        return [
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [outline('Mua lại', filled: true)]),
        ];
      case OrderStatus.toShip:
      case OrderStatus.toReceive:
        return const [];
    }
  }
}
