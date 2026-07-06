import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ShopeeApp());
}

class ShopeeApp extends StatelessWidget {
  const ShopeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Shopee Login',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEE4D2D),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
        ),
      ),

      // Giới hạn cỡ chữ hệ thống (Cài đặt > Màn hình > Cỡ chữ) trong khoảng
      // 0.9x - 1.15x. Nếu không giới hạn, khi test trên điện thoại thật có
      // cỡ chữ được set lớn hơn máy ảo, chữ sẽ wrap thêm dòng và làm tràn
      // (overflow) các khung có chiều cao cố định như voucher card, banner...
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clampedScale = mq.textScaler.scale(1).clamp(0.9, 1.15);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(clampedScale)),
          child: child!,
        );
      },

      home: const ShopeeLoginPage(),
    );
  }
}