import 'package:flutter/material.dart';
import 'address_model.dart';
import 'cart_models.dart';

/// Trạng thái xử lý đơn hàng, theo đúng luồng thật của Shopee:
/// Chờ xác nhận -> Chờ lấy hàng -> Chờ giao hàng -> Giao hàng thành công.
enum OrderStatus { toConfirm, toShip, toReceive, completed, cancelled }

/// Thứ tự tiến trình "thuận" của 1 đơn hàng — dùng để biết bước kế tiếp
/// sau mỗi trạng thái (không tính [OrderStatus.cancelled], vì đó là nhánh
/// dừng hẳn chứ không phải bước tiếp theo trong luồng).
const List<OrderStatus> kOrderForwardFlow = [
  OrderStatus.toConfirm,
  OrderStatus.toShip,
  OrderStatus.toReceive,
  OrderStatus.completed,
];

extension OrderStatusX on OrderStatus {
  /// Tên hiển thị đầy đủ (vd. dòng trạng thái to trong trang chi tiết).
  String get label {
    switch (this) {
      case OrderStatus.toConfirm:
        return 'Chờ xác nhận';
      case OrderStatus.toShip:
        return 'Chờ lấy hàng';
      case OrderStatus.toReceive:
        return 'Chờ giao hàng';
      case OrderStatus.completed:
        return 'Giao hàng thành công';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  /// Tên ngắn hiển thị trên thẻ đơn hàng trong danh sách / tab.
  String get shortLabel {
    switch (this) {
      case OrderStatus.toConfirm:
        return 'Chờ xác nhận';
      case OrderStatus.toShip:
        return 'Chờ lấy hàng';
      case OrderStatus.toReceive:
        return 'Chờ giao hàng';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.toConfirm:
        return Icons.receipt_long_outlined;
      case OrderStatus.toShip:
        return Icons.inventory_2_outlined;
      case OrderStatus.toReceive:
        return Icons.local_shipping_outlined;
      case OrderStatus.completed:
        return Icons.task_alt;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

/// 1 đơn hàng đã đặt — tạo ra sau khi thanh toán ở [PaymentProcessingScreen]
/// thành công. Sản phẩm dùng lại [CheckoutLineItem] (đã có sẵn shopName,
/// hình ảnh, giá, số lượng...) để khỏi phải định nghĩa model trùng lặp.
class Order {
  final String id;
  final DateTime createdAt;
  final List<CheckoutLineItem> items;
  final Address address;
  final String paymentMethodLabel;
  final int itemsTotal;
  final int discount;
  final int grandTotal;
  OrderStatus status;
  DateTime statusUpdatedAt;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.paymentMethodLabel,
    required this.itemsTotal,
    required this.discount,
    required this.grandTotal,
    this.status = OrderStatus.toConfirm,
    DateTime? statusUpdatedAt,
  }) : statusUpdatedAt = statusUpdatedAt ?? createdAt;

  int get totalQuantity =>
      items.fold(0, (sum, i) => sum + (i.quantity > 0 ? i.quantity : 1));

  /// Sản phẩm nhóm theo shop, giữ thứ tự xuất hiện — dùng để hiển thị ở
  /// trang chi tiết đơn hàng giống cách trang Thanh toán đã hiển thị.
  List<MapEntry<String, List<CheckoutLineItem>>> get itemsByShop {
    final map = <String, List<CheckoutLineItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.shopName, () => []).add(item);
    }
    return map.entries.toList();
  }
}
