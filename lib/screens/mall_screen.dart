import 'dart:async';
import 'package:flutter/material.dart';
import 'cart_screen.dart';

class ShopeeMallPage extends StatefulWidget {
  const ShopeeMallPage({super.key});

  @override
  State<ShopeeMallPage> createState() => _ShopeeMallPageState();
}

class _ShopeeMallPageState extends State<ShopeeMallPage> {
  static const Color mallRed = Color(0xFFD0011B);
  static const Color mallBlack = Color(0xFF0D0D0D);
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List<String> _banners = const [
    "https://picsum.photos/id/1005/800/360",
    "https://picsum.photos/id/1035/800/360",
    "https://picsum.photos/id/1041/800/360",
  ];

  // ============== DATA: THƯƠNG HIỆU CHÍNH HÃNG ==============
  final List<Map<String, dynamic>> _brands = const [
    {"logo": "https://picsum.photos/id/201/120/120", "name": "Samsung"},
    {"logo": "https://picsum.photos/id/202/120/120", "name": "L'Oréal"},
    {"logo": "https://picsum.photos/id/203/120/120", "name": "Nestlé"},
    {"logo": "https://picsum.photos/id/204/120/120", "name": "Nike"},
    {"logo": "https://picsum.photos/id/205/120/120", "name": "Xiaomi"},
    {"logo": "https://picsum.photos/id/206/120/120", "name": "Unilever"},
  ];

  // ============== DATA: DANH MỤC MALL ==============
  final List<Map<String, dynamic>> _categories = const [
    {"icon": Icons.checkroom, "label": "Thời Trang"},
    {"icon": Icons.devices_other, "label": "Điện Tử"},
    {"icon": Icons.face_retouching_natural, "label": "Sắc Đẹp"},
    {"icon": Icons.chair_alt, "label": "Nhà Cửa"},
    {"icon": Icons.child_friendly, "label": "Mẹ & Bé"},
    {"icon": Icons.grid_view, "label": "Xem Thêm"},
  ];

  // ============== DATA: SẢN PHẨM MALL ==============
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
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _bannerIndex = (_bannerIndex + 1) % _banners.length;
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
              _buildBanner(),
              const SizedBox(height: 8),
              _buildCategoriesGrid(),
              const SizedBox(height: 8),
              _buildBrandsSection(),
              const SizedBox(height: 8),
              _buildSuggestionHeader(),
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
      color: mallBlack,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Row(
            children: [
              const Text(
                "Shopee",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: mallRed,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  "Mall",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 10),
                  Icon(Icons.search, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tìm sản phẩm chính hãng",
                      style: TextStyle(color: Colors.grey, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
              );
            },
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // ================= BANNER =================
  Widget _buildBanner() {
    return Container(
      color: mallBlack,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemBuilder: (context, index) {
                  return Image.network(
                    _banners[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                },
              ),
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  final bool active = i == _bannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: active ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? mallRed : Colors.white54,
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

  // ================= CATEGORIES =================
  Widget _buildCategoriesGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Column(
            children: [
              Icon(cat["icon"] as IconData, color: mallRed, size: 24),
              const SizedBox(height: 6),
              Text(
                cat["label"] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, height: 1.1),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= BRANDS =================
  Widget _buildBrandsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Thương Hiệu Chính Hãng",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _brands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final b = _brands[index];
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        b["logo"] as String,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b["name"] as String,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUGGESTION HEADER =================
  Widget _buildSuggestionHeader() {
    return Container(
      color: const Color(0xFFF2F3F5),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: const [
          Expanded(
            child: Divider(thickness: 1, indent: 12, endIndent: 8, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "SẢN PHẨM MALL NỔI BẬT",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Divider(thickness: 1, indent: 8, endIndent: 12, color: Colors.grey),
          ),
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
