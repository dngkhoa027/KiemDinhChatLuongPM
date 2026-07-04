import 'dart:async';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'mall_screen.dart';
import 'live_screen.dart';
import 'cart_screen.dart';

class ShopeeHomePage extends StatefulWidget {
  const ShopeeHomePage({super.key});

  @override
  State<ShopeeHomePage> createState() => _ShopeeHomePageState();
}

class _ShopeeHomePageState extends State<ShopeeHomePage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);

  // ============== BOTTOM NAV ==============
  int _currentIndex = 0;

  // ============== BANNER CAROUSEL ==============
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List<String> _banners = const [
    "https://picsum.photos/id/1011/800/360",
    "https://picsum.photos/id/1015/800/360",
    "https://picsum.photos/id/1025/800/360",
  ];

  // ============== FLASH SALE COUNTDOWN ==============
  Timer? _countdownTimer;
  Duration _remaining = const Duration(hours: 2, minutes: 45, seconds: 12);

  // ============== DATA: CATEGORIES ==============
  final List<Map<String, dynamic>> _categories = const [
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

  // ============== DATA: FLASH SALE PRODUCTS ==============
  final List<Map<String, dynamic>> _flashSaleItems = const [
    {"image": "https://picsum.photos/id/103/300/300", "price": "39.000", "sold": 0.86, "discount": 45},
    {"image": "https://picsum.photos/id/201/300/300", "price": "129.000", "sold": 0.62, "discount": 30},
    {"image": "https://picsum.photos/id/312/300/300", "price": "79.000", "sold": 0.95, "discount": 50},
    {"image": "https://picsum.photos/id/145/300/300", "price": "259.000", "sold": 0.4, "discount": 20},
    {"image": "https://picsum.photos/id/342/300/300", "price": "99.000", "sold": 0.78, "discount": 35},
  ];

  // ============== DATA: PRODUCT GRID (GỢI Ý HÔM NAY) ==============
  final List<Map<String, dynamic>> _products = const [
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
  ];

  @override
  void initState() {
    super.initState();

    // Tự động chuyển banner mỗi 3 giây
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _bannerIndex = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });

    // Đếm ngược Flash Sale
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _remaining = const Duration(hours: 2, minutes: 45, seconds: 12);
        }
      });
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const ShopeeMallPage(),
      const ShopeeLivePage(),
      const ShopeeNotificationPage(),
      const ShopeeProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: shopeeOrange,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: "Mall"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Thông báo"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Tôi"),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
    );
  }

  // =========================================================
  // TAB: HOME
  // =========================================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: shopeeOrange,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildQuickAccessRow(),
            const SizedBox(height: 8),
            _buildCategoriesGrid(),
            const SizedBox(height: 8),
            _buildFlashSaleSection(),
            const SizedBox(height: 8),
            _buildSuggestionHeader(),
            _buildProductGrid(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ================= HEADER: SEARCH + BANNER =================
  Widget _buildHeader() {
    return Container(
      color: shopeeOrange,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 10),
                      Icon(Icons.search, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Bút Deli",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "5",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "19",
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ---- Banner carousel ----
          SizedBox(
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
                          color: active ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK ACCESS ROW =================
  Widget _buildQuickAccessRow() {
    final items = [
      {"icon": Icons.monetization_on, "label": "Shopee Xu", "color": Colors.orange},
      {"icon": Icons.confirmation_number, "label": "Voucher Xtra", "color": shopeeOrange},
      {"icon": Icons.replay_circle_filled, "label": "Hoàn Tiền Xtra", "color": Colors.red},
      {"icon": Icons.local_shipping, "label": "Freeship Xtra", "color": Colors.green},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((it) {
          return Column(
            children: [
              Icon(it["icon"] as IconData, color: it["color"] as Color, size: 26),
              const SizedBox(height: 4),
              Text(
                it["label"] as String,
                style: const TextStyle(fontSize: 10.5),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ================= CATEGORIES GRID =================
  Widget _buildCategoriesGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Column(
            children: [
              Icon(cat["icon"] as IconData, color: shopeeOrange, size: 26),
              const SizedBox(height: 6),
              Text(
                cat["label"] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, height: 1.1),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= FLASH SALE =================
  Widget _buildFlashSaleSection() {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.flash_on, color: shopeeRed, size: 22),
                const SizedBox(width: 4),
                const Text(
                  "FLASH SALE",
                  style: TextStyle(
                    color: shopeeRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _timeBox(h),
                _timeColon(),
                _timeBox(m),
                _timeColon(),
                _timeBox(s),
                const Spacer(),
                const Text(
                  "Xem Tất Cả  >",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _flashSaleItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _flashSaleItems[index];
                return _buildFlashSaleCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _timeColon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(":", style: TextStyle(color: shopeeRed, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFlashSaleCard(Map<String, dynamic> item) {
    final double soldRatio = item["sold"] as double;
    return Container(
      width: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: Image.network(
              item["image"] as String,
              height: 108,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₫${item["price"]}",
                      style: const TextStyle(
                        color: shopeeRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      color: Colors.yellow[700],
                      child: Text(
                        "-${item["discount"]}%",
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 100,
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFFFFD9CE)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: soldRatio,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFFF7337), shopeeRed]),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            soldRatio > 0.8 ? "Sắp hết hàng" : "Đã bán ${(soldRatio * 100).toInt()}%",
                            style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
              "GỢI Ý HÔM NAY",
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
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        p["location"] as String,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
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
