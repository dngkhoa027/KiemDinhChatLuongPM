import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Widget dùng để PHÂN QUYỀN hiển thị: tự động kiểm tra vai trò của tài
/// khoản đang đăng nhập (buyer/seller) rồi build ra widget tương ứng.
///
/// Dùng ở bất kỳ đâu cần rẽ nhánh theo quyền, ví dụ mục "Kênh Người Bán"
/// trong Trang cá nhân:
/// ```dart
/// RoleGate(
///   sellerBuilder: (context, user) => SellerDashboardScreen(shopId: user.shopId!),
///   buyerBuilder: (context) => const SellerRegisterScreen(),
/// )
/// ```
class RoleGate extends StatelessWidget {
  final Widget Function(BuildContext context, AppUser user) sellerBuilder;
  final Widget Function(BuildContext context) buyerBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  const RoleGate({
    super.key,
    required this.sellerBuilder,
    required this.buyerBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService.instance.fetchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingBuilder?.call(context) ??
              const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null && user.isSeller && user.shopId != null) {
          return sellerBuilder(context, user);
        }
        return buyerBuilder(context);
      },
    );
  }
}
