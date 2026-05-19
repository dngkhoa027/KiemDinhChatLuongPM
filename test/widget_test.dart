import 'package:flutter_test/flutter_test.dart';

import 'package:doanflutter/main.dart';

void main() {
  testWidgets('Shopee Login Test', (WidgetTester tester) async {

    // Load app
    await tester.pumpWidget(const ShopeeApp());

    // Kiểm tra chữ Shopee
    expect(find.text('Shopee'), findsOneWidget);

    // Kiểm tra nút đăng nhập
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);

    // Kiểm tra ô mật khẩu
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}