/// Model sản phẩm dùng chung cho toàn bộ app.
///
/// Dữ liệu số (giá gốc USD, % giảm giá, đánh giá, tồn kho, hình ảnh...)
/// được lấy thật từ API sản phẩm công khai (DummyJSON), sau đó được
/// bản địa hoá: đổi tên sản phẩm sang tiếng Việt và quy đổi giá tiền
/// sang VNĐ (xem `ProductApiService`).
class Product {
  final int id;
  final String name;
  final String description;
  final int price; // đơn vị: VNĐ
  final int originalPrice; // đơn vị: VNĐ
  final int discountPercent;
  final double rating;
  final int ratingCount;
  final int soldCount;
  final int stock;
  final String category;
  final String categoryLabel;
  final String brand;
  final String shopName;
  final String location;
  final List<String> images;
  final List<String> highlights;

  // ---- Dành cho sản phẩm do NGƯỜI DÙNG tự đăng bán (seller) ----
  // Sản phẩm lấy từ API demo (DummyJSON) sẽ để các trường này là null/false.
  // Sản phẩm do seller tự đăng (lưu ở Firestore collection `products`) sẽ có
  // đầy đủ `sellerId` + `shopId` để biết sản phẩm thuộc shop nào, dùng để lọc
  // "Sản phẩm của tôi" trong màn hình Kênh Người Bán.
  final String? sellerId;
  final String? shopId;
  final bool isUserListed;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    required this.rating,
    required this.ratingCount,
    required this.soldCount,
    required this.stock,
    required this.category,
    required this.categoryLabel,
    required this.brand,
    required this.shopName,
    required this.location,
    required this.images,
    this.highlights = const [],
    this.sellerId,
    this.shopId,
    this.isUserListed = false,
  });

  String get thumbnail => images.isNotEmpty ? images.first : '';

  String get priceText => formatVnd(price);

  String get originalPriceText => formatVnd(originalPrice);

  /// Tạo bản sao của [Product], chỉ thay đổi những field được truyền vào.
  /// Dùng khi cần "ép" 1 sản phẩm hiển thị đúng theo shop đang xem (VD: mở
  /// từ trong trang Shop ra thì phải luôn thuộc shop đó, không được lấy lại
  /// brand/shop gốc do API sinh ra).
  Product copyWith({String? shopName}) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
      rating: rating,
      ratingCount: ratingCount,
      soldCount: soldCount,
      stock: stock,
      category: category,
      categoryLabel: categoryLabel,
      brand: brand,
      shopName: shopName ?? this.shopName,
      location: location,
      images: images,
      highlights: highlights,
      sellerId: sellerId,
      shopId: shopId,
      isUserListed: isUserListed,
    );
  }

  String get soldText {
    if (soldCount >= 1000) {
      final k = soldCount / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return '$soldCount';
  }

  /// Chuyển 1 sản phẩm do seller tự đăng (Firestore) thành [Product] để
  /// dùng chung với mọi màn hình hiển thị sản phẩm hiện có (Home, Mall,
  /// ProductDetailScreen...) mà không cần sửa UI của các màn hình đó.
  factory Product.fromSellerMap(int localId, Map<String, dynamic> data) {
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final originalPrice = (data['originalPrice'] as num?)?.toInt() ?? price;
    return Product(
      id: localId,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      price: price,
      originalPrice: originalPrice,
      discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      soldCount: (data['soldCount'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      category: (data['category'] as String?) ?? '',
      categoryLabel: (data['categoryLabel'] as String?) ?? 'Sản phẩm',
      brand: (data['brand'] as String?) ?? '',
      shopName: (data['shopName'] as String?) ?? '',
      location: (data['location'] as String?) ?? 'TP. Hồ Chí Minh',
      images: ((data['images'] as List?) ?? []).map((e) => e.toString()).toList(),
      highlights: ((data['highlights'] as List?) ?? []).map((e) => e.toString()).toList(),
      sellerId: data['sellerId'] as String?,
      shopId: data['shopId'] as String?,
      isUserListed: true,
    );
  }

  /// Chuyển [Product] do seller tạo/sửa trong app thành map để lưu Firestore.
  Map<String, dynamic> toSellerMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'rating': rating,
      'ratingCount': ratingCount,
      'soldCount': soldCount,
      'stock': stock,
      'category': category,
      'categoryLabel': categoryLabel,
      'brand': brand,
      'shopName': shopName,
      'location': location,
      'images': images,
      'highlights': highlights,
      'sellerId': sellerId,
      'shopId': shopId,
    };
  }
}

/// Chuyển chuỗi giá kiểu "199.000" hoặc "199.000đ" thành số nguyên VNĐ.
int parseVndPriceString(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

/// Chuyển chuỗi số lượt bán kiểu Shopee ("2,3k", "10k", "876") thành số nguyên.
int parseSoldCountText(String value) {
  final lower = value.toLowerCase().trim();
  final hasK = lower.contains('k');
  final numeric = lower.replaceAll('k', '').replaceAll('+', '').replaceAll(',', '.');
  final parsed = double.tryParse(numeric) ?? 0;
  return hasK ? (parsed * 1000).round() : parsed.round();
}

/// Định dạng số tiền theo kiểu Việt Nam: 1.234.000đ
String formatVnd(int amount) {
  final s = amount.toString();
  final buffer = StringBuffer();
  final chars = s.split('').reversed.toList();
  for (int i = 0; i < chars.length; i++) {
    buffer.write(chars[i]);
    final posFromRight = i + 1;
    if (posFromRight % 3 == 0 && i != chars.length - 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString().split('').reversed.join()}đ';
}
