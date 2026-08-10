/// Các model dùng cho màn hình Giỏ hàng.
/// Được tách riêng ra khỏi cart_screen.dart để lib/data/mock_data.dart
/// có thể dùng chung mà không bị lặp code hoặc import vòng.
class CartItem {
  final String image;
  final String name;
  final String variant;
  final int price;
  final int originalPrice;
  final bool freeship;
  final String category;
  int quantity;
  bool selected;

  CartItem({
    required this.image,
    required this.name,
    required this.variant,
    required this.price,
    required this.originalPrice,
    this.freeship = false,
    this.category = '',
    this.quantity = 1,
    this.selected = true,
  });
}

class CartShop {
  final String shopName;
  final bool isMall;
  final bool isFavorite;
  final List<CartItem> items;

  CartShop({
    required this.shopName,
    required this.items,
    this.isMall = false,
    this.isFavorite = false,
  });

  bool get allSelected => items.every((i) => i.selected);
}

/// Một dòng sản phẩm sẽ được đưa sang trang Thanh toán.
///
/// Dùng chung cho cả 2 luồng: "Mua ngay" (1 sản phẩm, từ trang chi tiết sản
/// phẩm / livestream) và "Mua Hàng" từ Giỏ hàng (có thể nhiều sản phẩm,
/// nhiều shop cùng lúc). Nếu [sourceCartItem] khác null nghĩa là dòng này
/// lấy từ giỏ hàng thật — sau khi đặt hàng thành công, CheckoutScreen sẽ
/// xoá đúng các item này khỏi [CartItem] tương ứng trong giỏ.
class CheckoutLineItem {
  final String shopName;
  final bool isMall;
  final String image;
  final String name;
  final String variant;
  final int price;
  final int originalPrice;
  final int quantity;
  final String category;
  final CartItem? sourceCartItem;

  const CheckoutLineItem({
    required this.shopName,
    required this.image,
    required this.name,
    required this.variant,
    required this.price,
    required this.originalPrice,
    required this.quantity,
    this.isMall = false,
    this.category = '',
    this.sourceCartItem,
  });

  /// Tạo danh sách [CheckoutLineItem] từ các sản phẩm ĐANG ĐƯỢC CHỌN
  /// trong giỏ hàng (dùng cho nút "Mua Hàng" ở trang Giỏ hàng).
  static List<CheckoutLineItem> fromSelectedCart(List<CartShop> shops) {
    final result = <CheckoutLineItem>[];
    for (final shop in shops) {
      for (final item in shop.items) {
        if (!item.selected) continue;
        result.add(CheckoutLineItem(
          shopName: shop.shopName,
          isMall: shop.isMall,
          image: item.image,
          name: item.name,
          variant: item.variant,
          price: item.price,
          originalPrice: item.originalPrice,
          quantity: item.quantity,
          category: item.category,
          sourceCartItem: item,
        ));
      }
    }
    return result;
  }
}
