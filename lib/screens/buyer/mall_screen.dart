import 'dart:async';
import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../../data/mock_data.dart';
import '../../models/product_model.dart';
import '../../services/product_api_service.dart';
import '../../services/cart_service.dart';

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
  // Dữ liệu lấy từ lib/data/mock_data.dart -> sau này thay bằng API tại đây
  final List<Map<String, dynamic>> _mainBanners = MockData.mallMainBanners;

  // ============== HÀNG ICON TIỆN ÍCH ==============
  final List<Map<String, dynamic>> _quickIcons = MockData.mallQuickIcons;

  // ============== DANH MỤC ==============
  final List<Map<String, dynamic>> _categories = MockData.mallCategories;

  // ============== ƯU ĐÃI SHOPEE MALL (voucher thương hiệu, không phải sản phẩm) ==============
  final List<Map<String, dynamic>> _brandVouchers = MockData.mallBrandVouchers;

  // ============== SẢN PHẨM (lấy từ API DummyJSON - KHÔNG dùng mock nữa) ==============
  // Dùng skip khác với Home để không hiển thị trùng sản phẩm giữa 2 màn hình.
  List<Product> _flashRow = [];
  List<Product> _giftProducts = [];
  List<Product> _products = [];
  bool _loadingProducts = true;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _loadMallProducts();
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

  // Lấy 3 nhóm sản phẩm từ API DummyJSON, mỗi nhóm dùng "skip" riêng và
  // KHÁC với Home (Home dùng skip 0-9) để tránh hiển thị trùng sản phẩm
  // giữa 2 màn hình.
  Future<void> _loadMallProducts() async {
    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });
    try {
      final results = await Future.wait([
        ProductApiService.fetchProducts(limit: 3, skip: 9), // dãy voucher xtra
        ProductApiService.fetchProducts(limit: 3, skip: 12), // mua để nhận quà
        ProductApiService.fetchProducts(limit: 16, skip: 15), // lưới sản phẩm chính
      ]);
      if (!mounted) return;
      setState(() {
        _flashRow = results[0];
        _giftProducts = results[1];
        _products = results[2];
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = 'Không thể tải sản phẩm. Vui lòng kiểm tra kết nối mạng.';
        _loadingProducts = false;
      });
    }
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
                child: AnimatedBuilder(
                  animation: CartService.instance,
                  builder: (context, _) {
                    final count = CartService.instance.totalItemCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 25),
                        if (count > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 16),
                              decoration: BoxDecoration(
                                color: Colors.yellow[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
    if (_flashRow.isEmpty) {
      return _loadingProducts
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: mallRed)),
            )
          : const SizedBox.shrink();
    }
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
            return GestureDetector(
              onTap: () => _openProductDetail(p),
              child: SizedBox(
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
                            child: p.thumbnail.isEmpty
                                ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                                : Image.network(
                                    p.thumbnail,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(3)),
                            child: Text(
                              "-${p.discountPercent}%",
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
                                  p.name,
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
    if (_giftProducts.isEmpty) return const SizedBox.shrink();
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
                child: GestureDetector(
                  onTap: () => _openProductDetail(p),
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
                              child: p.thumbnail.isEmpty
                                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                                  : Image.network(
                                      p.thumbnail,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                                    ),
                            ),
                          ),
                          if (p.discountPercent > 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(3)),
                                child: Text(
                                  "-${p.discountPercent}%",
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
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      if (p.discountPercent >= 40)
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
                              p.priceText,
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
              // Giảm tỉ lệ (tăng chiều cao ô) để có thêm khoảng đệm,
              // tránh tràn khi text bị wrap thêm dòng trên máy có cỡ chữ lớn hơn.
              childAspectRatio: 0.80,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
  // ---- Mở trang chi tiết sản phẩm khi bấm vào 1 sản phẩm bất kỳ trong Mall ----
  // `p.id` là id thật từ API nên tên/ảnh/giá ở trang chi tiết luôn khớp
  // với đúng sản phẩm đã bấm (không còn hash tên để "đoán" id nữa).
  void _openProductDetail(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          seedId: p.id,
          fallbackName: p.name,
          fallbackImage: p.thumbnail,
          fallbackPrice: p.price,
          fallbackOriginalPrice: p.originalPrice,
          fallbackDiscount: p.discountPercent,
          fallbackRating: p.rating,
          fallbackSoldCount: p.soldCount,
          fallbackLocation: p.location,
        ),
      ),
    );
  }

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
    if (_loadingProducts && _products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: mallRed)),
      );
    }
    if (_productsError != null && _products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Text(_productsError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loadMallProducts, child: const Text('Thử lại')),
          ],
        ),
      );
    }
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

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () => _openProductDetail(p),
      child: Container(
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
                  child: p.thumbnail.isEmpty
                      ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                      : Image.network(
                          p.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
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
              if (p.discountPercent > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: Colors.yellow[700],
                    child: Text(
                      "-${p.discountPercent}%",
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
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.2),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p.priceText,
                      style: const TextStyle(
                        color: shopeeOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.originalPriceText,
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
                      p.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Đã bán ${p.soldText}",
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
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
  }
}