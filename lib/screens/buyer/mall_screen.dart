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
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _mainBanners = MockData.mallMainBanners;
  final List<Map<String, dynamic>> _categories = MockData.mallCategories;
  final List<Map<String, dynamic>> _brandVouchers = MockData.mallBrandVouchers;

  // Quick icons chuẩn Shopee Mall (giống ảnh)
  final List<Map<String, dynamic>> _quickIcons = const [
    {'label': 'SHOPEE\nPREMIUM', 'icon': Icons.diamond_outlined, 'color': Color(0xFFC9A227)},
    {'label': 'SĂN DEAL SIÊU\nHOT', 'icon': Icons.local_mall_outlined, 'color': Color(0xFFEE2E24)},
    {'label': 'THƯƠNG HIỆU\nMỚI LÊN SÀN', 'icon': Icons.workspace_premium_outlined, 'color': Color(0xFFB8860B)},
    {'label': 'THƯƠNG HIỆU\nQUỐC TẾ', 'icon': Icons.public, 'color': Color(0xFFE53935)},
    {'label': 'FLASH SALE', 'icon': Icons.bolt, 'color': Color(0xFFEE2E24)},
  ];

  List<Product> _flashRow = [];
  List<Product> _giftProducts = [];
  List<Product> _brandDayProducts = [];
  List<Product> _products = [];
  bool _loadingProducts = true;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _loadMallProducts();
    if (_mainBanners.isNotEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || _mainBanners.isEmpty) return;
        _bannerIndex = (_bannerIndex + 1) % _mainBanners.length;
        if (_bannerController.hasClients) {
          _bannerController.animateToPage(
            _bannerIndex,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _loadMallProducts() async {
    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });
    try {
      final results = await Future.wait([
        ProductApiService.fetchProducts(limit: 6, skip: 9),
        ProductApiService.fetchProducts(limit: 6, skip: 15),
        ProductApiService.fetchProducts(limit: 6, skip: 21),
        ProductApiService.fetchProducts(limit: 16, skip: 27),
      ]);
      if (!mounted) return;
      setState(() {
        _flashRow = results[0];
        _giftProducts = results[1];
        _brandDayProducts = results[2];
        _products = results[3];
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        color: mallRed,
        onRefresh: _loadMallProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(top)),
            SliverToBoxAdapter(child: _buildMainBanner()),
            SliverToBoxAdapter(child: _buildTrustRow()),
            SliverToBoxAdapter(child: const SizedBox(height: 4)),
            SliverToBoxAdapter(child: _buildQuickIconsRow()),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildPromoStrip()),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildMegaSaleBanner()),
            SliverToBoxAdapter(child: _buildHorizontalProductRow(_flashRow, showSeeAll: false)),
            SliverToBoxAdapter(child: _buildSectionTitle('THƯƠNG HIỆU NỔI BẬT TRONG NGÀY', red: true)),
            SliverToBoxAdapter(child: _buildBrandDayBanner()),
            SliverToBoxAdapter(child: _buildHorizontalProductRow(_brandDayProducts, premium: true)),
            SliverToBoxAdapter(child: _buildOutletBanner()),
            SliverToBoxAdapter(
              child: _buildHorizontalProductRow(_giftProducts, showSeeAll: true, seeAllLabel: 'Xem tất cả'),
            ),
            SliverToBoxAdapter(child: _buildBrandVoucherSection()),
            SliverToBoxAdapter(child: _buildSectionTitle('THƯƠNG HIỆU ƯA CHUỘNG', red: true, seeAll: true)),
            SliverToBoxAdapter(child: _buildFavoriteBrandsRow()),
            SliverToBoxAdapter(child: _buildSectionTitle('GỢI Ý HÔM NAY', red: true)),
            SliverToBoxAdapter(child: _buildProductGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(double topPadding) {
    return Container(
      color: mallRed,
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Shopee Mall',
                      style: TextStyle(
                        color: mallRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.camera_alt_outlined, color: Colors.grey.shade500, size: 20),
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
            child: AnimatedBuilder(
              animation: CartService.instance,
              builder: (context, _) {
                final count = CartService.instance.totalItemCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
                    if (count > 0)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
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
          const SizedBox(width: 12),
          const Icon(Icons.more_vert, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  // ================= MAIN BANNER =================
  Widget _buildMainBanner() {
    final banners = _mainBanners.isNotEmpty
        ? _mainBanners
        : [
            {
              'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800',
              'title1': 'CÔNG NGHỆ ĐỈNH CAO',
              'title2': 'GIÁ SỐC NGÀY VÀNG',
              'tag': 'OPPO',
              'date': 'DUY NHẤT: 04/07 – 07/07',
              'voucher': '100.000',
              'discount': '50%',
              'gift': '80.000',
            },
          ];

    return Container(
      color: mallRed,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: SizedBox(
        height: 168,
        child: Stack(
          children: [
            PageView.builder(
              controller: _bannerController,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (context, index) => _buildBannerSlide(banners[index]),
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (i) {
                  final active = i == _bannerIndex;
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
    final imageUrl = b['image'] as String? ?? '';
    final title1 = (b['title1'] as String?) ?? 'CÔNG NGHỆ ĐỈNH CAO';
    final title2 = (b['title2'] as String?) ?? 'GIÁ SỐC NGÀY VÀNG';
    final tag = (b['tag'] as String?) ?? 'OPPO';
    final date = (b['date'] as String?) ?? 'DUY NHẤT: 04/07 – 07/07';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFC62828)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh sản phẩm bên phải
          if (imageUrl.isNotEmpty)
            Positioned(
              right: -8,
              top: 0,
              bottom: 0,
              width: 160,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          // Gradient che bên trái để chữ rõ
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD32F2F),
                    const Color(0xFFD32F2F).withOpacity(0.92),
                    const Color(0xFFE53935).withOpacity(0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 0.62, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Nội dung
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Tag thương hiệu (OPPO / 8.8...)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Shopee Mall',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    // FREESHIP góc phải
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FREESHIP 0Đ',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  title2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                ),
              ],
            ),
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
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          item(Icons.replay_circle_filled_outlined, 'Trả hàng 15 ngày'),
          item(Icons.verified, 'Chính hãng 100%'),
          item(Icons.local_shipping_outlined, 'Giao miễn phí'),
        ],
      ),
    );
  }

  // ================= QUICK ICONS =================
  Widget _buildQuickIconsRow() {
    // Nền hồng nhạt + icon đỏ cam, chữ thường (không in đậm) giống ảnh Shopee
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: _quickIcons.map((q) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    q['icon'] as IconData,
                    color: const Color(0xFFE64A19),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  q['label'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w400, // không in đậm
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= PROMO STRIP (xanh lá – chăm tóc) =================
  Widget _buildPromoStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 8,
            bottom: 8,
            child: Row(
              children: [
                Icon(Icons.spa, color: Colors.white.withOpacity(0.9), size: 40),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CHĂM TÓC CHUYÊN NGHIỆP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      'TÓC "SLAY" CUỐN HÚT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'KHÁM PHÁ NGAY ›',
                      style: TextStyle(color: Color(0xFFFFEB3B), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DANH MỤC =================
  Widget _buildCategoriesSection() {
    final cats = _categories.isNotEmpty
        ? _categories
        : [
            {'label': 'Thể Thao &\nDu Lịch', 'image': 'https://picsum.photos/id/21/120'},
            {'label': 'Ô Tô & Xe Máy', 'image': 'https://picsum.photos/id/111/120'},
            {'label': 'Bách Hóa\nOnline', 'image': 'https://picsum.photos/id/292/120'},
            {'label': 'Nhà Cửa &\nĐời Sống', 'image': 'https://picsum.photos/id/201/120'},
            {'label': 'Sắc Đẹp', 'image': 'https://picsum.photos/id/64/120'},
          ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Xem thêm sản phẩm >', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final c = cats[index];
                return SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.network(
                          c['image'] as String,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 58,
                            height: 58,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.category, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c['label'] as String,
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

  // ================= MEGA SALE BANNER =================
  Widget _buildMegaSaleBanner() {
    return Container(
      height: 130,
      margin: const EdgeInsets.only(top: 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            bottom: 8,
            child: Icon(Icons.card_giftcard, size: 90, color: Colors.amber.withOpacity(0.35)),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text('Shopee Mall', style: TextStyle(color: mallRed, fontSize: 10.5, fontWeight: FontWeight.bold)),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber[600], borderRadius: BorderRadius.circular(4)),
                  child: const Text(
                    'SIÊU SALE THƯƠNG HIỆU',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    'THỎA SỨC SĂN DEAL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title, {bool red = false, bool seeAll = false}) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: red ? mallRed : Colors.black87,
              ),
            ),
          ),
          if (seeAll)
            const Text('Xem tất cả >', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
        ],
      ),
    );
  }

  // ================= BRAND DAY BANNER =================
  Widget _buildBrandDayBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('SHOPEE PREMIUM  |  THƯƠNG HIỆU', style: TextStyle(color: Colors.white70, fontSize: 11)),
          SizedBox(height: 4),
          Text('ƯU ĐÃI ĐẾN 50%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          SizedBox(height: 4),
          Text('Mua 1 tặng quà  •  Hàng chính hãng', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  // ================= OUTLET BANNER =================
  Widget _buildOutletBanner() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), mallRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Shopee Mall OUTLET',
                    style: TextStyle(color: mallRed, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('SALES HÀNG HIỆU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                const Text('100% CHÍNH HÃNG', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('GIẢM ĐẾN', style: TextStyle(color: Colors.white, fontSize: 12)),
                Text('40%', style: TextStyle(color: Colors.amber[300], fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                const Text('MỖI NGÀY', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HORIZONTAL PRODUCT ROW =================
  Widget _buildHorizontalProductRow(
    List<Product> items, {
    bool showSeeAll = false,
    String seeAllLabel = 'Xem tất cả',
    bool premium = false,
  }) {
    if (items.isEmpty) {
      if (_loadingProducts) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(color: mallRed, strokeWidth: 2)),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          if (showSeeAll)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Xem tất cả >', style: TextStyle(fontSize: 12.5, color: mallRed, fontWeight: FontWeight.w600)),
              ),
            ),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _buildMallProductCard(items[index], width: 148, premium: premium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMallProductCard(Product p, {double width = 148, bool premium = false}) {
    return GestureDetector(
      onTap: () => _openProductDetail(p),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: p.thumbnail.isEmpty
                      ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined))
                      : Image.network(
                          p.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                ),
                if (p.discountPercent > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(3)),
                      child: Text(
                        '-${p.discountPercent}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                    color: Colors.black.withOpacity(0.04),
                    child: Row(
                      children: [
                        _miniPromo('8.8', mallRed),
                        const SizedBox(width: 3),
                        _miniPromo('VOUCHER XTRA', const Color(0xFFFF6D00)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1, right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: premium ? const Color(0xFF5D4037) : mallRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          premium ? 'PREMIUM' : 'Mall',
                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: mallRed.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('Mua để nhận quà', style: TextStyle(color: mallRed, fontSize: 9.5)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.priceText,
                          style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.w800, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: mallRed, shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_cart, size: 13, color: Colors.white),
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

  Widget _miniPromo(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
    );
  }

  // ================= ƯU ĐÃI SHOPEE MALL (voucher) =================
  Widget _buildBrandVoucherSection() {
    final vouchers = _brandVouchers.isNotEmpty
        ? _brandVouchers
        : [
            {
              'name': 'Nutifood Official',
              'logo': 'https://picsum.photos/id/225/80',
              'percent': 'giảm 2%',
              'condition': 'Không giới hạn giá trị khuyến mãi tối đa...',
            },
            {
              'name': 'CeraVe Official',
              'logo': 'https://picsum.photos/id/201/80',
              'percent': 'giảm 3%',
              'condition': 'Giảm tối đa 20kđ Đơn tối thiểu 300kđ',
            },
          ];

    return Container(
      color: Colors.white,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ƯU ĐÃI SHOPEE MALL',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: mallRed),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _buildVoucherCard(vouchers[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // left notch style
          Container(
            width: 88,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.network(
                    v['logo'] as String? ?? '',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.store, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  v['name'] as String? ?? 'Shop',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.2),
                ),
              ],
            ),
          ),
          Container(width: 1, height: double.infinity, color: Colors.grey.shade200),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['percent'] as String? ?? 'giảm 5%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v['condition'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.25),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: mallRed),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('Mall', style: TextStyle(color: mallRed, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: mallRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Điều kiện',
                      style: TextStyle(color: Color(0xFF1565C0), fontSize: 11, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= THƯƠNG HIỆU ƯA CHUỘNG =================
  Widget _buildFavoriteBrandsRow() {
    final brands = [
      'https://picsum.photos/id/21/200',
      'https://picsum.photos/id/64/200',
      'https://picsum.photos/id/111/200',
      'https://picsum.photos/id/201/200',
    ];
    return Container(
      color: Colors.white,
      height: 120,
      padding: const EdgeInsets.only(bottom: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              brands[i],
              width: 120,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 120, color: Colors.grey.shade200),
            ),
          );
        },
      ),
    );
  }

  // ================= PRODUCT GRID (Gợi ý hôm nay) =================
  Widget _buildProductGrid() {
    if (_loadingProducts && _products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: mallRed)),
      );
    }
    if (_productsError != null && _products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
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
          childAspectRatio: 0.68,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, index) => _buildGridProductCard(_products[index], index: index),
      ),
    );
  }

  /// Card "Gợi ý hôm nay" – layout gọn, sạch giống Shopee Mall.
  Widget _buildGridProductCard(Product p, {int index = 0}) {
    // Rating luôn cao (4.8 – 5.0) như Shopee Mall thật
    final rating = (4.8 + (index % 3) * 0.1).clamp(4.8, 5.0);
    final tagType = index % 4; // 0 hot, 1 revo, 2 spay, 3 only rating
    final promoType = index % 3; // 0: 8.8+voucher+style, 1: 8.8 only, 2: 8.8+style

    return GestureDetector(
      onTap: () => _openProductDetail(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== ẢNH ==========
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: Colors.grey.shade50,
                    child: p.thumbnail.isEmpty
                        ? const Icon(Icons.image_not_supported_outlined, color: Colors.grey)
                        : Image.network(
                            p.thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                  ),
                ),
                // % giảm – góc trên phải, nền cam nhạt
                if (p.discountPercent > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                      color: const Color(0xFFFFE0B2),
                      child: Text(
                        '-${p.discountPercent}%',
                        style: const TextStyle(
                          color: Color(0xFFEF6C00),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Badge dưới ảnh: 8.8 (+ promo tùy card)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        color: const Color(0xFFFF6D00),
                        child: const Text(
                          '8.8',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (promoType == 0 || promoType == 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: const Color(0xFFFF8F00),
                          child: const Text(
                            'VOUCHER XTRA',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      if (promoType == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: const Color(0xFF1E88E5),
                          child: const Text(
                            'SHOPEE STYLE',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      if (promoType == 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: const Color(0xFF1E88E5),
                          child: const Text(
                            'SHOPEE STYLE',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // ========== INFO (compact) ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mall + tên
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                            decoration: BoxDecoration(
                              color: mallRed,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'Mall',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: p.name,
                          style: const TextStyle(fontSize: 12, height: 1.2, color: Color(0xFF222222)),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tag
                  Row(
                    children: [
                      if (tagType == 0) ...[
                        _miniTag('Đang bán chạy', const Color(0xFFE65100), const Color(0xFFFFF3E0), Icons.local_fire_department),
                        const SizedBox(width: 4),
                      ],
                      if (tagType == 1) ...[
                        _miniTag('Rẻ Vô Địch', const Color(0xFFE65100), const Color(0xFFFFF3E0), Icons.thumb_up_alt),
                        const SizedBox(width: 4),
                      ],
                      _miniTag(rating.toStringAsFixed(1), const Color(0xFFF9A825), const Color(0xFFFFF8E1), Icons.star),
                      if (tagType == 2) ...[
                        const SizedBox(width: 4),
                        _miniTag('SPayLater 0%', const Color(0xFF1565C0), const Color(0xFFE3F2FD), null),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Giá + đã bán
                  Row(
                    children: [
                      Text(
                        p.priceText,
                        style: const TextStyle(
                          color: shopeeOrange,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.monetization_on, size: 12, color: Color(0xFFFFB300)),
                      const Spacer(),
                      Text(
                        '${p.soldText} đã bán',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
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

  Widget _miniTag(String label, Color color, Color bg, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ],
      ),
    );
  }
}
