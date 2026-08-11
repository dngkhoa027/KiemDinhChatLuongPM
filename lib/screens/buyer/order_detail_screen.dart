import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/mock_data.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'tracking_screen.dart';

/// Trang "Thông tin đơn hàng" — layout sát Shopee thật.
/// Phân nhánh UI theo trạng thái: chờ duyệt / đang giao / đã giao / đã hủy.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color teal = Color(0xFF26A69A);
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color subText = Color(0xFF757575);

  bool _infoExpanded = false;

  static String money(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buf.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write('.');
    }
    return "$bufđ";
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy $hh:$mi';
  }

  static String _fmtDayMonth(DateTime d) {
    return '${d.day} Thg ${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, _) {
        final order = OrderService.instance.byId(widget.orderId);
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: orange),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
            centerTitle: false,
            titleSpacing: 0,
          ),
          body: order == null
              ? const Center(child: Text('Không tìm thấy đơn hàng', style: TextStyle(color: subText)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _statusBanner(order),
                    _shippingSection(order),
                    const SizedBox(height: 8),
                    _addressSection(order),
                    const SizedBox(height: 8),
                    _productSection(order),
                    const SizedBox(height: 8),
                    _supportSection(order),
                    const SizedBox(height: 8),
                    _orderInfoSection(order),
                    const SizedBox(height: 16),
                    _recommendSection(),
                    const SizedBox(height: 80),
                  ],
                ),
          bottomNavigationBar: order == null ? null : _bottomBar(context, order),
        );
      },
    );
  }

  // ── Status banner (teal) ──
  Widget _statusBanner(Order order) {
    final isCompleted = order.status == OrderStatus.completed;
    final isCancelled = order.status == OrderStatus.cancelled;
    final isPending = order.status == OrderStatus.toConfirm ||
        order.status == OrderStatus.toShip;

    String title;
    String? subtitle;
    if (isCompleted) {
      title = 'Đơn hàng đã hoàn thành';
    } else if (isCancelled) {
      title = 'Đơn hàng đã hủy';
    } else if (isPending) {
      final guarantee = order.createdAt.add(const Duration(days: 5));
      title = 'Ngày đảm bảo nhận hàng: ${_fmtDayMonth(guarantee)}';
      subtitle = 'Người bán đang chuẩn bị hàng';
    } else {
      title = 'Đang giao hàng';
      subtitle = 'Đơn hàng đang trên đường đến bạn';
    }

    final canTrack = order.status == OrderStatus.toReceive ||
        order.status == OrderStatus.toShip ||
        order.status == OrderStatus.completed;

    return Material(
      color: isCancelled ? Colors.grey.shade600 : teal,
      child: InkWell(
        onTap: canTrack
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order.id)),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5),
                      ),
                    ],
                    if (canTrack) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Xem thông tin vận chuyển ›',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              if (canTrack)
                const Icon(Icons.chevron_right, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shipping info ──
  Widget _shippingSection(Order order) {
    final isCompleted = order.status == OrderStatus.completed;
    final guaranteeDate = order.createdAt.add(const Duration(days: 5));
    final voucherAmount = isCompleted ? 20000 : 15000;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery promise
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                    children: [
                      TextSpan(
                        text:
                            'Giao nhanh đúng hẹn: nhận Voucher ${money(voucherAmount)} nếu đơn hàng được giao đến bạn sau ngày ${_fmtDate(guaranteeDate).split(' ').first}. ',
                      ),
                      const TextSpan(
                        text: 'Xem thêm',
                        style: TextStyle(color: Color(0xFF1976D2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Thông tin vận chuyển',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222222)),
          ),
          const SizedBox(height: 8),
          if (isCompleted) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SPX Express - Trong Ngày: VN${order.id.hashCode.abs()}T',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 18, color: teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giao hàng thành công',
                        style: TextStyle(color: teal, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _fmtDate(order.statusUpdatedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text('Nhanh', style: TextStyle(fontSize: 13.5, color: Color(0xFF333333))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: orange),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'ĐỒNG KIỂM',
                    style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Được đồng kiểm.', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Address ──
  Widget _addressSection(Order order) {
    final a = order.address;
    final canUpdate = order.status == OrderStatus.toConfirm ||
        order.status == OrderStatus.toShip;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Địa chỉ nhận hàng',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222222)),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.fullName}  (${a.phone})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      a.fullAddress,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (canUpdate)
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: const Text('Cập nhật', style: TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Products ──
  Widget _productSection(Order order) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          for (final group in order.itemsByShop) ...[
            // Shop row
            Row(
              children: [
                if (group.value.first.isMall)
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'Mall',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                Expanded(
                  child: Text(
                    group.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 8),
            // LIVE promo bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, size: 16, color: orange),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'LIVE  Săn Voucher Live Cùng Shop',
                      style: TextStyle(color: orange, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      minimumSize: Size.zero,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    ),
                    child: const Text('Xem ngay', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Items
            for (final item in group.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(
                        item.image,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
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
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, height: 1.3),
                            ),
                            if (item.variant.isNotEmpty)
                              Text(
                                item.variant,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'x${item.quantity}',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 4),
                        if (item.originalPrice > item.price)
                          Text(
                            money(item.originalPrice),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          money(item.price),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            // Thành tiền
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thành tiền: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    money(order.grandTotal),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade500),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Support ──
  Widget _supportSection(Order order) {
    final isCompleted = order.status == OrderStatus.completed;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn cần hỗ trợ?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222222)),
          ),
          const SizedBox(height: 4),
          if (isCompleted)
            _supportTile(
              icon: Icons.replay_outlined,
              title: 'Gửi yêu cầu Trả hàng/Hoàn tiền',
              subtitle: 'Gửi yêu cầu trễ nhất vào 19 Thg 8',
            ),
          _supportTile(icon: Icons.chat_bubble_outline, title: 'Liên hệ Shop'),
          _supportTile(icon: Icons.help_outline, title: 'Trung tâm Hỗ trợ'),
        ],
      ),
    );
  }

  Widget _supportTile({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF555555)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333))),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ── Order info (code, payment, times) — có thể thu gọn / mở rộng ──
  Widget _orderInfoSection(Order order) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          // Mã đơn (luôn hiện)
          Row(
            children: [
              const Text('Mã đơn hàng', style: TextStyle(fontSize: 13.5, color: Color(0xFF333333))),
              const Spacer(),
              Text(
                order.id.length > 14 ? order.id.substring(0, 14).toUpperCase() : order.id.toUpperCase(),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.id));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('SAO CHÉP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment (luôn hiện)
          Row(
            children: [
              const Text('Phương thức thanh toán', style: TextStyle(fontSize: 13.5, color: Color(0xFF333333))),
              const Spacer(),
              Text(
                order.paymentMethodLabel,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // SPayLater promo (luôn hiện)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 18, color: orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trả góp nhiều kỳ – Nhẹ gánh chi tiêu',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
                  ),
                ),
                Text(
                  'Chuyển đổi ngay >',
                  style: TextStyle(fontSize: 12.5, color: orange, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Phần chi tiết có thể thu gọn
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  _infoRow('Thời gian đặt hàng', _fmtDate(order.createdAt)),
                  _infoRow('Thời gian thanh toán', _fmtDate(order.createdAt)),
                  if (order.status != OrderStatus.toConfirm)
                    _infoRow(
                      'Thời gian đơn vị vận chuyển lấy hàng',
                      _fmtDate(order.createdAt.add(const Duration(hours: 1))),
                    ),
                  if (order.status == OrderStatus.completed)
                    _infoRow('Thời gian hoàn thành đơn', _fmtDate(order.statusUpdatedAt)),
                ],
              ),
            ),
            crossFadeState: _infoExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),

          const SizedBox(height: 10),
          // Nút Xem chi tiết / Rút gọn
          GestureDetector(
            onTap: () => setState(() => _infoExpanded = !_infoExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _infoExpanded ? 'Rút gọn' : 'Xem chi tiết',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _infoExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
          ),
          Text(value, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // ── Recommend — lấy sản phẩm đa dạng từ home + mall ──
  Widget _recommendSection() {
    // Trộn sản phẩm từ 2 nguồn, lấy offset khác nhau để không trùng lặp
    final home = MockData.homeProducts;
    final mall = MockData.mallProducts;
    final products = <Map<String, dynamic>>[];
    // Lấy xen kẽ: home[1], mall[0], home[3], mall[2], home[5], mall[4]...
    for (int i = 0; i < 6; i++) {
      if (i.isEven) {
        final idx = (i ~/ 2 * 2 + 1) % home.length;
        products.add(Map<String, dynamic>.from(home[idx]));
      } else {
        if (mall.isEmpty) continue;
        final idx = (i ~/ 2) % mall.length;
        products.add(Map<String, dynamic>.from(mall[idx]));
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Có thể bạn cũng thích',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => _RecommendCard(product: products[i]),
          ),
        ),
      ],
    );
  }

  // ── Bottom action bar ──
  Widget _bottomBar(BuildContext context, Order order) {
    List<Widget> buttons;
    switch (order.status) {
      case OrderStatus.toConfirm:
      case OrderStatus.toShip:
        buttons = [
          _btn('Hủy đơn hàng', primary: false, onTap: () {}),
          const SizedBox(width: 10),
          _btn('Liên hệ Shop', primary: false, onTap: () {}),
        ];
        break;
      case OrderStatus.toReceive:
        buttons = [
          _btn('Theo dõi đơn', primary: false, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order.id)),
            );
          }),
          const SizedBox(width: 10),
          _btn('Đã nhận hàng', primary: true, onTap: () {
            OrderService.instance.advanceToNextStatus(order.id);
          }),
        ];
        break;
      case OrderStatus.completed:
        buttons = [
          _btn('Yêu cầu Trả hàng/Hoàn tiền', primary: false, onTap: () {}),
          const SizedBox(width: 10),
          _btn('Đánh giá', primary: true, onTap: () {}),
        ];
        break;
      case OrderStatus.cancelled:
        buttons = [
          _btn('Mua lại', primary: true, onTap: () {}),
        ];
        break;
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        children: buttons.map((w) {
          if (w is SizedBox) return w;
          return Expanded(child: w);
        }).toList(),
      ),
    );
  }

  Widget _btn(String text, {required bool primary, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary ? orange : const Color(0xFF333333),
        side: BorderSide(color: primary ? orange : Colors.grey.shade400),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Card gợi ý sản phẩm — hiển thị đa dạng (tag, rating, sold, location…)
class _RecommendCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _RecommendCard({required this.product});

  static const Color orange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    final discount = product['discount'] as int? ?? 0;
    final title = (product['title'] ?? product['name'] ?? '') as String;
    final price = (product['price'] ?? '').toString();
    final image = (product['image'] ?? product['imageUrl'] ?? '') as String;
    final sold = (product['sold'] ?? '').toString();
    final rating = product['rating']?.toString();
    final location = (product['location'] ?? '') as String;
    final tag = (product['tag'] ?? product['badge'] ?? '') as String;
    final isMall = product['isMall'] == true || tag.toLowerCase().contains('mall');

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
                  // Title với badge Mall / tag
                  Text.rich(
                    TextSpan(
                      children: [
                        if (isMall)
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: _MiniBadge(text: 'Mall', color: orange),
                            ),
                          ),
                        if (!isMall && tag.isNotEmpty)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _MiniBadge(
                                text: tag.length > 10 ? '${tag.substring(0, 10)}…' : tag,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ),
                        TextSpan(
                          text: title,
                          style: const TextStyle(fontSize: 12.5, height: 1.25, color: Color(0xFF222222)),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    price.endsWith('đ') ? price : '${price}đ',
                    style: const TextStyle(
                      color: orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (rating != null || sold.isNotEmpty)
                    Row(
                      children: [
                        if (rating != null) ...[
                          const Icon(Icons.star, size: 11, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text(rating, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                        ],
                        if (sold.isNotEmpty)
                          Flexible(
                            child: Text(
                              '${rating != null ? ' | ' : ''}$sold đã bán',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
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

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

