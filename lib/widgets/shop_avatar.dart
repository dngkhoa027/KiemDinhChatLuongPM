import 'package:flutter/material.dart';

/// Avatar dùng chung cho MỌI shop trong app (trang chi tiết sản phẩm, trang
/// Shop, giỏ hàng...). Vì app demo dùng shop "ảo" sinh ra từ brand/category
/// của sản phẩm (không có ảnh đại diện thật upload lên), avatar được tạo tự
/// động theo kiểu "monogram" (chữ viết tắt trên nền gradient) — giống cách
/// Slack/Notion/Google tạo avatar mặc định cho tài khoản chưa có ảnh: luôn
/// ổn định (cùng 1 shop luôn ra đúng avatar đó), không phụ thuộc mạng nên
/// không bao giờ bị vỡ ảnh.
class ShopAvatar extends StatelessWidget {
  final String shopName;
  final double radius;
  final bool showBorder;

  const ShopAvatar({
    super.key,
    required this.shopName,
    this.radius = 20,
    this.showBorder = false,
  });

  // Các cặp gradient tương phản tốt với chữ trắng, đủ đa dạng để các shop
  // khác nhau nhìn khác biệt rõ (không lặp lại quá dễ nhận ra như màu đơn).
  static const List<List<Color>> _gradients = [
    [Color(0xFF4568DC), Color(0xFFB06AB3)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    [Color(0xFFF7971E), Color(0xFFFFA53D)],
    [Color(0xFF0072FF), Color(0xFF00C6FF)],
    [Color(0xFFEE0979), Color(0xFFFF6A00)],
    [Color(0xFF834D9B), Color(0xFFD04ED6)],
    [Color(0xFF16A085), Color(0xFF2ECC71)],
    [Color(0xFF3E5151), Color(0xFF6E48AA)],
    [Color(0xFFC33764), Color(0xFF1D2671)],
  ];

  int get _hash => shopName.trim().toLowerCase().codeUnits.fold<int>(0, (a, b) => a * 31 + b);

  List<Color> get _gradientColors => _gradients[_hash.abs() % _gradients.length];

  /// Lấy phần "tên gốc" của shop trước dấu chấm, VD "nike.official" -> "nike",
  /// rồi viết hoa chữ đầu + chữ 2 viết thường để ra chữ viết tắt kiểu logo
  /// (VD "Ni", "As", "Sh") — nếu tên chỉ có 1 ký tự thì dùng luôn 1 chữ.
  String get _monogram {
    final core = shopName.trim().split('.').first.trim();
    if (core.isEmpty) return 'S';
    if (core.length == 1) return core.toUpperCase();
    return core[0].toUpperCase() + core[1].toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
      ),
      child: Text(
        _monogram,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.72,
          letterSpacing: -0.3,
        ),
      ),
    );

    if (!showBorder) return avatar;

    return Container(
      padding: EdgeInsets.all(radius * 0.06 + 1),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: avatar,
    );
  }
}
