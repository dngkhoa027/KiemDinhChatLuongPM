import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

/// Trang chi tiết 1 đơn hàng: địa chỉ nhận hàng, sản phẩm, tổng tiền và
/// timeline trạng thái xử lý đơn.
///
/// App demo không có backend/ĐVVC thật để tự cập nhật trạng thái theo thời
/// gian, nên màn hình có nút hành động ở cuối trang để NGƯỜI DÙNG tự bấm mô
/// phỏng từng mốc xử lý đơn (Người bán xác nhận -> Lấy hàng -> Giao hàng
/// thành công), đúng thứ tự Chờ xác nhận -> Chờ lấy hàng -> Chờ giao hàng ->
/// Giao hàng thành công.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  static const Color orange = Color(0xFFEE4D2D);
  static const Color subText = Color(0xFF757575);
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color success = Color(0xFF2E9E5B);

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, _) {
        final order = OrderService.instance.byId(orderId);
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: orange),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Chi tiết đơn hàng',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
            ),
          ),
          body: order == null
              ? const Center(child: Text('Không tìm thấy đơn hàng', style: TextStyle(color: subText)))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _statusHeader(order),
                    _timeline(order),
                    const SizedBox(height: 8),
                    _section(child: _addressCard(order)),
                    const SizedBox(height: 8),
                    _section(child: _productsCard(order)),
                    const SizedBox(height: 8),
                    _section(child: _summaryCard(order)),
                  ],
                ),
          bottomNavigationBar: order == null ? null : _actionBar(context, order),
        );
      },
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _statusHeader(Order order) {
    final cancelled = order.status == OrderStatus.cancelled;
    return Container(
      width: double.infinity,
      color: cancelled ? Colors.grey.shade600 : orange,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Row(
        children: [
          Icon(order.status.icon, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  order.status == OrderStatus.completed
                      ? 'Đơn hàng đã được giao thành công'
                      : 'Đơn hàng của bạn đang được xử lý',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(Order order) {
    if (order.status == OrderStatus.cancelled) return const SizedBox.shrink();
    final currentIndex = kOrderForwardFlow.indexOf(order.status);
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
      child: Row(
        children: [
          for (int i = 0; i < kOrderForwardFlow.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= currentIndex ? orange : Colors.grey.shade300,
                ),
              ),
            _timelineStep(kOrderForwardFlow[i], done: i <= currentIndex),
          ],
        ],
      ),
    );
  }

  Widget _timelineStep(OrderStatus status, {required bool done}) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? orange : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(status.icon, size: 14, color: done ? Colors.white : Colors.grey.shade500),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 62,
          child: Text(
            status.shortLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.15,
              color: done ? Colors.black87 : Colors.grey.shade500,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressCard(Order order) {
    final a = order.address;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, color: orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${a.fullName}  (${a.phone})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              const SizedBox(height: 4),
              Text(a.fullAddress, style: const TextStyle(fontSize: 12.5, color: subText, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productsCard(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int g = 0; g < order.itemsByShop.length; g++) ...[
          if (g > 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          Text(
            order.itemsByShop[g].key,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          for (final item in order.itemsByShop[g].value) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      item.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        if (item.variant.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(item.variant, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              money(item.price),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: orange),
                            ),
                            const Spacer(),
                            Text(
                              'x${item.quantity > 0 ? item.quantity : 1}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _summaryCard(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 10),
        _line('Phương thức thanh toán', order.paymentMethodLabel),
        _line('Tổng tiền hàng', money(order.itemsTotal)),
        if (order.discount > 0) _line('Giảm giá', '-${money(order.discount)}', valueColor: orange),
        const Divider(height: 20),
        _line('Tổng thanh toán', money(order.grandTotal), bold: true),
      ],
    );
  }

  Widget _line(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: bold ? 14 : 12.5, color: bold ? Colors.black87 : subText),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? (bold ? orange : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== NÚT HÀNH ĐỘNG (MÔ PHỎNG XỬ LÝ ĐƠN) =====================
  Widget _actionBar(BuildContext context, Order order) {
    String caption;
    String buttonLabel;
    VoidCallback? onPressed;

    switch (order.status) {
      case OrderStatus.toConfirm:
        caption = 'Đơn hàng đang chờ Shop xác nhận.';
        buttonLabel = 'Người bán xác nhận đơn hàng';
        onPressed = () => OrderService.instance.advanceToNextStatus(order.id);
        break;
      case OrderStatus.toShip:
        caption = 'Shop đang chuẩn bị hàng, chờ đơn vị vận chuyển lấy hàng.';
        buttonLabel = 'Đã lấy hàng, bắt đầu giao';
        onPressed = () => OrderService.instance.advanceToNextStatus(order.id);
        break;
      case OrderStatus.toReceive:
        caption = 'Đơn hàng đang trên đường giao đến bạn.';
        buttonLabel = 'Đã giao hàng thành công';
        onPressed = () => OrderService.instance.advanceToNextStatus(order.id);
        break;
      case OrderStatus.completed:
        caption = 'Đơn hàng đã hoàn tất. Cảm ơn bạn đã mua hàng!';
        buttonLabel = 'Đã hoàn thành';
        onPressed = null;
        break;
      case OrderStatus.cancelled:
        caption = 'Đơn hàng đã bị hủy.';
        buttonLabel = 'Đã hủy';
        onPressed = null;
        break;
    }

    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(caption, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.status == OrderStatus.completed ? success : orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        order.status == OrderStatus.completed ? success : Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
