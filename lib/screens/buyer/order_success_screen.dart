import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../services/order_service.dart';
import 'my_orders_screen.dart';

/// Trang "Bạn đã thanh toán" — giống screenshot Shopee sau khi thanh toán thành công.
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  static const Color orange = Color(0xFFEE4D2D);

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

  void _openOrders(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyOrdersScreen(initialTabIndex: 0)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = OrderService.instance.byId(orderId);
    final amount = order?.grandTotal ?? 0;
    final topPad = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _backToHome(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            // ── Orange top section ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF7043), Color(0xFFEE4D2D)],
                ),
              ),
              padding: EdgeInsets.fromLTRB(8, topPad + 4, 8, 20),
              child: Column(
                children: [
                  // App bar row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        onPressed: () => _backToHome(context),
                      ),
                      const Spacer(),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD600),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '36',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Check + amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'Bạn đã thanh toán ${money(amount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Warning
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                        children: const [
                          TextSpan(
                            text:
                                'Để tránh mất tiền vào tay kẻ lừa đảo mạo danh Shipper, bạn tuyệt đối:\n',
                          ),
                          TextSpan(
                            text: 'KHÔNG',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' chuyển khoản cho Shipper khi chưa nhận hàng\n'),
                          TextSpan(
                            text: 'KHÔNG',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' nhấn vào đường dẫn (Link) lạ của Shipper gửi'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _backToHome(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Trang chủ',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openOrders(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Đơn mua',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body scroll ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Gift game banner
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF5722), Color(0xFFFF9800), Color(0xFFFFC107)],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative coins / %
                        Positioned(
                          left: 24,
                          top: 30,
                          child: _decoCircle(Icons.help_outline, const Color(0xFF66BB6A)),
                        ),
                        Positioned(
                          right: 28,
                          top: 36,
                          child: _decoCircle(Icons.card_giftcard, const Color(0xFF66BB6A)),
                        ),
                        Positioned(
                          left: 40,
                          bottom: 40,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF26A69A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 36,
                          bottom: 50,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('S', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ),
                        ),
                        // Center gift
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    '100%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'TRÚNG XU',
                                    style: TextStyle(
                                      color: Color(0xFFFFEB3B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('🎁', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Lượt mở quà còn lại: 1 +',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Recommend
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
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
                        childAspectRatio: 0.68,
                      ),
                      itemCount: MockData.homeProducts.take(4).length,
                      itemBuilder: (context, i) {
                        final p = MockData.homeProducts[i];
                        return _RecommendTile(product: p);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decoCircle(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _RecommendTile extends StatelessWidget {
  final Map<String, dynamic> product;
  const _RecommendTile({required this.product});

  static const Color orange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    final discount = product['discount'] as int? ?? 0;
    final title = product['title'] as String? ?? '';
    final price = product['price'] as String? ?? '';
    final image = product['image'] as String? ?? '';
    final sold = product['sold'] as String? ?? '';

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
                  if (sold.isNotEmpty)
                    Text(
                      '$sold đã bán',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
