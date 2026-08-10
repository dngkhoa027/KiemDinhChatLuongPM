import 'package:flutter/material.dart';
import '../../models/address_model.dart';
import '../../models/cart_models.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import 'order_success_screen.dart';

/// Trang "Đang xử lý thanh toán" — hiện ngay sau khi bấm Đặt hàng ở trang
/// Thanh toán, giả lập bước xử lý thanh toán thật của Shopee trước khi báo
/// thành công. Không cho bấm Back trong lúc xử lý (giống app thật).
class PaymentProcessingScreen extends StatefulWidget {
  final List<CheckoutLineItem> items;
  final Address address;
  final String paymentMethodLabel;
  final int itemsTotal;
  final int discount;
  final int grandTotal;

  const PaymentProcessingScreen({
    super.key,
    required this.items,
    required this.address,
    required this.paymentMethodLabel,
    required this.itemsTotal,
    required this.discount,
    required this.grandTotal,
  });

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  static const Color orange = Color(0xFFEE4D2D);

  @override
  void initState() {
    super.initState();
    _process();
  }

  Future<void> _process() async {
    // Giả lập thời gian xử lý thanh toán với cổng thanh toán.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    // Sản phẩm đến từ Giỏ hàng thật -> xoá khỏi giỏ sau khi thanh toán xong
    // (mua ngay không đi qua giỏ nên sẽ không có sourceCartItem).
    final purchasedCartItems = widget.items
        .map((i) => i.sourceCartItem)
        .whereType<CartItem>()
        .toList();
    if (purchasedCartItems.isNotEmpty) {
      CartService.instance.removeItems(purchasedCartItems);
    }

    final order = OrderService.instance.createOrder(
      items: widget.items,
      address: widget.address,
      paymentMethodLabel: widget.paymentMethodLabel,
      itemsTotal: widget.itemsTotal,
      discount: widget.discount,
      grandTotal: widget.grandTotal,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: order.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(strokeWidth: 3.4, color: orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đang xử lý thanh toán...',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text('Vui lòng không tắt ứng dụng', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
