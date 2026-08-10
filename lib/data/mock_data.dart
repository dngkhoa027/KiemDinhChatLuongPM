import 'package:flutter/material.dart';
import '../models/cart_models.dart';
import '../models/voucher_model.dart';

/// ============================================================
/// MOCK DATA – nơi tập trung TOÀN BỘ dữ liệu mẫu của ứng dụng.
///
/// Mục đích: tách phần "chữ/dữ liệu cứng" (title, subtitle, giá,
/// thời gian, số badge, hình ảnh...) ra khỏi các file giao diện
/// (screens). Sau này khi làm API / Firebase / CMS thật, bạn chỉ
/// cần sửa NỘI DUNG bên trong file này (hoặc đổi các getter/hàm
/// bên dưới thành các hàm gọi API bất đồng bộ), mà KHÔNG cần đụng
/// vào bất kỳ file giao diện nào trong thư mục screens/.
///
/// Ví dụ sau này khi có API thật:
///   static Future<List<Map<String, dynamic>>> fetchMallProducts() async {
///     final res = await http.get(Uri.parse('https://api.you.com/products'));
///     return jsonDecode(res.body);
///   }
/// rồi trong màn hình gọi `await MockData.fetchMallProducts()` thay vì
/// `MockData.mallProducts`.
/// ============================================================
class MockData {
  MockData._();

  // ============================================================
  // VOUCHER / MÃ GIẢM GIÁ (checkout_screen.dart, voucher_selection_screen.dart)
  // ============================================================

  /// Voucher do Shop phát hành (áp dụng riêng cho đơn hàng của shop đó).
  static List<Voucher> shopVouchers(String shopName) => [
        Voucher(
          id: 'shop_1',
          code: 'SHOPFREESHIP',
          title: 'Miễn phí vận chuyển',
          source: VoucherSource.shop,
          kind: VoucherKind.freeship,
          discountType: VoucherDiscountType.fixed,
          discountValue: 20000,
          minSpend: 0,
          quantity: 200,
          used: 140,
          expiry: 'HSD: 31.08.2026',
          shopName: shopName,
        ),
        Voucher(
          id: 'shop_2',
          code: 'SHOPGIAM10',
          title: 'Giảm 10%',
          source: VoucherSource.shop,
          discountType: VoucherDiscountType.percent,
          discountValue: 10,
          maxDiscount: 50000,
          minSpend: 100000,
          quantity: 100,
          used: 62,
          expiry: 'HSD: 20.08.2026',
          shopName: shopName,
        ),
        Voucher(
          id: 'shop_3',
          code: 'SHOP110K',
          title: 'Giảm 110.000đ',
          source: VoucherSource.shop,
          discountType: VoucherDiscountType.fixed,
          discountValue: 110150,
          minSpend: 500000,
          quantity: 50,
          used: 47,
          expiry: 'HSD: 15.08.2026',
          shopName: shopName,
        ),
      ];

  /// Voucher toàn sàn do Shopee phát hành.
  static const List<Voucher> platformVouchers = [
    Voucher(
      id: 'plat_1',
      code: 'SFREESHIPXTRA',
      title: 'Miễn phí vận chuyển',
      source: VoucherSource.platform,
      kind: VoucherKind.freeship,
      discountType: VoucherDiscountType.fixed,
      discountValue: 20100,
      minSpend: 0,
      quantity: 5000,
      used: 4210,
      expiry: 'HSD: 31.08.2026',
    ),
    Voucher(
      id: 'plat_2',
      code: 'SALE8SUM',
      title: 'Giảm 8%',
      source: VoucherSource.platform,
      discountType: VoucherDiscountType.percent,
      discountValue: 8,
      maxDiscount: 100000,
      minSpend: 200000,
      quantity: 3000,
      used: 2870,
      expiry: 'HSD: 10.08.2026',
    ),
    Voucher(
      id: 'plat_3',
      code: 'GIAM50K',
      title: 'Giảm 50.000đ',
      source: VoucherSource.platform,
      discountType: VoucherDiscountType.fixed,
      discountValue: 50000,
      minSpend: 300000,
      quantity: 1000,
      used: 990,
      expiry: 'HSD: 08.08.2026',
    ),
  ];

  // ============================================================
  // ============================================================
  // TRANG CHI TIẾT SẢN PHẨM (product_detail_screen.dart)
  // ============================================================

  /// Ảnh minh hoạ do NGƯỜI MUA đăng kèm đánh giá (review) — cố tình dùng
  /// ảnh ngoài (không phải ảnh sản phẩm lấy từ API) để trông giống ảnh
  /// khách thật chụp, thay vì lặp lại đúng ảnh sản phẩm trên sàn.
  /// Ảnh minh hoạ do NGƯỜI MUA đăng kèm đánh giá (review) — dùng ảnh ngoài
  /// (không phải ảnh sản phẩm từ API) để trông giống ảnh khách thật chụp.
  /// Được nhóm theo LOẠI sản phẩm để ảnh review luôn khớp với mặt hàng
  /// đang xem (review áo thì ra ảnh áo/quần, review điện thoại thì ra ảnh
  /// điện thoại... không còn bị lẫn lộn danh mục).
  static const Map<String, List<String>> reviewPhotosByCategory = {
    'apparel': [
      "https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400&q=80", // áo treo trên móc
      "https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=400&q=80", // outfit thử đồ
      "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=400&q=80", // quần áo gấp gọn
      "https://images.unsplash.com/photo-1562157873-818bc0726f68?w=400&q=80", // sản phẩm đóng gói
    ],
    'shoes': [
      "https://images.unsplash.com/photo-1445205170230-053b83016050?w=400&q=80", // giày dép
      "https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=400&q=80", // giày sneaker
      "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400&q=80", // giày cận cảnh
    ],
    'accessories': [
      "https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=400&q=80", // đồng hồ / phụ kiện
      "https://images.unsplash.com/photo-1523293182086-7651a899d37f?w=400&q=80", // trang sức
      "https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400&q=80", // kính mát
      "https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400&q=80", // túi xách
    ],
    'electronics': [
      "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&q=80", // điện thoại
      "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400&q=80", // laptop
      "https://images.unsplash.com/photo-1585790050230-5dd28404ccb9?w=400&q=80", // tai nghe / phụ kiện
      "https://images.unsplash.com/photo-1585060544812-6b45742d762f?w=400&q=80", // hộp máy mở ra
    ],
    'beauty': [
      "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80", // mỹ phẩm
      "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&q=80", // dưỡng da
      "https://images.unsplash.com/photo-1571875257727-256c39da42af?w=400&q=80", // nước hoa
    ],
    'home': [
      "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400&q=80", // nội thất
      "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80", // đồ trang trí
      "https://images.unsplash.com/photo-1556911220-bff31c812dce?w=400&q=80", // dụng cụ nhà bếp
    ],
    'food': [
      "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=400&q=80", // thực phẩm
      "https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&q=80", // đồ ăn vặt
    ],
    'vehicle': [
      "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=400&q=80", // phụ kiện xe
      "https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=400&q=80", // mũ bảo hiểm / xe máy
    ],
    'sports': [
      "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&q=80", // dụng cụ thể thao
      "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&q=80", // đồ tập gym
    ],
    'other': [
      "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&q=80",
      "https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=400&q=80",
    ],
  };

  /// Ảnh bìa (thumbnail) cho mục "Video về sản phẩm" — cũng dùng ảnh ngoài
  /// để giả lập khung hình đầu video thật, không lấy trùng ảnh sản phẩm.
  static const List<String> productVideoThumbs = [
    "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&q=80", // fashion store
    "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&q=80", // review / unbox
    "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&q=80", // model mặc thử
  ];

  // ============================================================
  // TRANG CHỦ (home_screen.dart)
  // ============================================================

  /// Banner carousel trang chủ
  static const List<String> homeBanners = [
    "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1200&q=80", // shopping bags sale
    "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80", // fashion store
    "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1200&q=80", // checkout / deal
  ];

  /// Danh mục trang chủ
  static const List<Map<String, dynamic>> homeCategories = [
    {"icon": Icons.checkroom, "label": "Thời Trang Nữ"},
    {"icon": Icons.checkroom_outlined, "label": "Thời Trang Nam"},
    {"icon": Icons.devices_other, "label": "Thiết Bị Điện Tử"},
    {"icon": Icons.phone_iphone, "label": "Điện Thoại & Tablet"},
    {"icon": Icons.chair_alt, "label": "Nhà Cửa Đời Sống"},
    {"icon": Icons.face_retouching_natural, "label": "Sắc Đẹp"},
    {"icon": Icons.child_friendly, "label": "Mẹ & Bé"},
    {"icon": Icons.sports_soccer, "label": "Thể Thao"},
    {"icon": Icons.local_offer, "label": "Voucher Shopee"},
    {"icon": Icons.grid_view, "label": "Xem Thêm"},
  ];

  /// Sản phẩm Flash Sale trang chủ
  static const List<Map<String, dynamic>> homeFlashSaleItems = [
    {"image": "https://picsum.photos/id/103/300/300", "price": "39.000", "sold": 0.86, "discount": 45},
    {"image": "https://picsum.photos/id/201/300/300", "price": "129.000", "sold": 0.62, "discount": 30},
    {"image": "https://picsum.photos/id/312/300/300", "price": "79.000", "sold": 0.95, "discount": 50},
    {"image": "https://picsum.photos/id/145/300/300", "price": "259.000", "sold": 0.4, "discount": 20},
    {"image": "https://picsum.photos/id/342/300/300", "price": "99.000", "sold": 0.78, "discount": 35},
  ];

  /// Lưới sản phẩm "Gợi ý hôm nay" / feed trang chủ.
  /// Các field "tag", "badge", "shipTime" là tùy chọn — chỉ 1 vài sản phẩm nổi bật
  /// có để hiển thị nhãn "Yêu thích", "Rẻ Vô Địch", thời gian giao hàng...
  static const List<Map<String, dynamic>> homeProducts = [
    {
      "image": "https://picsum.photos/id/26/300/300",
      "title": "Bút Deli màu học sinh 12 màu cao cấp",
      "price": "15.000",
      "originalPrice": "25.000",
      "discount": 40,
      "sold": "2,3k",
      "rating": 4.9,
      "location": "TP. Hồ Chí Minh",
    },
    {
      "image": "https://picsum.photos/id/1080/300/300",
      "title": "Túi vệ sinh máy lạnh treo tường - Áo bọc hứng nước điều hòa",
      "price": "71.000",
      "originalPrice": "89.000",
      "discount": 20,
      "sold": "3k+",
      "rating": 4.9,
      "location": "Tỉnh Đồng Nai",
      "tag": "Yêu thích",
      "badge": "Rẻ Vô Địch",
      "shipTime": "< 2 Ngày",
    },
    {
      "image": "https://picsum.photos/id/60/300/300",
      "title": "Áo thun nam nữ form rộng phong cách Hàn Quốc",
      "price": "89.000",
      "originalPrice": "159.000",
      "discount": 44,
      "sold": "5,1k",
      "rating": 4.8,
      "location": "Hà Nội",
    },
    {
      "image": "https://picsum.photos/id/96/300/300",
      "title": "Tai nghe Bluetooth không dây chống nước thể thao",
      "price": "199.000",
      "originalPrice": "399.000",
      "discount": 50,
      "sold": "10k",
      "rating": 4.7,
      "location": "TP. Hồ Chí Minh",
    },
    {
      "image": "https://picsum.photos/id/21/300/300",
      "title": "Giày sneaker nữ đế cao êm chân đi học đi làm",
      "price": "219.000",
      "originalPrice": "350.000",
      "discount": 38,
      "sold": "876",
      "rating": 4.9,
      "location": "Đà Nẵng",
    },
    {
      "image": "https://picsum.photos/id/48/300/300",
      "title": "Balo laptop chống nước chống trộm đa năng",
      "price": "175.000",
      "originalPrice": "280.000",
      "discount": 37,
      "sold": "1,2k",
      "rating": 4.8,
      "location": "TP. Hồ Chí Minh",
    },
    {
      "image": "https://picsum.photos/id/119/300/300",
      "title": "Kem chống nắng nâng tone SPF50+ dưỡng da",
      "price": "129.000",
      "originalPrice": "189.000",
      "discount": 32,
      "sold": "3,4k",
      "rating": 5.0,
      "location": "Hà Nội",
    },
    {
      "image": "https://picsum.photos/id/1071/300/300",
      "title": "Súng bắn ốc vít pin cầm tay đa năng chính hãng",
      "price": "259.000",
      "originalPrice": "355.000",
      "discount": 27,
      "sold": "642",
      "rating": 4.8,
      "location": "Bình Dương",
    },
    {
      "image": "https://picsum.photos/id/1005/300/300",
      "title": "Robot hút bụi lau nhà thông minh tự động sạc",
      "price": "2.590.000",
      "originalPrice": "3.290.000",
      "discount": 21,
      "sold": "215",
      "rating": 4.9,
      "location": "TP. Hồ Chí Minh",
    },
  ];

  /// Banner quảng cáo dạng thẻ lớn chèn trong feed 2 cột trang chủ
  static const Map<String, dynamic> homeFeedBanner = {
    "tag1": "7.7",
    "tag2": "CÒN 3 NGÀY",
    "badge": "FREESHIP 0Đ",
    "title": "Shopee Gifts",
    "subtitle": "Quà tặng chuẩn gu",
    "discountLabel": "GIẢM ĐẾN",
    "discountValue": "200.000",
    "discountUnit": "ĐỒNG",
    "note": "Áp dụng cho đơn hàng đầu tiên",
  };

  /// Hàng icon truy cập nhanh cuộn ngang trên trang chủ (có chấm phân trang)
  static const List<Map<String, dynamic>> homeQuickAccessIcons = [
    {"icon": Icons.restaurant, "color": Color(0xFFEE4D2D), "label": "ShopeeFood\nFlash Sale 50%"},
    {"icon": Icons.workspace_premium, "color": Color(0xFFEE4D2D), "label": "ShopeeVIP"},
    {"icon": Icons.sell, "color": Color(0xFFEE4D2D), "label": "Deal Từ 1.000Đ"},
    {"icon": Icons.shopping_bag, "color": Color(0xFFEE4D2D), "label": "Shopee Xử Lý"},
    {"icon": Icons.replay_circle_filled, "color": Color(0xFFEE4D2D), "label": "Shopee Hoàn\nTiền Xtra"},
    {"icon": Icons.local_shipping, "color": Color(0xFFEE4D2D), "label": "Freeship\nXtra"},
    {"icon": Icons.confirmation_number, "color": Color(0xFFEE4D2D), "label": "Voucher\nXtra"},
  ];

  /// Shopee Video – 2 video ngắn hiển thị song song với Shopee Live
  static const List<Map<String, dynamic>> homeVideos = [
    {"thumb": "https://picsum.photos/id/1005/300/400", "views": "16,6k"},
    {"thumb": "https://picsum.photos/id/1043/300/400", "views": "4,6k"},
  ];

  // ============================================================
  // MALL (mall_screen.dart)
  // ============================================================

  /// Banner chính (7.7) của Mall
static const List<Map<String, dynamic>> mallMainBanners = [
    {
      "tag": "OPPO",
      "title1": "CÔNG NGHỆ ĐỈNH CAO",
      "title2": "GIÁ SỐC NGÀY VÀNG",
      "date": "DUY NHẤT: 04/07 – 07/07",
      "voucher": "200.000",
      "discount": "30%",
      "gift": "300.000",
      // Điện thoại / gadget – nền sạch, sản phẩm nổi
      "image": "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=900&q=80",
    },
    {
      "tag": "8.8",
      "title1": "SIÊU SALE THÁNG 8",
      "title2": "FREESHIP 0Đ TOÀN SÀN",
      "date": "DIỄN RA: 01/08 – 08/08",
      "voucher": "500.000",
      "discount": "50%",
      "gift": "200.000",
      // Lifestyle shopping
      "image": "https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=900&q=80",
    },
    {
      "tag": "L'Oréal",
      "title1": "RỰC RỠ SẮC XINH",
      "title2": "ƯU ĐÃI NGẬP TRÀN",
      "date": "DUY NHẤT: 04/07 – 07/07",
      "voucher": "150.000",
      "discount": "50%",
      "gift": "200.000",
      // Beauty / cosmetics
      "image": "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=900&q=80",
    },
    {
      "tag": "SAMSUNG",
      "title1": "GALAXY SERIES MỚI",
      "title2": "ƯU ĐÃI ĐẾN 2 TRIỆU",
      "date": "ĐẶT TRƯỚC NGAY",
      "voucher": "400.000",
      "discount": "15%",
      "gift": "500.000",
      // Smartwatch / tech lifestyle
      "image": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900&q=80",
    },
    {
      "tag": "LAZYCHEF",
      "title1": "BẾP THÀNH THƠI",
      "title2": "VỊ HẠNH PHÚC",
      "date": "DUY NHẤT: 04/07 – 07/07",
      "voucher": "300.000",
      "discount": "45%",
      "gift": "500.000",
      // Kitchen / home
      "image": "https://images.unsplash.com/photo-1556911220-bff31c812dce?w=900&q=80",
    },
  ];

  /// Hàng icon tiện ích của Mall
  static const List<Map<String, dynamic>> mallQuickIcons = [
    {"icon": Icons.diamond, "color": Color(0xFFFFC107), "label": "SHOPEE\nPREMIUM"},
    {"icon": Icons.shopping_bag, "color": Color(0xFFEE4D2D), "label": "SĂN DEAL SIÊU\nHOT"},
    {"icon": Icons.emoji_events, "color": Color(0xFFFF7A00), "label": "THƯƠNG HIỆU\nMỚI LÊN SÀN"},
    {"icon": Icons.public, "color": Color(0xFFEE2E24), "label": "THƯƠNG HIỆU\nQUỐC TẾ"},
    {"icon": Icons.bolt, "color": Color(0xFF222222), "label": "FLASH SALE"},
  ];

  /// Danh mục Mall
  static const List<Map<String, dynamic>> mallCategories = [
    {"image": "https://picsum.photos/id/1074/200/200", "label": "Thể Thao & Du Lịch"},
    {"image": "https://picsum.photos/id/1071/200/200", "label": "Ô Tô & Xe Máy & Xe Đạp"},
    {"image": "https://picsum.photos/id/1080/200/200", "label": "Bách Hóa Online"},
    {"image": "https://picsum.photos/id/312/200/200", "label": "Nhà Cửa & Đời Sống"},
    {"image": "https://picsum.photos/id/26/200/200", "label": "Sắc Đẹp"},
    {"image": "https://picsum.photos/id/48/200/200", "label": "Mẹ & Bé"},
  ];

  /// Dãy sản phẩm "7.7 Voucher Xtra" của Mall
  static const List<Map<String, dynamic>> mallFlashRow = [
    {
      "image": "https://picsum.photos/id/24/300/300",
      "title": "Combo 5/10/20 Bút gel Minimalist Thiên Long",
      "discount": 37,
    },
    {
      "image": "https://picsum.photos/id/367/300/300",
      "title": "Tai nghe bluetooth Soundcore R50i NC | Chính hãng",
      "discount": 44,
    },
    {
      "image": "https://picsum.photos/id/103/300/300",
      "title": "Máy Xay Đa Năng Cầm Tay Bear Chính Hãng",
      "discount": 40,
    },
  ];

  /// Khối "Mua để nhận quà" của Mall
  static const List<Map<String, dynamic>> mallGiftProducts = [
    {
      "image": "https://picsum.photos/id/1025/300/300",
      "title": "Sách - Bộ 6 cuốn THƯ VIỆN HÌNH ẢNH song ngữ Anh Việt",
      "discount": 41,
      "price": "35.000",
      "hasGift": true,
    },
    {
      "image": "https://picsum.photos/id/1060/300/300",
      "title": "Khăn Tắm, Khăn Gội Đầu, Khăn Lau Mặt Cotton",
      "discount": 80,
      "price": "6.900",
      "hasGift": true,
    },
    {
      "image": "https://picsum.photos/id/1076/300/300",
      "title": "Mũ Bảo Hiểm Dáng Nửa Đầu TRAI NAM/NỮ",
      "discount": 0,
      "price": "122.760",
      "hasGift": false,
    },
  ];

  /// Voucher thương hiệu – "ƯU ĐÃI SHOPEE MALL"
  static const List<Map<String, dynamic>> mallBrandVouchers = [
    {
      "logo": "https://picsum.photos/id/201/120/120",
      "name": "LIXIBOX\nOFFICIAL STORE",
      "percent": "giảm 20%",
      "condition": "Giảm tối đa 350k đ\nĐơn tối thiểu 1,2tr đ",
    },
    {
      "logo": "https://picsum.photos/id/64/120/120",
      "name": "Abib Official\nStore",
      "percent": "giảm 10%",
      "condition": "Giảm tối đa 15k đ Đơn\ntối thiểu 150k đ",
    },
    {
      "logo": "https://picsum.photos/id/96/120/120",
      "name": "OPPO Official\nStore",
      "percent": "giảm 5%",
      "condition": "Giảm tối đa 50k đ Đơn\ntối thiểu 500k đ",
    },
    {
      "logo": "https://picsum.photos/id/292/120/120",
      "name": "LazyChef\nVietNam",
      "percent": "giảm 7%",
      "condition": "Giảm tối đa 30k đ Đơn\ntối thiểu 400k đ",
    },
    {
      "logo": "https://picsum.photos/id/312/120/120",
      "name": "Vinamilk\nOfficial Store",
      "percent": "giảm 3%",
      "condition": "Giảm tối đa 20k đ Đơn\ntối thiểu 200k đ",
    },
    {
      "logo": "https://picsum.photos/id/342/120/120",
      "name": "Samsung\nOfficial Store",
      "percent": "giảm 8%",
      "condition": "Giảm tối đa 400k đ Đơn\ntối thiểu 3tr đ",
    },
  ];

  /// Lưới sản phẩm chính của Mall (sau phần ưu đãi)
  static const List<Map<String, dynamic>> mallProducts = [
    {
      "image": "https://picsum.photos/id/250/300/300",
      "title": "[Chính Hãng] Sữa rửa mặt CeraVe làm sạch da dầu mụn",
      "price": "215.000",
      "originalPrice": "320.000",
      "discount": 33,
      "sold": "8,2k",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/160/300/300",
      "title": "Tai nghe Sony WH-CH520 chính hãng bảo hành 12 tháng",
      "price": "890.000",
      "originalPrice": "1.290.000",
      "discount": 31,
      "sold": "1,5k",
      "rating": 5.0,
    },
    {
      "image": "https://picsum.photos/id/338/300/300",
      "title": "Áo khoác Uniqlo phối mũ chống nắng chính hãng",
      "price": "459.000",
      "originalPrice": "690.000",
      "discount": 33,
      "sold": "3,1k",
      "rating": 4.8,
    },
    {
      "image": "https://picsum.photos/id/431/300/300",
      "title": "Nồi chiên không dầu Philips 4.1L chính hãng",
      "price": "1.590.000",
      "originalPrice": "2.190.000",
      "discount": 27,
      "sold": "620",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/435/300/300",
      "title": "Sữa bột Nan Optipro số 3 hộp 1.5kg",
      "price": "545.000",
      "originalPrice": "620.000",
      "discount": 12,
      "sold": "990",
      "rating": 5.0,
    },
    {
      "image": "https://picsum.photos/id/119/300/300",
      "title": "Kem chống nắng Anessa chính hãng Nhật Bản SPF50+",
      "price": "455.000",
      "originalPrice": "550.000",
      "discount": 17,
      "sold": "2,4k",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/145/300/300",
      "title": "Bàn phím cơ Logitech G Pro X chính hãng",
      "price": "1.990.000",
      "originalPrice": "2.590.000",
      "discount": 23,
      "sold": "540",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/96/300/300",
      "title": "Nước hoa hồng Hada Labo dưỡng ẩm chuyên sâu 170ml",
      "price": "175.000",
      "originalPrice": "230.000",
      "discount": 24,
      "sold": "6,7k",
      "rating": 4.8,
    },
    {
      "image": "https://picsum.photos/id/312/300/300",
      "title": "Máy lọc không khí Xiaomi Smart Air Purifier 4",
      "price": "2.390.000",
      "originalPrice": "2.990.000",
      "discount": 20,
      "sold": "310",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/342/300/300",
      "title": "Điện thoại Samsung Galaxy A16 chính hãng",
      "price": "3.990.000",
      "originalPrice": "4.590.000",
      "discount": 13,
      "sold": "1,2k",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/24/300/300",
      "title": "Combo 5 bút gel Thiên Long Minimalist mực xanh/đen",
      "price": "45.000",
      "originalPrice": "72.000",
      "discount": 37,
      "sold": "4,3k",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/367/300/300",
      "title": "Tai nghe Bluetooth Soundcore R50i NC chống ồn",
      "price": "579.000",
      "originalPrice": "1.034.000",
      "discount": 44,
      "sold": "980",
      "rating": 4.8,
    },
    {
      "image": "https://picsum.photos/id/1025/300/300",
      "title": "Bộ 6 cuốn sách song ngữ Anh Việt cho bé 0-3 tuổi",
      "price": "35.000",
      "originalPrice": "59.000",
      "discount": 41,
      "sold": "2,1k",
      "rating": 5.0,
    },
    {
      "image": "https://picsum.photos/id/1060/300/300",
      "title": "Bộ khăn tắm khăn gội cotton cao cấp Lotus Towel",
      "price": "129.000",
      "originalPrice": "645.000",
      "discount": 80,
      "sold": "3,7k",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/1076/300/300",
      "title": "Mũ bảo hiểm dáng nửa đầu thời trang nam nữ",
      "price": "122.760",
      "originalPrice": "189.000",
      "discount": 35,
      "sold": "756",
      "rating": 4.7,
    },
    {
      "image": "https://picsum.photos/id/431/300/300",
      "title": "Máy ép chậm đa năng Lazychef công suất lớn",
      "price": "890.000",
      "originalPrice": "1.590.000",
      "discount": 44,
      "sold": "412",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/106/300/300",
      "title": "Son kem lì Merzy chính hãng Hàn Quốc nhiều màu",
      "price": "189.000",
      "originalPrice": "259.000",
      "discount": 27,
      "sold": "5,9k",
      "rating": 4.9,
    },
    {
      "image": "https://picsum.photos/id/1078/300/300",
      "title": "Giày thể thao nam nữ Skechers chính hãng êm ái",
      "price": "990.000",
      "originalPrice": "1.590.000",
      "discount": 38,
      "sold": "830",
      "rating": 4.8,
    },
  ];

  // ============================================================
  // THÔNG BÁO (notification_screen.dart)
  // ============================================================

  /// 5 tab icon trên đầu trang Thông báo
  static const List<Map<String, dynamic>> notificationTabs = [
    {"icon": Icons.thumb_up_alt_rounded, "label": "Thông báo nổi\nbật", "badgeCount": 10},
    {"icon": Icons.local_offer_outlined, "label": "Khuyến mãi", "badgeDot": true},
    {"icon": Icons.live_tv_outlined, "label": "Live, Video &\nThưởng", "badgeDot": true},
    {"icon": Icons.account_balance_wallet_outlined, "label": "Thông tin Tài\nchính", "badgeDot": true},
    {"icon": Icons.shopping_bag_outlined, "label": "Cập nhật\nShopee", "badgeDot": true},
  ];

  /// Tab "Thông báo nổi bật" (có banner mã Freeship)
  static const List<Map<String, dynamic>> notificationHighlight = [
    {
      "icon": Icons.local_shipping,
      "iconBg": Color(0xFF17A398),
      "title": "Mã freeship cho đơn từ 0Đ có sẵn trong ví 😍",
      "subtitle":
          "⏰ Mã sẽ hết hạn vào 08-07-2026! Áp dụng cho đơn từ 0Đ🤑\n🛒 Voucher freeship có sẵn trong ví, dùng ngay kẻo lỡ!",
      "hasBanner": true,
      "secondaryLabel": "Dành cho bạn",
      "time": "13:24 02-07-2026",
    },
    {
      "icon": Icons.local_shipping,
      "iconBg": Color(0xFF17A398),
      "title": "⏰ Mau mau sử dụng mã freeship đơn từ 0Đ",
      "subtitle":
          "🛒 Nhanh tay kẻo lỡ mã freeship cho đơn từ 0Đ\n⏰ Mã sẽ hết hạn vào 30-06-2026! Số lượng có hạn.",
      "hasBanner": true,
      "secondaryLabel": "Sắp hết hạn",
      "time": "13:45 29-06-2026",
    },
    {
      "icon": Icons.campaign,
      "iconBg": Color(0xFFEE4D2D),
      "title": "📣 Bạn yêu ơi!",
      "subtitle": "Shopee đang có chương trình ưu đãi cực lớn dành riêng cho bạn, đừng bỏ lỡ nhé!",
      "hasBanner": false,
      "time": "2 ngày trước",
    },
  ];

  /// Tab "Khuyến mãi"
  static const List<Map<String, dynamic>> notificationPromo = [
    {
      "icon": Icons.card_giftcard,
      "iconBg": Colors.pinkAccent,
      "title": "Nhận ngay Voucher 50K cho đơn đầu tiên",
      "subtitle": "Áp dụng cho đơn hàng từ 0đ, nhập mã tại trang Voucher của tôi.",
      "hasBanner": false,
      "time": "6 giờ trước",
    },
    {
      "icon": Icons.local_fire_department,
      "iconBg": Color(0xFFEE4D2D),
      "title": "Flash Sale bắt đầu sau 2 giờ nữa!",
      "subtitle": "Hàng ngàn sản phẩm giảm đến 50%. Đặt lời nhắc để không bỏ lỡ deal hot.",
      "hasBanner": false,
      "time": "10 phút trước",
    },
  ];

  /// Tab "Live, Video & Thưởng"
  static const List<Map<String, dynamic>> notificationLive = [
    {
      "icon": Icons.videocam,
      "iconBg": Color(0xFF9B51E0),
      "title": "Phiên Live sắp bắt đầu!",
      "subtitle": "Shop yêu thích của bạn sẽ Live sau 15 phút nữa, vào xem để nhận Xu ngay.",
      "hasBanner": false,
      "time": "15 phút trước",
    },
  ];

  /// Tab "Thông tin Tài chính"
  static const List<Map<String, dynamic>> notificationFinance = [
    {
      "icon": Icons.account_balance_wallet,
      "iconBg": Color(0xFF2E9E5B),
      "title": "Hoàn tiền vào ví ShopeePay",
      "subtitle": "Bạn vừa được hoàn 15.000đ vào ví ShopeePay từ đơn hàng đã huỷ.",
      "hasBanner": false,
      "time": "1 ngày trước",
    },
  ];

  /// Tab "Cập nhật Shopee"
  static const List<Map<String, dynamic>> notificationSystem = [
    {
      "icon": Icons.privacy_tip_outlined,
      "iconBg": Colors.grey,
      "title": "Cập nhật Chính Sách Bảo Mật",
      "subtitle": "Shopee đã cập nhật chính sách bảo mật, vui lòng xem chi tiết để biết thêm thông tin.",
      "hasBanner": false,
      "time": "3 ngày trước",
    },
  ];

  // ============================================================
  // LIVE (live_screen.dart)
  // ============================================================

  static const List<String> liveFilters = ["Dành Cho Bạn", "Thời Trang", "Làm Đẹp", "Điện Tử", "Ẩm Thực"];

  static const List<Map<String, dynamic>> liveStreams = [
    {
      "thumb": "https://picsum.photos/id/292/400/560",
      "shop": "nha.gia.dung.vn",
      "title": "SALE SỐC 50% Đồ Gia Dụng Nhà Bếp",
      "viewers": "12,4k",
      "price": "329.000",
      "video": "assets/videos/live_1.mp4",
      "products": [
        {
          "thumb": "https://picsum.photos/id/292/300/300",
          "name": "Nồi Chiên Không Dầu 5L Đa Năng",
          "price": "699.000",
          "originalPrice": "1.290.000",
          "discount": "-46%",
          "sold": "2,3k đã bán",
          "rating": "4.9",
        },
        {
          "thumb": "https://picsum.photos/id/312/300/300",
          "name": "Máy Xay Sinh Tố Đa Năng 2L",
          "price": "329.000",
          "originalPrice": "590.000",
          "discount": "-44%",
          "sold": "1,1k đã bán",
          "rating": "4.8",
        },
        {
          "thumb": "https://picsum.photos/id/365/300/300",
          "name": "Nồi Cơm Điện Tử Cao Tần 1.8L",
          "price": "489.000",
          "originalPrice": "850.000",
          "discount": "-42%",
          "sold": "980 đã bán",
          "rating": "4.9",
        },
        {
          "thumb": "https://picsum.photos/id/431/300/300",
          "name": "Bộ Dao Kéo Nhà Bếp Inox 6 Món",
          "price": "159.000",
          "originalPrice": "299.000",
          "discount": "-47%",
          "sold": "3,4k đã bán",
          "rating": "5.0",
        },
      ],
    },
    {
      "thumb": "https://picsum.photos/id/1011/400/560",
      "shop": "sneaker_hub",
      "title": "Giày Thể Thao Giảm Đến 60%",
      "viewers": "8,2k",
      "price": "259.000",
    },
    {
      "thumb": "https://picsum.photos/id/1005/400/560",
      "shop": "tech.zone",
      "title": "Mở Hộp Điện Thoại Mới Nhất",
      "viewers": "20,1k",
      "price": "4.990.000",
    },
    {
      "thumb": "https://picsum.photos/id/1013/400/560",
      "shop": "mom_and_baby",
      "title": "Đồ Sơ Sinh Giá Sốc Cuối Tuần",
      "viewers": "3,6k",
      "price": "45.000",
    },
    {
      "thumb": "https://picsum.photos/id/1025/400/560",
      "shop": "home.living.vn",
      "title": "Đồ Gia Dụng Thông Minh Cho Bếp",
      "viewers": "5,9k",
      "price": "329.000",
    },
    {
      "thumb": "https://picsum.photos/id/1035/400/560",
      "shop": "fashion.style",
      "title": "Thời Trang Thu Đông Mới Về",
      "viewers": "15,7k",
      "price": "179.000",
    },
    {
      "thumb": "https://picsum.photos/id/1041/400/560",
      "shop": "sport.gear",
      "title": "Dụng Cụ Tập Gym Tại Nhà",
      "viewers": "2,1k",
      "price": "199.000",
    },
    {
      "thumb": "https://picsum.photos/id/1043/400/560",
      "shop": "pet.corner",
      "title": "Phụ Kiện Thú Cưng Giá Tốt",
      "viewers": "1,8k",
      "price": "59.000",
    },
  ];

  // ============================================================
  // CÀI ĐẶT (settings_screen.dart)
  // ============================================================

  /// Nhóm "Tài khoản" — mỗi mục: icon, label, và trailingValue (tuỳ chọn,
  /// hiển thị bên phải trước mũi tên, ví dụ giá trị hiện tại của cài đặt)
  static const List<Map<String, dynamic>> settingsAccountItems = [
    {"icon": Icons.person_outline, "label": "Thông tin cá nhân"},
    {"icon": Icons.lock_outline, "label": "Đổi mật khẩu"},
    {"icon": Icons.location_on_outlined, "label": "Địa chỉ"},
    {"icon": Icons.account_balance_outlined, "label": "Ngân hàng & Thẻ"},
    {"icon": Icons.language_outlined, "label": "Ngôn ngữ", "trailingValue": "Tiếng Việt"},
  ];

  /// Nhóm "Quyền riêng tư & Bảo mật"
  static const List<Map<String, dynamic>> settingsPrivacyItems = [
    {"icon": Icons.block_outlined, "label": "Danh sách chặn"},
    {"icon": Icons.privacy_tip_outlined, "label": "Quyền riêng tư"},
    {"icon": Icons.delete_outline, "label": "Xoá tài khoản"},
  ];

  /// Nhóm "Thông tin thêm"
  static const List<Map<String, dynamic>> settingsMoreItems = [
    {"icon": Icons.help_outline, "label": "Trung tâm trợ giúp"},
    {"icon": Icons.info_outline, "label": "Về Shopee"},
    {"icon": Icons.description_outlined, "label": "Điều khoản dịch vụ"},
    {"icon": Icons.shield_outlined, "label": "Chính sách bảo mật"},
    {"icon": Icons.star_border, "label": "Đánh giá ứng dụng"},
  ];

  // ============================================================
  // GIỎ HÀNG (cart_screen.dart)
  // ============================================================

  /// Vì CartItem/CartShop chứa field mutable (quantity, selected) nên
  /// không thể khai báo `const` — dùng hàm khởi tạo để mỗi lần mở
  /// trang Giỏ hàng sẽ có một bản dữ liệu mới, độc lập.
  static List<CartShop> buildInitialCartShops() {
    return [
      CartShop(
        shopName: "tech.zone",
        isMall: true,
        items: [
          CartItem(
            image: "https://picsum.photos/id/96/300/300",
            name: "Tai nghe Bluetooth không dây chống nước thể thao",
            variant: "Màu: Đen",
            price: 199000,
            originalPrice: 399000,
            quantity: 1,
            freeship: true,
          ),
          CartItem(
            image: "https://picsum.photos/id/60/300/300",
            name: "Cáp sạc nhanh USB-C 100W dài 2m bọc dù",
            variant: "Loại: 2m",
            price: 59000,
            originalPrice: 99000,
            quantity: 2,
            freeship: true,
          ),
        ],
      ),
      CartShop(
        shopName: "fashion.style",
        isFavorite: true,
        items: [
          CartItem(
            image: "https://picsum.photos/id/21/300/300",
            name: "Giày sneaker nữ đế cao êm chân đi học đi làm",
            variant: "Size: 38 / Trắng",
            price: 219000,
            originalPrice: 350000,
            quantity: 1,
          ),
        ],
      ),
      CartShop(
        shopName: "home.living.vn",
        items: [
          CartItem(
            image: "https://picsum.photos/id/48/300/300",
            name: "Balo laptop chống nước chống trộm đa năng",
            variant: "Màu: Xám",
            price: 175000,
            originalPrice: 280000,
            quantity: 1,
            selected: false,
          ),
        ],
      ),
    ];
  }
}
