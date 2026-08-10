import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';

/// Trang báo "Đặt hàng / Thanh toán thành công" — hiện ra thay cho
/// [PaymentProcessingScreen] sau khi xử lý thanh toán xong, giống trang kết
/// quả thanh toán thật của Shopee. Chặn nút Back hệ thống để tránh quay lại
/// trang loading/Thanh toán đã hoàn tất; bấm Back sẽ có tác dụng như nút
/// "Về Trang chủ".
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  static const Color orange = Color(0xFFEE4D2D);
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

  void _backToHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final order = OrderService.instance.byId(orderId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _backToHome(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: success, size: 84),
                const SizedBox(height: 20),
                const Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text('Mã đơn hàng: $orderId', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                Text(
                  'Cảm ơn bạn đã mua hàng. Đơn hàng của bạn đang chờ Shop xác nhận.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600, height: 1.45),
                ),
                if (order != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng thanh toán',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                        Text(
                          money(order.grandTotal),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: orange),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Xem đơn hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _backToHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Về Trang chủ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
