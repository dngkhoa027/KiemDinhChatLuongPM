import 'dart:async';
import 'package:flutter/material.dart';
import '../shared/profile_screen.dart';
import '../shared/notification_screen.dart';
import 'mall_screen.dart';
import 'live_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../../data/mock_data.dart';
import '../../models/product_model.dart';
import '../../services/product_api_service.dart';
import '../../services/cart_service.dart';

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

  final List<String> _banners = MockData.homeBanners;

  // ============== FLASH SALE COUNTDOWN ==============
  Timer? _countdownTimer;
  Duration _remaining = const Duration(hours: 2, minutes: 45, seconds: 12);

  // ============== VÒNG QUAY FREESHIP NỔI (trang trí) ==============
  bool _showFreeshipWheel = true;

  // ============== DATA: CATEGORIES ==============
  // Dữ liệu lấy từ lib/data/mock_data.dart -> sau này thay bằng API tại đây
  final List<Map<String, dynamic>> _categories = MockData.homeCategories;

  // ============== DATA: SẢN PHẨM (lấy từ API DummyJSON - KHÔNG dùng mock nữa) ==============
  // Toàn bộ tên, ảnh, giá của sản phẩm hiển thị trong feed "Gợi ý hôm nay" đều
  // lấy trực tiếp từ ProductApiService (API thật, có gần 200 sản phẩm), nên
  // tên / ảnh / giá luôn khớp với đúng dữ liệu sẽ hiển thị ở trang chi tiết.
  //
  // Để feed đa dạng ngành hàng (không chỉ toàn 1-2 danh mục đầu tiên), ta tải
  // MỘT LẦN một danh sách lớn hơn (_allProducts), rồi trộn xen kẽ theo danh
  // mục (round-robin) trước khi hiển thị. Việc "xem thêm" chỉ cần hiện thêm
  // sản phẩm đã có sẵn trong _allProducts (không gọi lại API), giúp cuộn mượt.
  List<Product> _allProducts = [];
  int _displayCount = 12;
  static const int _pageSize = 12;
  bool _loadingProducts = true;
  bool _isLoadingMore = false;
  String? _productsError;

  // Controller của toàn bộ trang Home, dùng để phát hiện khi người dùng
  // cuộn gần tới cuối danh sách sản phẩm -> tự động tải thêm (infinite scroll).
  final ScrollController _scrollController = ScrollController();

  List<Product> get _products => _allProducts.take(_displayCount).toList();

  @override
  void initState() {
    super.initState();

    _loadProducts();
    _scrollController.addListener(_onScroll);

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
    _scrollController.dispose();
    super.dispose();
  }

  // Tải một danh sách sản phẩm LỚN (nhiều ngành hàng khác nhau: mỹ phẩm,
  // điện thoại, thời trang, nội thất, thực phẩm...) rồi trộn xen kẽ theo
  // danh mục để feed "Gợi ý hôm nay" phong phú ngay từ đầu, thay vì chỉ
  // lặp lại 1-2 ngành hàng đầu tiên của API.
  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });
    try {
      final products = await ProductApiService.fetchProducts(limit: 100, skip: 0);
      if (!mounted) return;
      setState(() {
        _allProducts = _interleaveByCategory(products);
        _displayCount = _pageSize;
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

  // Xếp lại danh sách sản phẩm theo kiểu round-robin giữa các danh mục,
  // ví dụ: [mỹ phẩm, điện thoại, nội thất, thời trang, mỹ phẩm, điện thoại...]
  // thay vì giữ nguyên thứ tự API (vốn gom theo từng khối danh mục), để
  // feed hiển thị đa dạng ngành hàng ngay từ những sản phẩm đầu tiên.
  List<Product> _interleaveByCategory(List<Product> products) {
    final byCategory = <String, List<Product>>{};
    for (final p in products) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }
    final buckets = byCategory.values.toList();
    final result = <Product>[];
    int index = 0;
    while (result.length < products.length) {
      bool addedAny = false;
      for (final bucket in buckets) {
        if (index < bucket.length) {
          result.add(bucket[index]);
          addedAny = true;
        }
      }
      if (!addedAny) break;
      index++;
    }
    return result;
  }

  // Được gọi mỗi khi người dùng cuộn trang Home. Khi vị trí cuộn còn cách
  // đáy danh sách khoảng 400px, tự động tải thêm sản phẩm (giống hành vi
  // "infinite scroll" quen thuộc trên Shopee), thay vì bắt bấm nút.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 400;
    if (nearBottom && !_isLoadingMore && _displayCount < _allProducts.length) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _displayCount >= _allProducts.length) return;
    setState(() => _isLoadingMore = true);
    // Đợi một chút để có cảm giác mượt (giống các app tự tải thêm khi cuộn),
    // vì dữ liệu thực ra đã có sẵn trong _allProducts nên không cần gọi API.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _displayCount = (_displayCount + _pageSize).clamp(0, _allProducts.length);
      _isLoadingMore = false;
    });
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
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildWalletCheckInRow(),
                const SizedBox(height: 8),
                _buildQuickAccessIconsRow(),
                const SizedBox(height: 8),
                _buildLiveAndVideoRow(),
                const SizedBox(height: 8),
                _buildFeedGrid(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (_showFreeshipWheel) _buildFreeshipWheel(),
        ],
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
                child: AnimatedBuilder(
                  animation: CartService.instance,
                  builder: (context, _) {
                    final count = CartService.instance.totalItemCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
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

  // ================= SHOPEEPAY / ĐIỂM DANH =================
  Widget _buildWalletCheckInRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: shopeeOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: shopeeOrange, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ShopeePay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 2),
                      Text(
                        "Mở Ví - Giảm đến 100.000Đ🔥",
                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 34, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 8)),
          Expanded(
            child: Row(
              children: [
                const Text("🌙", style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Điểm danh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 2),
                      Text(
                        "Để nhận Xu!",
                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: shopeeOrange, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text("S", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  // ================= HÀNG ICON TRUY CẬP NHANH (cuộn ngang) =================
  int _quickIconPage = 0;

  Widget _buildQuickAccessIconsRow() {
    final icons = MockData.homeQuickAccessIcons;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 82,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.maxScrollExtent > 0) {
                  final page = (n.metrics.pixels / (n.metrics.maxScrollExtent)).clamp(0, 1);
                  setState(() => _quickIconPage = page > 0.5 ? 1 : 0);
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  final it = icons[index];
                  return SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: (it["color"] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(it["icon"] as IconData, color: it["color"] as Color, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          it["label"] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9.5, height: 1.15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
              final bool active = i == _quickIconPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: active ? 14 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? shopeeOrange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= SHOPEE LIVE + SHOPEE VIDEO =================
  Widget _buildLiveAndVideoRow() {
    final lives = MockData.liveStreams.take(2).toList();
    final videos = MockData.homeVideos;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMiniSection("SHOPEE LIVE", _buildLiveThumbs(lives))),
          const SizedBox(width: 8),
          Expanded(child: _buildMiniSection("SHOPEE VIDEO", _buildVideoThumbs(videos))),
        ],
      ),
    );
  }

  Widget _buildMiniSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const Icon(Icons.chevron_right, color: shopeeOrange, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildLiveThumbs(List<Map<String, dynamic>> lives) {
    return Row(
      children: List.generate(lives.length, (i) {
        final l = lives[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.network(l["thumb"] as String, fit: BoxFit.cover, width: double.infinity),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: shopeeRed, borderRadius: BorderRadius.circular(3)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, color: Colors.white, size: 6),
                          SizedBox(width: 3),
                          Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Text(
                        l["title"] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVideoThumbs(List<Map<String, dynamic>> videos) {
    return Row(
      children: List.generate(videos.length, (i) {
        final v = videos[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.network(v["thumb"] as String, fit: BoxFit.cover, width: double.infinity),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            v["views"] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ================= FEED 2 CỘT (banner quảng cáo + sản phẩm) =================
  Widget _buildFeedGrid() {
    // Đang tải sản phẩm từ API lần đầu
    if (_loadingProducts && _products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: shopeeOrange)),
      );
    }

    // Gọi API lỗi (mất mạng...) và chưa có sản phẩm nào để hiển thị
    if (_productsError != null && _products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Text(_productsError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loadProducts, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final products = _products;
    final left = <Widget>[];
    final right = <Widget>[];

    // Thẻ banner quảng cáo lớn nằm đầu cột trái, giống banner "7.7 Congrats" trong ảnh mẫu
    left.add(_buildFeedAdCard(MockData.homeFeedBanner));

    for (int i = 0; i < products.length; i++) {
      final card = _buildFeedProductCard(products[i]);
      if (i.isEven) {
        right.add(card);
      } else {
        left.add(card);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: left
                      .map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: right
                      .map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w))
                      .toList(),
                ),
              ),
            ],
          ),
          if (_isLoadingMore) _buildLoadingMoreIndicator(),
        ],
      ),
    );
  }

  // ---- Vòng xoay nhỏ tự hiện ở cuối lưới khi đang tự động tải thêm sản
  // phẩm lúc cuộn gần tới đáy (infinite scroll), không cần bấm nút. ----
  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2.4),
        ),
      ),
    );
  }

  // ---- Thẻ banner quảng cáo trong feed ----
  Widget _buildFeedAdCard(Map<String, dynamic> b) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A3D), shopeeRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.card_giftcard, size: 120, color: Colors.white.withOpacity(0.15)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        b["tag1"] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b["tag2"] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    b["badge"] as String,
                    style: const TextStyle(color: shopeeRed, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  b["title"] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                ),
                Text(
                  b["subtitle"] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Text(
                  b["discountLabel"] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      b["discountValue"] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, height: 1),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        b["discountUnit"] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  b["note"] as String,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 8.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mở trang chi tiết sản phẩm khi bấm vào 1 sản phẩm bất kỳ ----
  // Lưu ý: `p.id` ở đây là id THẬT của sản phẩm trên API (DummyJSON), không
  // còn phải "đoán" bằng cách băm tên sản phẩm nữa -> tên/ảnh/giá trong
  // trang chi tiết chắc chắn khớp với đúng sản phẩm đã bấm ở Trang chủ.
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

  // ---- Thẻ sản phẩm trong feed (kiểu Shopee) ----
  Widget _buildFeedProductCard(Product p) {
    return GestureDetector(
      onTap: () => _openProductDetail(p),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
                    ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                    : Image.network(
                        p.thumbnail,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                      ),
              ),
              if (p.discountPercent > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: shopeeRed, borderRadius: BorderRadius.circular(3)),
                    child: Text(
                      "-${p.discountPercent}%",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.25),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p.priceText,
                      style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.confirmation_num_outlined, size: 13, color: shopeeRed),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Đã bán ${p.soldText}",
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        p.location,
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
      ),
    );
  }

  // ================= VÒNG QUAY FREESHIP NỔI (trang trí, giống ảnh mẫu) =================
  Widget _buildFreeshipWheel() {
    return Positioned(
      right: 10,
      bottom: 16,
      child: SizedBox(
        width: 74,
        height: 74,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.local_shipping, color: shopeeRed, size: 26),
                    Positioned(
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: shopeeRed, borderRadius: BorderRadius.circular(3)),
                        child: const Text(
                          "FREESHIP",
                          style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: shopeeRed, shape: BoxShape.circle),
                child: const Text("1", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: GestureDetector(
                onTap: () => setState(() => _showFreeshipWheel = false),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
