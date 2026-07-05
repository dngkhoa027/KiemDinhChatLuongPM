import 'package:flutter/foundation.dart';
import '../models/cart_models.dart';

/// Dịch vụ giỏ hàng dùng chung cho toàn bộ app (singleton).
///
/// Trước đây [ShopeeCartPage] tự dựng dữ liệu mẫu riêng mỗi lần mở
/// màn hình, nên bấm "Thêm Vào Giỏ Hàng" ở trang chi tiết sản phẩm không
/// thể làm giỏ hàng thay đổi được. Bằng cách đưa danh sách [CartShop] vào
/// một singleton duy nhất, mọi màn hình (trang sản phẩm, trang giỏ hàng,
/// badge số lượng...) đều đọc/ghi cùng một nguồn dữ liệu.
///
/// Giỏ hàng LUÔN bắt đầu trống — không còn dùng dữ liệu mẫu từ
/// `MockData.buildInitialCartShops()` nữa. Chỉ những sản phẩm người dùng
/// thực sự bấm "Thêm Vào Giỏ Hàng" mới xuất hiện ở đây.
///
/// Đây chỉ là bước "thêm vào giỏ hàng" — CHƯA xử lý thanh toán/đặt hàng.
class CartService extends ChangeNotifier {
  CartService._internal();

  static final CartService instance = CartService._internal();

  /// Danh sách giỏ hàng, nhóm theo shop. Bắt đầu trống; các màn hình có
  /// thể mutate trực tiếp các item bên trong (đổi số lượng, xoá...) rồi
  /// gọi [refresh] để báo cho những listener khác (vd. badge giỏ hàng)
  /// render lại.
  List<CartShop> shops = [];

  /// Tổng số lượng sản phẩm (cộng dồn quantity) đang có trong giỏ.
  int get totalItemCount =>
      shops.expand((s) => s.items).fold(0, (sum, i) => sum + i.quantity);

  /// Thêm 1 sản phẩm vào giỏ hàng.
  ///
  /// Nếu shop đã có trong giỏ thì gộp vào nhóm đó; nếu sản phẩm + phân
  /// loại giống hệt một item đã có thì chỉ cộng dồn số lượng, thay vì
  /// tạo dòng mới — đúng hành vi giỏ hàng thông thường.
  void addToCart({
    required String shopName,
    required String image,
    required String name,
    required String variant,
    required int price,
    required int originalPrice,
    bool isMall = false,
    bool freeship = false,
    int quantity = 1,
  }) {
    CartShop? targetShop;
    for (final s in shops) {
      if (s.shopName == shopName) {
        targetShop = s;
        break;
      }
    }

    if (targetShop == null) {
      targetShop = CartShop(shopName: shopName, isMall: isMall, items: []);
      // Shop vừa thêm sản phẩm mới nhất hiển thị lên đầu giỏ hàng.
      shops.insert(0, targetShop);
    }

    CartItem? existingItem;
    for (final item in targetShop.items) {
      if (item.name == name && item.variant == variant) {
        existingItem = item;
        break;
      }
    }

    if (existingItem != null) {
      existingItem.quantity += quantity;
    } else {
      targetShop.items.add(
        CartItem(
          image: image,
          name: name,
          variant: variant,
          price: price,
          originalPrice: originalPrice,
          quantity: quantity,
          freeship: freeship,
          selected: true,
        ),
      );
    }

    notifyListeners();
  }

  /// Cho phép các màn hình khác (vd. ShopeeCartPage) báo lại thay đổi
  /// sau khi mutate trực tiếp lên [shops] (đổi số lượng, xoá item...).
  void refresh() => notifyListeners();
}
