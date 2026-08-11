import 'dart:async';
import 'package:flutter/material.dart';
import '../shared/profile_screen.dart';
import '../shared/notification_screen.dart';
import 'mall_screen.dart';
import 'live_watch_screen.dart';
import 'live_feed_screen.dart';
import 'cart_screen.dart';
import 'chat_list_screen.dart';
import 'product_detail_screen.dart';
import 'product_search_screen.dart';
import 'qr_scan_screen.dart';
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

  int _currentIndex = 0;

  Timer? _countdownTimer;
  Duration _remaining = const Duration(hours: 2, minutes: 45, seconds: 12);

  bool _showFreeshipWheel = true;

  final List<Map<String, dynamic>> _categories = MockData.homeCategories;

  List<Product> _allProducts = [];
  int _displayCount = 12;
  static const int _pageSize = 12;
  bool _loadingProducts = true;
  bool _isLoadingMore = false;
  String? _productsError;

  final ScrollController _scrollController = ScrollController();

  List<Product> get _products => _allProducts.take(_displayCount).toList();

  int _quickIconPage = 0;

  // Gợi ý tìm kiếm xoay vòng (giống Shopee)
  final List<String> _searchHints = const [
    'De Basé',
    'Áo Thun',
    'Giày Adidas',
    'iPhone 17',
    'Son môi',
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);

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

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _searchHints.length);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hintTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

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
      const SizedBox.shrink(),
      const ShopeeNotificationPage(),
      const ShopeeProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Tab Live — mở livestream như ban đầu
            final streams = MockData.liveStreams;
            if (streams.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LiveFeedScreen(),
                  fullscreenDialog: true,
                ),
              );
            }
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: shopeeOrange,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Mall',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Live & Video',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: const Text('13', style: TextStyle(fontSize: 10)),
              backgroundColor: shopeeOrange,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Tôi',
          ),
        ],
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
        await _loadProducts();
      },
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header cam + card ShopeePay nổi đè nhẹ (giống Shopee thật)
              SliverToBoxAdapter(child: _buildHeaderWithWallet()),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    _buildQuickAccessIconsRow(),
                    const SizedBox(height: 8),
                    _buildLiveAndVideoRow(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: _buildFeedGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          if (_showFreeshipWheel) _buildFreeshipWheel(),
        ],
      ),
    );
  }

  // ================= HEADER + SHOPEEPAY (giống ảnh Shopee) =================
  Widget _buildHeaderWithWallet() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: shopeeOrange,
          padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductSearchScreen(initialHint: _searchHints[_hintIndex]),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 280),
                                      child: Align(
                                        key: ValueKey(_hintIndex),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _searchHints[_hintIndex],
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const QrScanScreen()),
                            ),
                            child: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600, size: 22),
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
                                right: -6,
                                top: -5,
                                child: _yellowBadge(count > 99 ? '99+' : '$count'),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatListScreen()),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                        Positioned(
                          right: -6,
                          top: -5,
                          child: _yellowBadge('19'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Chừa khoảng cam để card ShopeePay đè lên (giống ảnh)
              const SizedBox(height: 16),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: _buildWalletCheckInRow(),
        ),
      ],
    );
  }

  Widget _yellowBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: shopeeOrange, width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWalletCheckInRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(8, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code_2, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: shopeeOrange,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ShopeePay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      Text(
                        'Giảm đến 40.000Đ mua sắm mỗi ngày...',
                        style: TextStyle(fontSize: 9.5, color: Colors.grey, height: 1.15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: Color(0xFFEEEEEE), margin: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🪙', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm danh',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                      ),
                      Text(
                        'Để Nhận Xu!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(fontSize: 9.5, color: Colors.grey, height: 1.15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: Color(0xFFEEEEEE), margin: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(Icons.credit_card, color: shopeeOrange, size: 14),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SPayLater', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      Text(
                        'Kích hoạt nhận voucher 150.000Đ',
                        style: TextStyle(fontSize: 9.5, color: Colors.grey, height: 1.15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: shopeeOrange, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  // ================= ICON TRUY CẬP NHANH =================
  Widget _buildQuickAccessIconsRow() {
    // Icons bám sát ảnh: ShopeeFood, Shopee Mart, ShopeeVIP, Deal Từ 1.000Đ, ...
    final icons = <Map<String, dynamic>>[
      {
        'label': 'ShopeeFood\nFlash Sale 50%',
        'icon': Icons.restaurant,
        'color': shopeeOrange,
        'bg': const Color(0xFFFFE8E2),
      },
      {
        'label': 'Shopee Mart',
        'icon': Icons.shopping_basket_outlined,
        'color': const Color(0xFF26A69A),
        'bg': const Color(0xFFE0F2F1),
      },
      {
        'label': 'ShopeeVIP',
        'icon': Icons.workspace_premium_outlined,
        'color': const Color(0xFF7B1FA2),
        'bg': const Color(0xFFF3E5F5),
      },
      {
        'label': 'Deal Từ 1.000Đ',
        'icon': Icons.local_offer_outlined,
        'color': const Color(0xFFFF8F00),
        'bg': const Color(0xFFFFF3E0),
        'badge': 'SHOPEE\nSIÊU RẺ',
      },
      {
        'label': 'Shopee\nXu Hướng',
        'icon': Icons.trending_up,
        'color': shopeeOrange,
        'bg': const Color(0xFFFFE8E2),
      },
      {
        'label': 'Mã Giảm Giá',
        'icon': Icons.confirmation_number_outlined,
        'color': shopeeRed,
        'bg': const Color(0xFFFFEBEE),
      },
      {
        'label': 'Săn Xu',
        'icon': Icons.monetization_on_outlined,
        'color': const Color(0xFFFFA000),
        'bg': const Color(0xFFFFF8E1),
      },
      {
        'label': 'Live Hot',
        'icon': Icons.live_tv,
        'color': shopeeRed,
        'bg': const Color(0xFFFFEBEE),
      },
    ];

    // Dùng list icons chuẩn Shopee (không phụ thuộc MockData để đồng bộ UI)
    final useIcons = icons;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 86,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.maxScrollExtent > 0) {
                  final page = (n.metrics.pixels / n.metrics.maxScrollExtent).clamp(0.0, 1.0);
                  final next = page > 0.5 ? 1 : 0;
                  if (next != _quickIconPage) {
                    setState(() => _quickIconPage = next);
                  }
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: useIcons.length,
                itemBuilder: (context, index) {
                  final it = useIcons[index];
                  final color = (it['color'] as Color?) ?? shopeeOrange;
                  final bg = (it['bg'] as Color?) ?? color.withValues(alpha: 0.12);
                  final label = it['label'] as String? ?? '';
                  final iconData = it['icon'] as IconData? ?? Icons.apps;

                  return SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(iconData, color: color, size: 24),
                            ),
                            if (it['badge'] != null)
                              Positioned(
                                top: -6,
                                right: -10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    it['badge'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      height: 1.05,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, height: 1.15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Page indicator (thanh cam mỏng)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
              final active = i == _quickIconPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: active ? 14 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: active ? shopeeOrange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
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
          Expanded(child: _buildMiniSection('SHOPEE LIVE', _buildLiveThumbs(lives))),
          const SizedBox(width: 8),
          Expanded(child: _buildMiniSection('SHOPEE VIDEO', _buildVideoThumbs(videos))),
        ],
      ),
    );
  }

  Widget _buildMiniSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: shopeeOrange,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
              const Icon(Icons.chevron_right, color: shopeeOrange, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildLiveThumbs(List<Map<String, dynamic>> lives) {
    if (lives.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('Chưa có live', style: TextStyle(color: Colors.grey, fontSize: 12))));
    }
    return Row(
      children: List.generate(lives.length.clamp(0, 2), (i) {
        final l = lives[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.network(
                      l['thumb'] as String? ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(color: Colors.grey.shade300),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: shopeeRed, borderRadius: BorderRadius.circular(3)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 6),
                          SizedBox(width: 3),
                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                        l['title'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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
    if (videos.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('Chưa có video', style: TextStyle(color: Colors.grey, fontSize: 12))));
    }
    return Row(
      children: List.generate(videos.length.clamp(0, 2), (i) {
        final v = videos[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.network(
                      v['thumb'] as String? ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(color: Colors.grey.shade300),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
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
                            v['views'] as String? ?? '0',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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

  // ================= FEED 2 CỘT =================
  Widget _buildFeedGrid() {
    if (_loadingProducts && _products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: shopeeOrange)),
      );
    }

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

    left.add(_buildFeedAdCard());

    for (int i = 0; i < products.length; i++) {
      final card = _buildFeedProductCard(products[i], index: i);
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

  // ---- Banner quảng cáo kiểu Casper 8.8 ----
  Widget _buildFeedAdCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('ShopeeMall', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFF53D2D)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('8.8', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('CÒN 2 NGÀY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFFEB3B), borderRadius: BorderRadius.circular(4)),
                  child: const Text('FREESHIP 0Đ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(height: 16),
                const Text('Casper', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, height: 1.1)),
                const Text('BÙNG NỔ 8.8', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, height: 1.2)),
                const SizedBox(height: 2),
                const Text(
                  'CASPER MÁT LẠNH, DEAL CHÁY SÀN!',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildAdBadge('BẢO HÀNH\nCHÍNH HÃNG'),
                    const SizedBox(width: 6),
                    _buildAdBadge('LẮP ĐẶT\n0Đ'),
                    const SizedBox(width: 6),
                    _buildAdBadge('GIAO HÀNG\nMIỄN PHÍ'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '(*) Chỉ áp dụng cho một số sản phẩm thuộc ngành hàng điện lạnh.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBadge(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1.2),
        ),
      ),
    );
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

  // ---- Thẻ sản phẩm (giống ảnh Shopee) ----
  Widget _buildFeedProductCard(Product p, {int index = 0}) {
    final showLive = index % 3 == 0;
    final showPreferred = index % 4 == 1;

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
            // Ảnh + badge giảm giá
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
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        ),
                ),
                if (p.discountPercent > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: const BoxDecoration(
                        color: shopeeRed,
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(6)),
                      ),
                      child: Text(
                        '-${p.discountPercent}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng badge 8.8 / VOUCHER XTRA / SHOPEE STYLE
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      _promoBadge('8.8', const Color(0xFFEE4D2D), Colors.white),
                      _promoBadge('VOUCHER XTRA', const Color(0xFFFF6D00), Colors.white),
                      _promoBadge('SHOPEE STYLE', const Color(0xFF1565C0), Colors.white),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Tên + LIVE / Yêu thích+
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLive)
                        Container(
                          margin: const EdgeInsets.only(top: 1, right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: shopeeRed, borderRadius: BorderRadius.circular(3)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 5, color: Colors.white),
                              SizedBox(width: 2),
                              Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else if (showPreferred)
                        Container(
                          margin: const EdgeInsets.only(top: 1, right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFFFB74D)),
                          ),
                          child: const Text('Yêu thích+', style: TextStyle(color: Color(0xFFE65100), fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, height: 1.25, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Tag Rẻ Vô Địch / SPayLater
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: [
                      _outlineTag('Rẻ Vô Địch', const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                      _outlineTag('SPayLater 0%', const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Giá + đã bán (tránh overflow khi giá dài)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          p.priceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.monetization_on, size: 13, color: Color(0xFFFFC107)),
                      const SizedBox(width: 6),
                      Text(
                        'Đã bán ${p.soldText}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Shipping
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 12, color: Color(0xFF26A69A)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Ngày mai',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF26A69A)),
                              ),
                              TextSpan(
                                text: ' | ${p.location}',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          maxLines: 1,
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

  Widget _promoBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 8.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _outlineTag(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // ================= VÒNG QUAY FREESHIP =================
  Widget _buildFreeshipWheel() {
    return Positioned(
      right: 12,
      bottom: 20,
      child: SizedBox(
        width: 68,
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
              ),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.local_shipping, color: shopeeRed, size: 24),
                    Positioned(
                      bottom: 2,
                      child: Text(
                        'FREESHIP',
                        style: TextStyle(color: shopeeRed, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: shopeeRed, shape: BoxShape.circle),
                child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              right: -3,
              top: -3,
              child: GestureDetector(
                onTap: () => setState(() => _showFreeshipWheel = false),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
