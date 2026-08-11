import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';
import 'order_search_screen.dart';
import 'write_review_screen.dart';

/// Định dạng số tiền theo kiểu Việt Nam: 1.234.000đ
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

/// Trang "Đơn đã mua" — bám sát layout Shopee thật.
class MyOrdersScreen extends StatefulWidget {
  final int initialTabIndex;
  const MyOrdersScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color pageBg = Color(0xFFF5F5F5);

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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đơn đã mua',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 24, color: orange),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderSearchScreen()),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 22, color: orange),
                onPressed: () {},
              ),
              Positioned(
                top: 11,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: orange,
              unselectedLabelColor: const Color(0xFF222222),
              indicatorColor: orange,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.2,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.2, color: orange),
                insets: EdgeInsets.zero,
              ),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              dividerColor: Colors.transparent,
              // Giảm padding trái tối đa để không dư khoảng trống
              labelPadding: const EdgeInsets.only(left: 12, right: 12),
              padding: const EdgeInsets.only(left: 4),
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
              tabs: [for (final t in _tabs) Tab(text: t.label, height: 36)],
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
        : (tab.status == null
            ? OrderService.instance.orders
            : OrderService.instance.byStatus(tab.status!));

    if (orders.isEmpty) {
      return const _EmptyOrdersWithRecommend();
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => OrderCard(order: orders[i]),
    );
  }
}

class _OrderTab {
  final String label;
  final OrderStatus? status;
  final bool isPlaceholder;
  const _OrderTab(this.label, this.status, {this.isPlaceholder = false});
}

/// Empty state giống Shopee + phần gợi ý sản phẩm
class _EmptyOrdersWithRecommend extends StatelessWidget {
  const _EmptyOrdersWithRecommend();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 56),
        // Illustration clipboard
        Center(
          child: SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 4,
                  left: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE0B2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFCCBC),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: 72,
                  height: 86,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD9A0), width: 1.4),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          height: 3.5,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD9A0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: 26,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DB6AC),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 20,
                  child: Transform.rotate(
                    angle: -0.55,
                    child: const Icon(Icons.edit, size: 20, color: Color(0xFFFFB74D)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Bạn chưa có đơn hàng nào cả',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 40),
        // "Có thể bạn cũng thích"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.7)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Có thể bạn cũng thích',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.7)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: _RecommendGrid(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RecommendGrid extends StatelessWidget {
  const _RecommendGrid();

  @override
  Widget build(BuildContext context) {
    final products = MockData.homeProducts.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.66,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _RecommendCard(product: products[i]),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _RecommendCard({required this.product});

  static const Color orange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    final discount = product['discount'] as int? ?? 0;
    final title = product['title'] as String? ?? '';
    final price = product['price'] as String? ?? '';
    final image = product['image'] as String? ?? '';
    final rating = product['rating']?.toString() ?? '4.9';
    final sold = product['sold'] as String? ?? '';
    final location = product['location'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: const Color(0xFFFFF0E5),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.25),
                  ),
                  const Spacer(),
                  Text(
                    '${price}đ',
                    style: const TextStyle(
                      color: orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 11, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '$rating${sold.isNotEmpty ? ' | $sold đã bán' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ đơn hàng — layout sát screenshot Shopee
class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  static const Color orange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    final shopGroups = order.itemsByShop;
    final firstShopName = shopGroups.isNotEmpty ? shopGroups.first.key : '';
    final items = order.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final firstItem = items.first;
    final isMall = firstItem.isMall;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Shop + status ──
              Row(
                children: [
                  if (isMall) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'Mall',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      firstShopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.status.shortLabel,
                    style: const TextStyle(
                      color: orange,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Product ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      firstItem.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 70,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              color: Color(0xFF222222),
                            ),
                          ),
                          if (firstItem.variant.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              firstItem.variant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'x${firstItem.quantity > 0 ? firstItem.quantity : 1}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 4),
                      if (firstItem.originalPrice > firstItem.price)
                        Text(
                          _formatVnd(firstItem.originalPrice),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade400,
                          ),
                        ),
                      Text(
                        _formatVnd(firstItem.price),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Tổng tiền ──
              Align(
                alignment: Alignment.centerRight,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    children: [
                      TextSpan(text: 'Tổng số tiền (${items.length} sản phẩm): '),
                      TextSpan(
                        text: _formatVnd(order.grandTotal),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Banner đánh giá (Đã giao) ──
              if (order.status == OrderStatus.completed) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
                            children: [
                              TextSpan(text: 'Đánh giá sản phẩm trước '),
                              TextSpan(
                                text: '5 Thg 9',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' để nhận '),
                              TextSpan(
                                text: '600 Xu',
                                style: TextStyle(
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ],

              // ── Nút hành động ──
              ..._actionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actionButtons(BuildContext context) {
    Widget btn(String text, {bool primary = false, VoidCallback? onPressed}) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary ? orange : const Color(0xFF333333),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: primary ? orange : Colors.grey.shade400,
            width: 0.9,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: onPressed ?? () {},
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
      );
    }

    switch (order.status) {
      case OrderStatus.toConfirm:
        return [
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [btn('Hủy đơn hàng')]),
        ];
      case OrderStatus.completed:
        return [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              btn('Trả hàng/Hoàn tiền'),
              const SizedBox(width: 8),
              btn(
                'Đánh giá',
                primary: true,
                onPressed: () {
                  final firstLine = order.items.first;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WriteReviewScreen(
                        item: ReviewableItem(
                          orderId: order.id,
                          itemIndex: 0,
                          shopName: firstLine.shopName,
                          productName: firstLine.name,
                          productImage: firstLine.image,
                          variant: firstLine.variant,
                          daysLeftToReview: 30,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ];
      case OrderStatus.cancelled:
        return [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              btn('Xem Thông tin Hoàn tiền'),
              const SizedBox(width: 8),
              btn('Mua lại', primary: true),
            ],
          ),
        ];
      case OrderStatus.toShip:
      case OrderStatus.toReceive:
        return const [];
    }
  }
}
