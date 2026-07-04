import 'dart:async';
import 'package:flutter/material.dart';
import 'cart_screen.dart';

class ShopeeMallPage extends StatefulWidget {
  const ShopeeMallPage({super.key});

  @override
  State<ShopeeMallPage> createState() => _ShopeeMallPageState();
}

class _ShopeeMallPageState extends State<ShopeeMallPage> {
  static const Color mallRed = Color(0xFFEE2E24);
  static const Color darkRed = Color(0xFFC5171B);
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // ============== BANNER CHÍNH (7.7) ==============
  final List<Map<String, dynamic>> _mainBanners = const [
    {
      "tag": "lazychef",
      "title1": "BẾP THÀNH THƠI",
      "title2": "VỊ HẠNH PHÚC",
      "date": "DUY NHẤT: 04/07 – 07/07",
      "voucher": "300.000",
      "discount": "45%",
      "gift": "500.000",
      "image": "https://picsum.photos/id/292/500/500",
    },
    {
      "tag": "OPPO",
      "title1": "CÔNG NGHỆ ĐỈNH CAO",
      "title2": "GIÁ SỐC NGÀY VÀNG",
      "date": "DUY NHẤT: 04/07 – 07/07",
      "voucher": "200.000",
      "discount": "30%",
      "gift": "300.000",
      "image": "https://picsum.photos/id/160/500/500",
    },
    {
      "tag": "L'Oréal",
      "title1": "RỰC RỠ SẮC XINH",
      "title2": "ƯU ĐÃI NGẬP TRÀN",
      "date": "DUY NHẤT: 04/07 – 07/07",
      "voucher": "150.000",
      "discount": "50%",
      "gift": "200.000",
      "image": "https://picsum.photos/id/119/500/500",
    },
  ];

  // ============== HÀNG ICON TIỆN ÍCH ==============
  final List<Map<String, dynamic>> _quickIcons = const [
    {"icon": Icons.diamond, "color": Color(0xFFFFC107), "label": "SHOPEE\nPREMIUM"},
    {"icon": Icons.shopping_bag, "color": Color(0xFFEE4D2D), "label": "SĂN DEAL SIÊU\nHOT"},
    {"icon": Icons.emoji_events, "color": Color(0xFFFF7A00), "label": "THƯƠNG HIỆU\nMỚI LÊN SÀN"},
    {"icon": Icons.public, "color": Color(0xFFEE2E24), "label": "THƯƠNG HIỆU\nQUỐC TẾ"},
    {"icon": Icons.bolt, "color": Color(0xFF222222), "label": "FLASH SALE"},
  ];

  // ============== DANH MỤC ==============
  final List<Map<String, dynamic>> _categories = const [
    {"image": "https://picsum.photos/id/1074/200/200", "label": "Thể Thao & Du Lịch"},
    {"image": "https://picsum.photos/id/1071/200/200", "label": "Ô Tô & Xe Máy & Xe Đạp"},
    {"image": "https://picsum.photos/id/1080/200/200", "label": "Bách Hóa Online"},
    {"image": "https://picsum.photos/id/312/200/200", "label": "Nhà Cửa & Đời Sống"},
    {"image": "https://picsum.photos/id/26/200/200", "label": "Sắc Đẹp"},
    {"image": "https://picsum.photos/id/48/200/200", "label": "Mẹ & Bé"},
  ];

  // ============== DÃY SẢN PHẨM VOUCHER XTRA (ngang) ==============
  final List<Map<String, dynamic>> _flashRow = const [
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

  // ============== KHỐI "MUA ĐỂ NHẬN QUÀ" ==============
  final List<Map<String, dynamic>> _giftProducts = const [
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

  // ============== ƯU ĐÃI SHOPEE MALL (voucher thương hiệu) ==============
  final List<Map<String, dynamic>> _brandVouchers = const [
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

  // ============== LƯỚI SẢN PHẨM CHÍNH (sau ưu đãi) ==============
  final List<Map<String, dynamic>> _products = const [
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

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _bannerIndex = (_bannerIndex + 1) % _mainBanners.length;
      _bannerController.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: RefreshIndicator(
        color: mallRed,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildMainBanner(),
              _buildTrustRow(),
              const SizedBox(height: 8),
              _buildQuickIconsRow(),
              const SizedBox(height: 8),
              _buildCategoriesSection(),
              const SizedBox(height: 8),
              _buildMegaSaleBanner(),
              const SizedBox(height: 4),
              _buildFlashRow(),
              const SizedBox(height: 8),
              _buildOutletBanner(),
              _buildGiftSection(),
              const SizedBox(height: 8),
              _buildBrandVoucherSection(),
              const SizedBox(height: 8),
              _buildProductsHeader(),
              _buildProductGrid(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: mallRed,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: shopeeOrange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Shopee Mall",
                      style: TextStyle(
                        color: shopeeOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
                  );
                },
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 25),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const Icon(Icons.more_vert, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  // ================= MAIN BANNER (7.7) =================
  Widget _buildMainBanner() {
    return Container(
      color: mallRed,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
      child: SizedBox(
        height: 175,
        child: Stack(
          children: [
            PageView.builder(
              controller: _bannerController,
              itemCount: _mainBanners.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (context, index) => _buildBannerSlide(_mainBanners[index]),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mainBanners.length, (i) {
                  final bool active = i == _bannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: active ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSlide(Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF8C0E12), Color(0xFFEE2E24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  b["image"] as String,
                  width: 170,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Shopee Mall",
                style: TextStyle(
                  color: mallRed,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "7.7",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "CÒN 3 NGÀY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b["tag"] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 42,
            right: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b["title1"] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                Text(
                  b["title2"] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b["date"] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                Expanded(child: _bannerPill("VOUCHER", "${b["voucher"]}đ")),
                const SizedBox(width: 4),
                Expanded(child: _bannerPill("GIẢM ĐẾN", "${b["discount"]}")),
                const SizedBox(width: 4),
                Expanded(child: _bannerPill("QUÀ TẶNG", "${b["gift"]}đ")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPill(String top, String bottom) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(top, style: const TextStyle(color: Colors.white70, fontSize: 8)),
          Text(
            bottom,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ================= TRUST ROW =================
  Widget _buildTrustRow() {
    Widget item(IconData icon, String label) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: mallRed, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        children: [
          item(Icons.replay_circle_filled_outlined, "Trả hàng 15 ngày"),
          item(Icons.verified, "Chính hãng 100%"),
          item(Icons.local_shipping, "Giao miễn phí"),
        ],
      ),
    );
  }

  // ================= QUICK ICONS =================
  Widget _buildQuickIconsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        children: _quickIcons.map((q) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (q["color"] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(q["icon"] as IconData, color: q["color"] as Color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  q["label"] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 9.5, height: 1.15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= DANH MỤC =================
  Widget _buildCategoriesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Danh mục", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(
                "Xem thêm sản phẩm  >",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final c = _categories[index];
                return SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.network(
                          c["image"] as String,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c["label"] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, height: 1.15),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= BANNER SIÊU SALE THƯƠNG HIỆU =================
  Widget _buildMegaSaleBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [mallRed, Color(0xFFB8171B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            bottom: -20,
            child: Icon(Icons.card_giftcard, size: 150, color: Colors.amber.withOpacity(0.35)),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text(
                "Shopee Mall",
                style: TextStyle(color: mallRed, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "SIÊU SALE THƯƠNG HIỆU",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    "THỎA SỨC SĂN DEAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= FLASH ROW (voucher xtra) =================
  Widget _buildFlashRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 240,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: _flashRow.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final p = _flashRow[index];
            return SizedBox(
              width: 165,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(p["image"] as String, fit: BoxFit.cover, width: double.infinity),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(3)),
                            child: Text(
                              "-${p["discount"]}%",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            color: Colors.amber[700],
                            alignment: Alignment.center,
                            child: const Text(
                              "7.7 VOUCHER XTRA",
                              style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(2)),
                                child: const Text(
                                  "Mall",
                                  style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  p["title"] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, height: 1.2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= OUTLET BANNER =================
  Widget _buildOutletBanner() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7A0E0E), mallRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                "https://picsum.photos/id/103/220/220",
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.05),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Shopee Mall Outlet",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "SALES HÀNG HIỆU",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: [
                    const Text("GIẢM ĐẾN ", style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text(
                      "40%",
                      style: TextStyle(color: Colors.amber[300], fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const Text(
                  "100% CHÍNH HÃNG",
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= GIFT SECTION (Xem tất cả) =================
  Widget _buildGiftSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                "Xem tất cả  >",
                style: TextStyle(fontSize: 12.5, color: mallRed, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _giftProducts.map((p) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(p["image"] as String, fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          if ((p["discount"] as int) > 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(3)),
                                child: Text(
                                  "-${p["discount"]}%",
                                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(2)),
                            child: const Text(
                              "Mall",
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p["title"] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      if (p["hasGift"] as bool)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: mallRed),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            "Mua để nhận quà",
                            style: TextStyle(color: mallRed, fontSize: 9),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${p["price"]}đ",
                              style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.confirmation_num_outlined, size: 14, color: mallRed),
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: mallRed, shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_cart, size: 11, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ================= ƯU ĐÃI SHOPEE MALL =================
  Widget _buildBrandVoucherSection() {
    return Container(
      color: const Color(0xFFF2F3F5),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ƯU ĐÃI SHOPEE MALL",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _brandVouchers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.92,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) => _buildVoucherCard(_brandVouchers[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v) {
    const double notchY = 108; // vị trí đường đứt nét (tính từ đỉnh thẻ)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ClipOval(
                          child: Image.network(
                            v["logo"] as String,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: Text(
                            v["name"] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, height: 1.2, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v["percent"] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            v["condition"] as String,
                            style: const TextStyle(fontSize: 10.5, color: Colors.grey, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // đường kẻ đứt nét kiểu vé giảm giá
                Row(
                  children: List.generate(22, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        height: 1,
                        color: i.isEven ? Colors.grey.shade300 : Colors.transparent,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: mallRed, width: 1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        "Mall",
                        style: TextStyle(color: mallRed, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: mallRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Lưu",
                        style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Điều kiện",
                    style: TextStyle(
                      color: Color(0xFF0055CC),
                      fontSize: 10.5,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // notch trái/phải tạo cảm giác "vé giảm giá"
          Positioned(
            left: -8,
            top: notchY,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: Color(0xFFF2F3F5), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -8,
            top: notchY,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: Color(0xFFF2F3F5), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PRODUCTS HEADER =================
  Widget _buildProductsHeader() {
    return Container(
      color: const Color(0xFFF2F3F5),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: const [
          Expanded(child: Divider(thickness: 1, indent: 12, endIndent: 8, color: Colors.grey)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "SẢN PHẨM MALL NỔI BẬT",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Divider(thickness: 1, indent: 8, endIndent: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ================= PRODUCT GRID =================
  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, index) => _buildProductCard(_products[index]),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    p["image"] as String,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.favorite_border, size: 16, color: Colors.grey.shade400),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: mallRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    "Mall",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  color: Colors.yellow[700],
                  child: Text(
                    "-${p["discount"]}%",
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p["title"] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.2),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₫${p["price"]}",
                      style: const TextStyle(
                        color: shopeeOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "₫${p["originalPrice"]}",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10.5,
                          decoration: TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      "${p["rating"]}",
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Đã bán ${p["sold"]}",
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}