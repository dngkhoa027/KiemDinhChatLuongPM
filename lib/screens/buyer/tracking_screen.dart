import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

/// Trang theo dõi vận chuyển — UI kiểu Shopee.
class TrackingScreen extends StatelessWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  static const Color orange = Color(0xFFEE4D2D);
  static const Color green = Color(0xFF26A69A);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, _) {
        final order = OrderService.instance.byId(orderId);
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thông tin vận chuyển')),
            body: const Center(child: Text('Không tìm thấy đơn hàng')),
          );
        }
        return _body(context, order);
      },
    );
  }

  Widget _body(BuildContext context, Order order) {
    final svc = OrderService.instance;
    final code = svc.trackingCode(order.id);
    final courier = svc.courierName(order.id);
    final events = svc.buildTrackingEvents(order);

    String statusHeadline;
    Color statusColor;
    switch (order.status) {
      case OrderStatus.toConfirm:
        statusHeadline = 'Đang chờ xác nhận';
        statusColor = orange;
        break;
      case OrderStatus.toShip:
        statusHeadline = 'Người bán đang chuẩn bị hàng';
        statusColor = orange;
        break;
      case OrderStatus.toReceive:
        statusHeadline = 'Đơn hàng đang được giao đến bạn';
        statusColor = green;
        break;
      case OrderStatus.completed:
        statusHeadline = 'Giao hàng thành công';
        statusColor = green;
        break;
      case OrderStatus.cancelled:
        statusHeadline = 'Đơn đã hủy';
        statusColor = Colors.grey;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông tin vận chuyển',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            width: double.infinity,
            color: statusColor,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(
              children: [
                Icon(
                  order.status == OrderStatus.toReceive || order.status == OrderStatus.completed
                      ? Icons.local_shipping
                      : Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusHeadline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.status == OrderStatus.toReceive
                            ? 'Dự kiến giao trong hôm nay — vui lòng chú ý điện thoại'
                            : order.status.label,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF555555)),
                    const SizedBox(width: 8),
                    Text(courier, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text('Mã vận đơn', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép mã vận đơn'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Sao chép', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hành trình đơn hàng',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 16),
                ...List.generate(events.length, (i) {
                  final e = events[i];
                  final isLast = i == events.length - 1;
                  return _timelineItem(e, isLast: isLast);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${order.address.fullName} | ${order.address.phone}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  order.address.fullAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sản phẩm (${order.totalQuantity})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 10),
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.image,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text('x${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(TrackingEvent e, {required bool isLast}) {
    final active = e.isCurrent || e.isDone;
    final color = e.isCurrent ? orange : (e.isDone ? green : Colors.grey.shade400);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: e.isDone ? green.withValues(alpha: 0.4) : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: e.isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: e.isCurrent ? orange : (e.isDone ? const Color(0xFF222222) : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.detail,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmt(e.time),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }
}
