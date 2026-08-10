import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../models/cart_models.dart';
import '../models/order_model.dart';

/// Quản lý danh sách đơn hàng của người dùng (in-memory, dùng chung toàn
/// app qua singleton — giống cách [CartService] hoạt động).
///
/// App demo này không có backend/ĐVVC thật nên trạng thái đơn hàng được
/// tiến tới bước kế tiếp thủ công qua [advanceToNextStatus] (gọi từ trang
/// chi tiết đơn hàng), thay vì tự động theo thời gian thật.
class OrderService extends ChangeNotifier {
  OrderService._();
  static final OrderService instance = OrderService._();

  final List<Order> _orders = [];
  int _seq = 0;

  /// Đơn mới nhất hiển thị trước, giống danh sách "Đơn mua" thật của Shopee.
  List<Order> get orders => List.unmodifiable(_orders.reversed);

  List<Order> byStatus(OrderStatus status) =>
      orders.where((o) => o.status == status).toList();

  Order? byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Order createOrder({
    required List<CheckoutLineItem> items,
    required Address address,
    required String paymentMethodLabel,
    required int itemsTotal,
    required int discount,
    required int grandTotal,
  }) {
    _seq++;
    final now = DateTime.now();
    final order = Order(
      id: 'SPE${now.millisecondsSinceEpoch}$_seq',
      createdAt: now,
      items: items,
      address: address,
      paymentMethodLabel: paymentMethodLabel,
      itemsTotal: itemsTotal,
      discount: discount,
      grandTotal: grandTotal,
    );
    _orders.add(order);
    notifyListeners();
    return order;
  }

  /// Chuyển đơn sang trạng thái kế tiếp trong [kOrderForwardFlow] — dùng để
  /// mô phỏng các mốc "Người bán xác nhận" / "Đã lấy hàng" / "Giao hàng
  /// thành công" vì app demo không có backend thật để tự cập nhật.
  void advanceToNextStatus(String orderId) {
    final order = byId(orderId);
    if (order == null) return;
    final idx = kOrderForwardFlow.indexOf(order.status);
    if (idx == -1 || idx >= kOrderForwardFlow.length - 1) return;
    order.status = kOrderForwardFlow[idx + 1];
    order.statusUpdatedAt = DateTime.now();
    notifyListeners();
  }
}
