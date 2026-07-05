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
  int quantity;
  bool selected;

  CartItem({
    required this.image,
    required this.name,
    required this.variant,
    required this.price,
    required this.originalPrice,
    this.freeship = false,
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
