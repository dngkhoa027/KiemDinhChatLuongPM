import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

/// ============================================================
/// PRODUCT API SERVICE
/// ------------------------------------------------------------
/// Gọi API sản phẩm công khai (DummyJSON – https://dummyjson.com)
/// để lấy dữ liệu THẬT: giá, % giảm giá, đánh giá, tồn kho, hình
/// ảnh sản phẩm... Vì API trả về dữ liệu tiếng Anh / giá USD nên
/// service này sẽ:
///   • Đổi tên + mô tả sản phẩm sang tiếng Việt (dựa theo danh mục
///     và thương hiệu thật của sản phẩm trả về từ API).
///   • Quy đổi giá từ USD sang VNĐ và làm tròn theo đơn vị nghìn
///     đồng, giống cách hiển thị giá trên Shopee.
///
/// Nếu sau này bạn có API sản phẩm thật của riêng mình (ví dụ API
/// backend cho app Shopee của bạn), chỉ cần thay `_baseUrl` và cách
/// map dữ liệu trong `Product _mapToProduct(...)`, phần giao diện
/// (ProductDetailScreen, các màn hình danh sách...) không cần sửa gì.
/// ============================================================
class ProductApiService {
  ProductApiService._();

  static const String _baseUrl = 'https://dummyjson.com';

  /// Tỉ giá quy đổi USD -> VNĐ dùng để hiển thị giá tiền Việt Nam.
  static const double usdToVndRate = 25450;

  /// Lấy danh sách sản phẩm từ API (dùng cho các lưới sản phẩm).
  static Future<List<Product>> fetchProducts({int limit = 30, int skip = 0}) async {
    final uri = Uri.parse('$_baseUrl/products?limit=$limit&skip=$skip');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Không thể tải danh sách sản phẩm (mã lỗi ${res.statusCode})');
    }
    final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
    final List products = data['products'] as List? ?? [];
    return products
        .map((e) => _mapToProduct(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy chi tiết 1 sản phẩm theo [id] từ API.
  /// [overrideName]: nếu người dùng đã bấm vào 1 sản phẩm có sẵn tên
  /// tiếng Việt trong danh sách (mock data), ta giữ nguyên tên đó để
  /// đồng bộ giữa danh sách và trang chi tiết, chỉ lấy các thông tin
  /// còn lại (giá, ảnh, đánh giá, tồn kho, mô tả...) từ API.
  ///
  /// [overrideImage], [overridePrice], [overrideOriginalPrice],
  /// [overrideDiscountPercent]: dùng để giữ đúng ảnh/giá mà người dùng đã
  /// thấy ở màn hình danh sách (Home, Mall, Live...) — vì [id] truyền vào
  /// (`seedId`) chỉ là một mã băm từ tên sản phẩm, KHÔNG phải id thật của
  /// sản phẩm đó trên DummyJSON, nên sản phẩm trả về từ API có thể là một
  /// sản phẩm hoàn toàn khác (khác ảnh, khác giá, khác danh mục). Nếu
  /// không truyền các override này, trang chi tiết sẽ hiển thị tên đúng
  /// nhưng ảnh + giá của một sản phẩm ngẫu nhiên khác -> không đồng nhất
  /// với card đã bấm vào.
  static Future<Product> fetchProductById(
    int id, {
    String? overrideName,
    String? overrideImage,
    int? overridePrice,
    int? overrideOriginalPrice,
    int? overrideDiscountPercent,
  }) async {
    final safeId = ((id - 1) % 100).abs() + 1; // DummyJSON có 100 sản phẩm mẫu (id 1-100)
    final uri = Uri.parse('$_baseUrl/products/$safeId');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Không thể tải chi tiết sản phẩm (mã lỗi ${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _mapToProduct(
      json,
      overrideName: overrideName,
      overrideImage: overrideImage,
      overridePrice: overridePrice,
      overrideOriginalPrice: overrideOriginalPrice,
      overrideDiscountPercent: overrideDiscountPercent,
    );
  }

  /// Lấy vài sản phẩm cùng danh mục để hiển thị mục "Có thể bạn cũng thích".
  static Future<List<Product>> fetchSimilarProducts(String category, {int excludeId = -1, int limit = 6}) async {
    if (category.isEmpty) return fetchProducts(limit: limit);
    final uri = Uri.parse('$_baseUrl/products/category/$category?limit=$limit');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      return fetchProducts(limit: limit);
    }
    final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
    final List products = data['products'] as List? ?? [];
    return products
        .where((e) => (e['id'] as int?) != excludeId)
        .map((e) => _mapToProduct(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // Bản địa hoá dữ liệu API -> Product tiếng Việt / giá VNĐ
  // ============================================================

  static Product _mapToProduct(
    Map<String, dynamic> json, {
    String? overrideName,
    String? overrideImage,
    int? overridePrice,
    int? overrideOriginalPrice,
    int? overrideDiscountPercent,
  }) {
    final int id = (json['id'] as num?)?.toInt() ?? Random().nextInt(100) + 1;
    final double usdPrice = (json['price'] as num?)?.toDouble() ?? 9.99;
    final int apiDiscountPercent = ((json['discountPercentage'] as num?) ?? 0).round().clamp(0, 80);
    final double usdOriginal =
        apiDiscountPercent > 0 ? usdPrice / (1 - (apiDiscountPercent / 100)) : usdPrice;

    // Nếu có override (đến từ card đã bấm ở Home/Mall/Live) thì ưu tiên
    // dùng đúng giá đó, để trang chi tiết luôn khớp với những gì người
    // dùng vừa thấy, thay vì hiển thị giá của một sản phẩm khác lấy
    // ngẫu nhiên từ API theo `seedId`.
    final int discountPercent = overrideDiscountPercent ?? apiDiscountPercent;
    final int price =
        (overridePrice != null && overridePrice > 0) ? overridePrice : _roundToThousand(usdPrice * usdToVndRate);
    final int originalPrice = (overrideOriginalPrice != null && overrideOriginalPrice > 0)
        ? overrideOriginalPrice
        : _roundToThousand(usdOriginal * usdToVndRate);

    final double rating = (json['rating'] as num?)?.toDouble() ?? 4.5;
    final int stock = (json['stock'] as num?)?.toInt() ?? 999;

    final String category = (json['category'] as String?) ?? 'khac';
    final String? rawBrand = json['brand'] as String?;
    final String rawTitle = (json['title'] as String?) ?? '';
    final List<String> rawTags = ((json['tags'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    final List<String> apiImages = ((json['images'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    // Nhiều sản phẩm trên DummyJSON (đặc biệt nhóm "groceries") chỉ trả về
    // ĐÚNG 1 ảnh trong `images`, khiến trang chi tiết trông như chỉ có 1
    // tấm hình duy nhất. Tuy nhiên API luôn có thêm `thumbnail` - một ảnh
    // THẬT khác (crop/khung hình khác của cùng sản phẩm) mà trước đây bị
    // bỏ qua nếu `images` đã có sẵn ít nhất 1 ảnh. Giờ ta luôn gộp thêm
    // `thumbnail` vào danh sách ảnh (nếu khác các ảnh đã có), để gallery
    // có tối thiểu 2 ảnh thật cho hầu hết sản phẩm, thay vì tạo ảnh giả.
    final String? apiThumbnail = json['thumbnail']?.toString();
    if (apiThumbnail != null && apiThumbnail.isNotEmpty && !apiImages.contains(apiThumbnail)) {
      apiImages.add(apiThumbnail);
    }

    // Ảnh bìa (thumbnail) PHẢI là ảnh mà người dùng đã thấy ở card lúc
    // bấm vào, nên đưa lên đầu danh sách; các ảnh còn lại từ API vẫn
    // giữ lại để phần "gallery" trong trang chi tiết có thêm ảnh xem.
    final List<String> images = (overrideImage != null && overrideImage.isNotEmpty)
        ? [overrideImage, ...apiImages.where((e) => e != overrideImage)]
        : apiImages;

    final String brand = _resolveBrand(rawBrand, category, id);
    final String name = overrideName ?? _localizedName(category, brand, id, title: rawTitle, tags: rawTags);
    final String categoryLabel = _categoryLabel(category);

    // Số lượt bán + đánh giá + vị trí: API không cung cấp, tạo dữ liệu
    // hợp lý dựa theo id để mỗi sản phẩm có số liệu ổn định, không đổi
    // ngẫu nhiên mỗi lần build lại giao diện.
    final int soldCount = 30 + ((id * 197) % 6000);
    final int ratingCount = (soldCount * 0.6).round() + (id % 50);
    const locations = [
      'TP. Hồ Chí Minh',
      'Hà Nội',
      'Đà Nẵng',
      'Bình Dương',
      'Đồng Nai',
      'Cần Thơ',
    ];
    final String location = locations[id % locations.length];
    final String shopName = _shopNameFor(brand, category, id);

    final String description = _localizedDescription(name, category, brand);

    final List<String> highlights = [
      'Thương hiệu: $brand',
      'Danh mục: $categoryLabel',
      'Tình trạng kho: ${stock > 0 ? "Còn hàng ($stock sản phẩm)" : "Tạm hết hàng"}',
      'Xuất xứ: Chính hãng, có tem nhãn phụ tiếng Việt',
    ];

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
      shopName: shopName,
      location: location,
      images: images,
      highlights: highlights,
    );
  }

  static int _roundToThousand(double value) {
    final rounded = (value / 1000).round() * 1000;
    return rounded < 1000 ? 1000 : rounded;
  }

  static String _resolveBrand(String? rawBrand, String category, int id) {
    if (rawBrand != null && rawBrand.trim().isNotEmpty && rawBrand.toLowerCase() != 'null') {
      return rawBrand.trim();
    }
    final fallback = _genericBrandPool[category] ?? const ['Chính Hãng', 'Cao Cấp', 'Nội Địa'];
    return fallback[id % fallback.length];
  }

  static String _shopNameFor(String brand, String category, int id) {
    final slug = brand
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .trim();
    if (slug.isNotEmpty) return '$slug.official';
    final catSlug = category.replaceAll('-', '');
    return 'shop.$catSlug$id';
  }

  /// Sinh tên tiếng Việt cho sản phẩm.
  ///
  /// TRƯỚC ĐÂY: hàm này chỉ chọn 1 trong 3 mẫu câu cố định của category
  /// theo `id % 3`, HOÀN TOÀN không quan tâm sản phẩm thật là gì (title
  /// từ API). Đó là lý do "Beef Steak" (id=17, 17%3=2) bị rơi trúng mẫu
  /// "Gia vị nấu ăn {brand} chính hãng" – sai hoàn toàn so với thực tế
  /// (thịt bò lại bị gắn tên "gia vị nấu ăn").
  ///
  /// BÂY GIỜ: với nhóm "groceries" (thực phẩm/tạp hoá) - nơi bị báo lỗi -
  /// ta dịch theo đúng `title` thật của sản phẩm (ưu tiên tra từ điển tên
  /// chính xác, nếu không có thì dịch từng từ tiếng Anh trong title, và
  /// chỉ dùng `tags` làm phương án dự phòng cuối cùng). Các category khác
  /// vẫn dùng mẫu câu theo thương hiệu như cũ (vì không bị báo sai lệch
  /// nội dung như groceries).
  static String _localizedName(
    String category,
    String brand,
    int id, {
    String title = '',
    List<String> tags = const [],
  }) {
    if (category == 'groceries') {
      return _localizedGroceryName(title, tags, id);
    }
    final templates = _categoryTemplates[category] ?? ['Sản phẩm $brand chính hãng'];
    final template = templates[id % templates.length];
    return template.replaceAll('{brand}', brand);
  }

  /// Tên chính xác cho các sản phẩm groceries phổ biến trên DummyJSON,
  /// tra theo đúng `title` (tiếng Anh) trả về từ API.
  static const Map<String, String> _groceryExactNames = {
    'apple': 'Táo tươi',
    'beef steak': 'Thịt bò bít tết',
    'cat food': 'Thức ăn cho mèo',
    'chicken meat': 'Thịt gà tươi',
    'cooking oil': 'Dầu ăn',
    'cucumber': 'Dưa leo',
    'dog food': 'Thức ăn cho chó',
    'eggs': 'Trứng gà',
    'fish steak': 'Cá phi lê',
    'green bell pepper': 'Ớt chuông xanh',
    'green chili pepper': 'Ớt cay xanh',
    'honey jar': 'Mật ong nguyên chất',
    'ice cream': 'Kem tươi',
    'juice': 'Nước ép trái cây',
    'kiwi': 'Kiwi tươi',
  };

  /// Dịch từng từ tiếng Anh thường gặp trong tên thực phẩm/tạp hoá.
  /// Dùng khi sản phẩm không nằm trong `_groceryExactNames` ở trên.
  static const Map<String, String> _groceryWordTranslations = {
    'apple': 'táo', 'apples': 'táo', 'banana': 'chuối', 'bananas': 'chuối',
    'orange': 'cam', 'lemon': 'chanh', 'lime': 'chanh', 'grape': 'nho',
    'grapes': 'nho', 'mango': 'xoài', 'watermelon': 'dưa hấu',
    'strawberry': 'dâu tây', 'strawberries': 'dâu tây', 'pineapple': 'dứa',
    'kiwi': 'kiwi', 'peach': 'đào', 'pear': 'lê', 'cherry': 'cherry',
    'beef': 'bò', 'chicken': 'gà', 'pork': 'heo', 'meat': 'thịt',
    'steak': 'bít tết', 'fish': 'cá', 'shrimp': 'tôm', 'seafood': 'hải sản',
    'egg': 'trứng', 'eggs': 'trứng', 'milk': 'sữa', 'cheese': 'phô mai',
    'butter': 'bơ', 'yogurt': 'sữa chua', 'cream': 'kem',
    'cucumber': 'dưa leo', 'tomato': 'cà chua', 'tomatoes': 'cà chua',
    'potato': 'khoai tây', 'potatoes': 'khoai tây', 'onion': 'hành tây',
    'garlic': 'tỏi', 'carrot': 'cà rốt', 'broccoli': 'bông cải xanh',
    'pepper': 'ớt', 'chili': 'ớt cay', 'green': 'xanh', 'red': 'đỏ',
    'bell': 'chuông',
    'rice': 'gạo', 'bread': 'bánh mì', 'flour': 'bột mì', 'sugar': 'đường',
    'salt': 'muối', 'oil': 'dầu ăn', 'cooking': 'nấu ăn', 'honey': 'mật ong',
    'jar': 'hũ', 'sauce': 'nước sốt', 'noodle': 'mì', 'noodles': 'mì',
    'pasta': 'mì Ý', 'cereal': 'ngũ cốc', 'oat': 'yến mạch', 'oats': 'yến mạch',
    'juice': 'nước ép', 'water': 'nước', 'soda': 'nước ngọt',
    'coffee': 'cà phê', 'tea': 'trà', 'chocolate': 'sô cô la',
    'candy': 'kẹo', 'cookie': 'bánh quy', 'cookies': 'bánh quy',
    'cake': 'bánh ngọt', 'ice': 'kem lạnh', 'dog': 'cho chó',
    'cat': 'cho mèo', 'food': 'thức ăn', 'pet': 'thú cưng',
    'wine': 'rượu vang', 'beer': 'bia',
  };

  static const Map<String, String> _groceryTagLabels = {
    'fruits': 'Trái cây',
    'vegetables': 'Rau củ',
    'meat': 'Thịt',
    'seafood': 'Hải sản',
    'dairy': 'Sữa & trứng',
    'beverages': 'Đồ uống',
    'desserts': 'Đồ ngọt & kem',
    'condiments': 'Gia vị & nước chấm',
    'cooking essentials': 'Nguyên liệu nấu ăn',
    'pet supplies': 'Thức ăn thú cưng',
  };

  static String _localizedGroceryName(String title, List<String> tags, int id) {
    final normalizedTitle = title.trim().toLowerCase();
    final exact = _groceryExactNames[normalizedTitle];
    if (exact != null) return exact;

    if (normalizedTitle.isNotEmpty) {
      final words = normalizedTitle.split(RegExp(r'\s+'));
      final translated = <String>[];
      int hitCount = 0;
      for (final w in words) {
        final clean = w.replaceAll(RegExp(r'[^a-z]'), '');
        final vi = _groceryWordTranslations[clean];
        if (vi != null) {
          translated.add(vi);
          hitCount++;
        }
      }
      // Chỉ dùng bản dịch ghép từ nếu dịch được ít nhất 1 từ khoá thực
      // phẩm; nếu không dịch được từ nào (VD tên riêng hiếm gặp), dùng
      // nhãn theo tag để tránh hiển thị tên lộn xộn nửa Anh nửa Việt.
      if (hitCount > 0) {
        final capitalized = translated
            .asMap()
            .entries
            .map((e) => e.key == 0
                ? '${e.value[0].toUpperCase()}${e.value.substring(1)}'
                : e.value)
            .join(' ');
        return capitalized;
      }
    }

    final tagLabel = tags.isNotEmpty ? (_groceryTagLabels[tags.first] ?? 'Thực phẩm') : 'Thực phẩm';
    return title.isNotEmpty ? '$tagLabel $title' : '$tagLabel & Tạp hoá';
  }

  static String _categoryLabel(String category) {
    return _categoryLabels[category] ?? 'Sản phẩm';
  }

  static String _localizedDescription(String name, String category, String brand) {
    final catLabel = _categoryLabel(category);
    return '$name là sản phẩm thuộc ngành hàng $catLabel của thương hiệu $brand, '
        'được nhiều khách hàng lựa chọn nhờ chất lượng tốt, thiết kế hiện đại và '
        'giá thành hợp lý. Sản phẩm chính hãng 100%, đầy đủ tem nhãn phụ tiếng Việt, '
        'đóng gói cẩn thận trước khi giao hàng.\n\n'
        'Cam kết từ người bán: giao đúng mẫu mã như hình ảnh và mô tả, hỗ trợ đổi trả '
        'trong vòng 7 ngày nếu sản phẩm bị lỗi do nhà sản xuất, hoàn tiền 100% nếu hàng '
        'giả hoặc không đúng mô tả (theo chính sách bảo vệ người mua của Shopee).';
  }

  // ------------------------------------------------------------
  // Bảng bản địa hoá theo danh mục (DummyJSON category -> tiếng Việt)
  // ------------------------------------------------------------

  static const Map<String, String> _categoryLabels = {
    'beauty': 'Sắc Đẹp',
    'fragrances': 'Nước Hoa',
    'furniture': 'Nội Thất',
    'groceries': 'Thực Phẩm & Tạp Hoá',
    'home-decoration': 'Trang Trí Nhà Cửa',
    'kitchen-accessories': 'Phụ Kiện Nhà Bếp',
    'laptops': 'Laptop',
    'mens-shirts': 'Thời Trang Nam',
    'mens-shoes': 'Giày Nam',
    'mens-watches': 'Đồng Hồ Nam',
    'mobile-accessories': 'Phụ Kiện Điện Thoại',
    'motorcycle': 'Phụ Kiện Xe Máy',
    'skin-care': 'Chăm Sóc Da',
    'skincare': 'Chăm Sóc Da',
    'smartphones': 'Điện Thoại',
    'sports-accessories': 'Đồ Thể Thao',
    'sunglasses': 'Kính Mát',
    'tablets': 'Máy Tính Bảng',
    'tops': 'Thời Trang Nữ',
    'vehicle': 'Phụ Kiện Ô Tô',
    'womens-bags': 'Túi Xách Nữ',
    'womens-dresses': 'Váy Đầm Nữ',
    'womens-jewellery': 'Trang Sức Nữ',
    'womens-shoes': 'Giày Nữ',
    'womens-watches': 'Đồng Hồ Nữ',
  };

  static const Map<String, List<String>> _categoryTemplates = {
    'beauty': ['Bộ trang điểm {brand} cao cấp', 'Phấn phủ kiềm dầu {brand}', 'Cọ trang điểm {brand} bộ đầy đủ'],
    'fragrances': ['Nước hoa {brand} quyến rũ', 'Nước hoa nam {brand} lưu hương lâu', 'Nước hoa nữ {brand} hương ngọt'],
    'furniture': ['Ghế sofa {brand} phòng khách', 'Bàn làm việc gỗ {brand}', 'Kệ trang trí {brand} đa năng'],
    'groceries': ['Thực phẩm {brand} tươi ngon', 'Đồ ăn vặt {brand} nhập khẩu', 'Gia vị nấu ăn {brand} chính hãng'],
    'home-decoration': ['Đồ trang trí nhà cửa {brand}', 'Đèn trang trí {brand} phong cách Bắc Âu', 'Tranh treo tường {brand} decor'],
    'kitchen-accessories': ['Dụng cụ nhà bếp {brand} tiện lợi', 'Bộ dao kéo nhà bếp {brand}', 'Hộp đựng thực phẩm {brand}'],
    'laptops': ['Laptop {brand} hiệu năng cao', 'Laptop {brand} mỏng nhẹ văn phòng', 'Laptop {brand} gaming'],
    'mens-shirts': ['Áo sơ mi nam {brand} công sở', 'Áo thun nam {brand} phong cách', 'Áo polo nam {brand} basic'],
    'mens-shoes': ['Giày nam {brand} thời trang', 'Giày thể thao nam {brand}', 'Giày da nam {brand} lịch lãm'],
    'mens-watches': ['Đồng hồ nam {brand} sang trọng', 'Đồng hồ nam {brand} dây da', 'Đồng hồ nam {brand} chống nước'],
    'mobile-accessories': ['Phụ kiện điện thoại {brand}', 'Ốp lưng điện thoại {brand} chống sốc', 'Sạc nhanh {brand} chính hãng'],
    'motorcycle': ['Phụ kiện xe máy {brand}', 'Mũ bảo hiểm {brand} chính hãng', 'Gương chiếu hậu {brand}'],
    'skin-care': ['Sữa rửa mặt {brand} sạch sâu', 'Serum dưỡng da {brand} phục hồi', 'Kem dưỡng ẩm {brand} chuyên sâu'],
    'skincare': ['Sữa rửa mặt {brand} sạch sâu', 'Serum dưỡng da {brand} phục hồi', 'Kem dưỡng ẩm {brand} chuyên sâu'],
    'smartphones': ['Điện thoại {brand} chính hãng', 'Smartphone {brand} camera sắc nét', 'Điện thoại {brand} pin trâu'],
    'sports-accessories': ['Dụng cụ thể thao {brand}', 'Phụ kiện tập gym {brand}', 'Bóng thể thao {brand} chính hãng'],
    'sunglasses': ['Kính mát {brand} chống UV', 'Kính râm thời trang {brand}', 'Kính mát {brand} phong cách Hàn Quốc'],
    'tablets': ['Máy tính bảng {brand}', 'Tablet {brand} màn hình lớn', 'Máy tính bảng {brand} học tập & giải trí'],
    'tops': ['Áo kiểu nữ {brand} thanh lịch', 'Áo croptop {brand} năng động', 'Áo blouse nữ {brand} công sở'],
    'vehicle': ['Phụ kiện ô tô {brand}', 'Đồ chơi mô hình xe {brand}', 'Nước hoa ô tô {brand} thơm lâu'],
    'womens-bags': ['Túi xách {brand} thời trang', 'Túi đeo chéo nữ {brand}', 'Ví cầm tay nữ {brand} sang trọng'],
    'womens-dresses': ['Váy đầm {brand} dự tiệc', 'Đầm nữ {brand} thanh lịch', 'Váy hoa {brand} phong cách vintage'],
    'womens-jewellery': ['Trang sức {brand} sang trọng', 'Vòng tay {brand} đính đá', 'Dây chuyền {brand} mạ vàng'],
    'womens-shoes': ['Giày nữ {brand} êm chân', 'Sandal nữ {brand} thời trang hè', 'Giày cao gót {brand} thanh lịch'],
    'womens-watches': ['Đồng hồ nữ {brand} thanh lịch', 'Đồng hồ nữ {brand} mặt đá', 'Đồng hồ nữ {brand} dây kim loại'],
  };

  static const Map<String, List<String>> _genericBrandPool = {
    'beauty': ['Hàn Quốc', 'Nhật Bản', 'Thái Lan'],
    'fragrances': ['Pháp', 'Ý', 'Hàn Quốc'],
    'skin-care': ['Hàn Quốc', 'Nhật Bản', 'Cocoon'],
    'skincare': ['Hàn Quốc', 'Nhật Bản', 'Cocoon'],
    'groceries': ['Việt Nam', 'Nhập Khẩu', 'Nội Địa'],
    'home-decoration': ['Bắc Âu', 'Nhật Bản', 'Nội Địa'],
    'furniture': ['Nội Địa', 'Nhập Khẩu', 'Cao Cấp'],
  };
}