import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../buyer/home_screen.dart';
import 'login_screen.dart';

/// Cổng vào app: quyết định hiển thị Trang chủ hay Trang đăng nhập dựa
/// trên trạng thái đăng nhập Firebase HIỆN TẠI.
///
/// Firebase Auth trên Android/iOS tự lưu phiên đăng nhập vào bộ nhớ máy
/// (persistence LOCAL theo mặc định), nên [FirebaseAuth.instance.currentUser]
/// vẫn còn nguyên sau khi tắt hẳn app rồi mở lại — ta chỉ cần LẮNG NGHE
/// [authStateChanges] ngay từ màn hình đầu tiên thay vì luôn mở thẳng màn
/// đăng nhập như trước, là có được tính năng "ghi nhớ đăng nhập".
///
/// Người dùng chỉ quay lại màn đăng nhập khi: chưa từng đăng nhập, hoặc
/// đã chủ động bấm "Đăng xuất" (gọi `AuthService.instance.logout()`).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang kiểm tra phiên đăng nhập đã lưu -> hiện splash ngắn thay vì
        // để trắng màn hình hoặc nháy qua trang Login rồi mới vào Home.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;
        if (user != null) {
          return const ShopeeHomePage();
        }
        return const ShopeeLoginPage();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  static const Color shopeeOrange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: shopeeOrange,
      body: Center(
        child: Text(
          'Shopee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
