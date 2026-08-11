import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../models/cart_models.dart';
import '../models/order_model.dart';

/// Quản lý đơn hàng + mô phỏng luồng trạng thái tự động:
/// Chờ xác nhận → (≈1 phút) → Chờ lấy hàng → (≈45 giây) → Chờ giao hàng.
///
/// Không có backend/seller/shipper thật nên dùng [Timer] in-memory.
class OrderService extends ChangeNotifier {
  OrderService._() {
    _seedDemoOrders();
  }
  static final OrderService instance = OrderService._();

  final List<Order> _orders = [];
  int _seq = 0;

  /// Timer theo orderId — huỷ khi advance thủ công / order hoàn tất.
  final Map<String, Timer> _timers = {};

  /// Thời gian chờ: Chờ xác nhận → Chờ lấy hàng
  static const Duration confirmDelay = Duration(minutes: 1);

  /// Thời gian chờ: Chờ lấy hàng → Chờ giao hàng
  static const Duration shipDelay = Duration(seconds: 45);

  void _seedDemoOrders() {
    const demoAddress = Address(
      id: 'addr_demo',
      fullName: 'Nguyễn Văn A',
      phone: '0901234567',
      detail: '123 Nguyễn Huệ',
      ward: 'Phường Bến Nghé',
      district: 'Quận 1',
      province: 'TP. Hồ Chí Minh',
    );

    _orders.add(Order(
      id: 'SPE_DEMO_001',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      items: const [
        CheckoutLineItem(
          shopName: 'La Roche-Posay Chính Hãng',
          isMall: true,
          image: 'https://picsum.photos/id/201/200/200',
          name: 'Kem dưỡng giảm mụn nhanh 8 giờ La Roche-Posay Effaclar Duo+',
          variant: '15ML',
          price: 226000,
          originalPrice: 260000,
          quantity: 1,
        ),
      ],
      address: demoAddress,
      paymentMethodLabel: 'ShopeePay',
      itemsTotal: 226000,
      discount: 40680,
      grandTotal: 185320,
      status: OrderStatus.completed,
      statusUpdatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ));

    _orders.add(Order(
      id: 'SPE_DEMO_002',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      items: const [
        CheckoutLineItem(
          shopName: 'Hair Beauty Store',
          isMall: true,
          image: 'https://picsum.photos/id/250/200/200',
          name: 'Ô Dù Mini gấp gọn để túi chống tia uv cao cấp',
          variant: 'Xanh Dương Ko Hộp',
          price: 82000,
          originalPrice: 115000,
          quantity: 1,
        ),
      ],
      address: demoAddress,
      paymentMethodLabel: 'ShopeePay',
      itemsTotal: 82000,
      discount: 23984,
      grandTotal: 58016,
      status: OrderStatus.completed,
      statusUpdatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ));

    _orders.add(Order(
      id: 'SPE_DEMO_003',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      items: const [
        CheckoutLineItem(
          shopName: 'Youwatch',
          isMall: true,
          image: 'https://picsum.photos/id/175/200/200',
          name: 'Đồng Hồ Nam Dây Da Chính Hãng Casio MTP',
          variant: 'MTP-V002L-1B',
          price: 2418250,
          originalPrice: 2845000,
          quantity: 1,
        ),
      ],
      address: demoAddress,
      paymentMethodLabel: 'Thẻ tín dụng',
      itemsTotal: 2418250,
      discount: 552198,
      grandTotal: 1866052,
      status: OrderStatus.cancelled,
      statusUpdatedAt: DateTime.now().subtract(const Duration(days: 8)),
    ));

    _orders.add(Order(
      id: 'SPE_DEMO_004',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      items: const [
        CheckoutLineItem(
          shopName: 'NQ30FORUM',
          isMall: false,
          image: 'https://picsum.photos/id/1011/200/200',
          name: 'Quần Jeans Dài COTTON NQ30 Ống Rộng',
          variant: 'Xám LANI,M',
          price: 179000,
          originalPrice: 350000,
          quantity: 1,
        ),
      ],
      address: demoAddress,
      paymentMethodLabel: 'COD',
      itemsTotal: 179000,
      discount: 30430,
      grandTotal: 148570,
      status: OrderStatus.cancelled,
      statusUpdatedAt: DateTime.now().subtract(const Duration(days: 6)),
    ));

    // Demo đang giao — để mở tracking ngay
    _orders.add(Order(
      id: 'SPE_DEMO_SHIP',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      items: const [
        CheckoutLineItem(
          shopName: 'Shopee Mall Official',
          isMall: true,
          image: 'https://picsum.photos/id/26/200/200',
          name: 'Tai nghe Bluetooth không dây chống ồn',
          variant: 'Đen',
          price: 299000,
          originalPrice: 450000,
          quantity: 1,
        ),
      ],
      address: demoAddress,
      paymentMethodLabel: 'SPayLater',
      itemsTotal: 299000,
      discount: 20000,
      grandTotal: 279000,
      status: OrderStatus.toReceive,
      statusUpdatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ));
  }

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
      status: OrderStatus.toConfirm,
      statusUpdatedAt: now,
    );
    _orders.add(order);
    notifyListeners();
    _scheduleAutoAdvance(order.id);
    return order;
  }

  /// Lên lịch tự động: toConfirm → toShip → toReceive.
  void _scheduleAutoAdvance(String orderId) {
    _cancelTimer(orderId);
    final order = byId(orderId);
    if (order == null) return;

    if (order.status == OrderStatus.toConfirm) {
      _timers[orderId] = Timer(confirmDelay, () {
        _autoAdvance(orderId, OrderStatus.toShip);
        // Sau khi xác nhận → chờ lấy hàng, tiếp tục schedule sang đang giao
        _scheduleAutoAdvance(orderId);
      });
    } else if (order.status == OrderStatus.toShip) {
      _timers[orderId] = Timer(shipDelay, () {
        _autoAdvance(orderId, OrderStatus.toReceive);
      });
    }
  }

  void _autoAdvance(String orderId, OrderStatus next) {
    final order = byId(orderId);
    if (order == null) return;
    // Chỉ advance nếu vẫn đang ở bước trước đó
    final expectedPrev = next == OrderStatus.toShip
        ? OrderStatus.toConfirm
        : next == OrderStatus.toReceive
            ? OrderStatus.toShip
            : null;
    if (expectedPrev != null && order.status != expectedPrev) return;
    order.status = next;
    order.statusUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void _cancelTimer(String orderId) {
    _timers[orderId]?.cancel();
    _timers.remove(orderId);
  }

  /// Chuyển đơn sang trạng thái kế tiếp (vẫn giữ cho nút thủ công nếu cần).
  void advanceToNextStatus(String orderId) {
    final order = byId(orderId);
    if (order == null) return;
    final idx = kOrderForwardFlow.indexOf(order.status);
    if (idx == -1 || idx >= kOrderForwardFlow.length - 1) return;
    _cancelTimer(orderId);
    order.status = kOrderForwardFlow[idx + 1];
    order.statusUpdatedAt = DateTime.now();
    notifyListeners();
    // Nếu vừa chuyển sang toShip thì vẫn schedule tiếp sang toReceive
    if (order.status == OrderStatus.toShip) {
      _scheduleAutoAdvance(orderId);
    }
  }

  /// Mã vận đơn giả lập ổn định theo orderId.
  String trackingCode(String orderId) {
    final hash = orderId.hashCode.abs() % 100000000;
    return 'SPXVN${hash.toString().padLeft(10, '0')}';
  }

  String courierName(String orderId) {
    final names = ['SPX Express', 'J&T Express', 'Giao Hàng Nhanh', 'Viettel Post'];
    return names[orderId.hashCode.abs() % names.length];
  }

  /// Timeline mô phỏng hành trình — phụ thuộc status & thời gian cập nhật.
  List<TrackingEvent> buildTrackingEvents(Order order) {
    final created = order.createdAt;
    final updated = order.statusUpdatedAt;
    final events = <TrackingEvent>[];

    events.add(TrackingEvent(
      time: created,
      title: 'Đơn hàng đã được đặt',
      detail: 'Đơn hàng của bạn đã được tạo thành công và đang chờ xác nhận.',
      isDone: true,
    ));

    if (order.status.index >= OrderStatus.toShip.index ||
        order.status == OrderStatus.completed) {
      final t = order.status == OrderStatus.toConfirm
          ? created.add(confirmDelay)
          : (order.status == OrderStatus.toShip
              ? updated
              : updated.subtract(const Duration(minutes: 30)));
      events.add(TrackingEvent(
        time: t.isAfter(created) ? t : created.add(const Duration(minutes: 1)),
        title: 'Người bán đã xác nhận đơn hàng',
        detail: 'Người bán đang chuẩn bị hàng để bàn giao cho đơn vị vận chuyển.',
        isDone: true,
      ));
    } else {
      events.add(TrackingEvent(
        time: created,
        title: 'Đang chờ Người bán xác nhận',
        detail: 'Đơn hàng sẽ được xác nhận trong khoảng 1 phút (mô phỏng).',
        isDone: false,
        isCurrent: true,
      ));
      return events.reversed.toList();
    }

    if (order.status.index >= OrderStatus.toReceive.index ||
        order.status == OrderStatus.completed) {
      final pick = updated.subtract(const Duration(minutes: 20));
      events.add(TrackingEvent(
        time: pick.isAfter(created) ? pick : created.add(const Duration(minutes: 2)),
        title: 'Đơn vị vận chuyển đã lấy hàng',
        detail: '${courierName(order.id)} đã nhận hàng từ Người bán.',
        isDone: true,
      ));
      events.add(TrackingEvent(
        time: updated.subtract(const Duration(minutes: 10)),
        title: 'Đơn hàng đang ở kho phân loại',
        detail: 'Kiện hàng đang được xử lý tại kho trung chuyển.',
        isDone: true,
      ));
      events.add(TrackingEvent(
        time: updated,
        title: 'Đơn hàng đang trên đường giao đến bạn',
        detail: 'Shipper đang giao hàng. Vui lòng chú ý điện thoại.',
        isDone: order.status == OrderStatus.completed,
        isCurrent: order.status == OrderStatus.toReceive,
      ));
    } else if (order.status == OrderStatus.toShip) {
      events.add(TrackingEvent(
        time: updated,
        title: 'Người bán đang chuẩn bị hàng',
        detail: 'Đơn hàng sẽ sớm được bàn giao cho đơn vị vận chuyển.',
        isDone: false,
        isCurrent: true,
      ));
    }

    if (order.status == OrderStatus.completed) {
      events.add(TrackingEvent(
        time: updated,
        title: 'Giao hàng thành công',
        detail: 'Đơn hàng đã được giao thành công. Cảm ơn bạn đã mua sắm!',
        isDone: true,
        isCurrent: true,
      ));
    }

    return events.reversed.toList(); // mới nhất trên cùng
  }
}

class TrackingEvent {
  final DateTime time;
  final String title;
  final String detail;
  final bool isDone;
  final bool isCurrent;

  const TrackingEvent({
    required this.time,
    required this.title,
    required this.detail,
    this.isDone = false,
    this.isCurrent = false,
  });
}
