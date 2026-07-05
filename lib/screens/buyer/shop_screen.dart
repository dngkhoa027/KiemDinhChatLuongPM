import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_api_service.dart';
import '../../widgets/shop_avatar.dart';
import 'product_detail_screen.dart';

/// Trang "Shop" (gian hàng ảo) — demo cho ý tưởng shop chuyên 1 ngành hàng.
///
/// Vì đây là demo dùng dữ liệu từ DummyJSON, shop được "dựng" tạm dựa trên
/// [category] của sản phẩm mà người dùng bấm vào ("Xem Shop"): mọi sản phẩm
/// cùng category sẽ được xem là "sản phẩm của shop này" -> đúng tinh thần
/// "1 shop chỉ bán 1 ngành hàng" mà bạn muốn làm cứng.
class ShopDetailScreen extends StatefulWidget {
  final String shopName;
  final String category;
  final String categoryLabel;

  const ShopDetailScreen({
    super.key,
    required this.shopName,
    required this.category,
    required this.categoryLabel,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);

  late TabController _tabController;
  late Future<List<Product>> _productsFuture;

  // Mỗi tab có ScrollController RIÊNG, không dùng chung PrimaryScrollController
  // -> tránh lỗi "ScrollController is attached to more than one ScrollPosition"
  // khi TabBarView giữ nhiều tab cùng tồn tại trong cây widget.
  final ScrollController _overviewScrollCtrl = ScrollController();
  final ScrollController _productsScrollCtrl = ScrollController();
  final ScrollController _categoryScrollCtrl = ScrollController();

  String _sort = 'popular'; // popular | newest | bestselling | price
  bool _isFollowing = false;

  // ---- Số liệu demo, sinh ổn định theo tên shop (không đổi mỗi lần rebuild) ----
  late final int _seed;
  late final int _followerCount;
  late final int _viewCount;
  late final double _rating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _productsFuture = ProductApiService.fetchSimilarProducts(
      widget.category,
      excludeId: -1,
      limit: 30,
    );

    _seed = widget.shopName.codeUnits.fold<int>(0, (a, b) => a + b) + 17;
    _followerCount = 800 + (_seed * 53) % 15000;
    _viewCount = 5000 + (_seed * 97) % 95000;
    _rating = 4.5 + (_seed % 5) / 10;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _overviewScrollCtrl.dispose();
    _productsScrollCtrl.dispose();
    _categoryScrollCtrl.dispose();
    super.dispose();
  }

  IconData get _categoryIcon {
    final c = widget.category.toLowerCase();
    if (c.contains('shirt') || c.contains('dress') || c.contains('fashion')) {
      return Icons.checkroom;
    }
    if (c.contains('phone') || c.contains('laptop') || c.contains('mobile')) {
      return Icons.devices_other;
    }
    if (c.contains('shoe') || c.contains('watch') || c.contains('sunglasses')) {
      return Icons.watch;
    }
    if (c.contains('grocer') || c.contains('food')) {
      return Icons.local_grocery_store;
    }
    if (c.contains('furniture') || c.contains('home') || c.contains('decor')) {
      return Icons.chair_outlined;
    }
    if (c.contains('beauty') || c.contains('skincare') || c.contains('fragrance')) {
      return Icons.spa_outlined;
    }
    return Icons.storefront;
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return '$n';
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — tính năng minh hoạ, chưa kết nối backend thật.')),
    );
  }

  void _openProduct(Product p) {
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
          overrideShopName: widget.shopName,
        ),
      ),
    );
  }

  List<Product> _sorted(List<Product> items) {
    final list = [...items];
    switch (_sort) {
      case 'newest':
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'bestselling':
        list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
      case 'price':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      default:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShopOverviewTab(),
                  _buildProductsTab(),
                  _buildCategoryTab(),
                  _buildLiveTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER (banner + info shop) =================
  // Bố cục: banner ngắn (chứa back/search/more) rồi 1 khối trắng bên dưới
  // chứa avatar + tên + rating + nút Theo dõi/Chat. KHÔNG overlap giữa 2
  // phần này để tránh bị chồng chữ/lệch như bản trước.
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Banner ----
          SizedBox(
            height: 108,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [shopeeOrange, shopeeRed],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -16,
                          top: -16,
                          child: Icon(_categoryIcon, size: 110, color: Colors.white.withOpacity(0.14)),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _circleIconButton(Icons.arrow_back, () => Navigator.of(context).pop()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 17, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tìm kiếm sản phẩm trong Shop',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _circleIconButton(Icons.more_vert, () => _showComingSoon('Tùy chọn khác')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- Info shop (nằm hẳn dưới banner, avatar chỉ hơi đè nhẹ lên viền) ----
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 5)],
                        ),
                        child: ShopAvatar(
                          shopName: widget.shopName,
                          radius: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.shopName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(_rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12.5)),
                    const SizedBox(width: 8),
                    Text('|', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatCount(_followerCount)} người theo dõi',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(3)),
                      child: const Text(
                        'Yêu thích+',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chuyên: ${widget.categoryLabel}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: _isFollowing
                            ? OutlinedButton(
                                onPressed: () => setState(() => _isFollowing = false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                child: const Text('Đang theo dõi', style: TextStyle(fontSize: 12.5)),
                              )
                            : ElevatedButton(
                                onPressed: () => setState(() => _isFollowing = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: shopeeOrange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: const Text('+ Theo dõi', style: TextStyle(fontSize: 12.5)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () => _showComingSoon('Chat với Shop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: shopeeOrange,
                            side: const BorderSide(color: shopeeOrange),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 14),
                          label: const Text('Chat', style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showComingSoon('Video sản phẩm'),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                            child: Icon(Icons.play_arrow, size: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 6),
                          Text('Video sản phẩm', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_formatCount(_viewCount)}+ lượt xem',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.22), shape: BoxShape.circle),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }

  // ================= TAB BAR =================
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: shopeeOrange,
        unselectedLabelColor: Colors.black87,
        indicatorColor: shopeeOrange,
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13.5),
        tabs: const [
          Tab(text: 'Shop'),
          Tab(text: 'Sản phẩm'),
          Tab(text: 'Danh mục hàng'),
          Tab(text: 'Live'),
        ],
      ),
    );
  }

  // ================= TAB 1: SHOP (tổng quan) =================
  Widget _buildShopOverviewTab() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2));
        }
        final items = snapshot.data ?? const [];
        return ListView(
          controller: _overviewScrollCtrl,
          primary: false,
          padding: const EdgeInsets.all(10),
          children: [
            _sectionHeader('Gợi ý cho bạn', onSeeAll: () => _tabController.animateTo(1)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              _emptyState('Shop chưa có sản phẩm nào.')
            else
              _productGrid(items.take(6).toList()),
            const SizedBox(height: 16),
            _buildPolicyBanner(),
            const SizedBox(height: 16),
            if (items.length > 6) ...[
              const Text('Gợi ý riêng cho bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
              const SizedBox(height: 8),
              _productGrid(items.skip(6).toList()),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text('Xem tất cả', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPolicyBanner() {
    final policies = [
      (Icons.local_shipping_outlined, 'Miễn phí\ngiao hàng'),
      (Icons.inventory_2_outlined, 'FULLBOX\nmọi đơn hàng'),
      (Icons.currency_exchange, 'Hoàn tiền\n24h'),
      (Icons.autorenew, 'Đổi trả\n7 ngày'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: policies
            .map(
              (p) => Expanded(
                child: Column(
                  children: [
                    Icon(p.$1, color: shopeeOrange, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      p.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ================= TAB 2: SẢN PHẨM =================
  Widget _buildProductsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _sortChip('Phổ biến', 'popular'),
              _sortChip('Mới nhất', 'newest'),
              _sortChip('Bán chạy', 'bestselling'),
              _sortChip('Giá', 'price'),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2));
              }
              final items = _sorted(snapshot.data ?? const []);
              if (items.isEmpty) {
                return _emptyState('Shop chưa có sản phẩm nào.');
              }
              return ListView(
                controller: _productsScrollCtrl,
                primary: false,
                padding: const EdgeInsets.all(10),
                children: [_productGrid(items)],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sortChip(String label, String value) {
    final selected = _sort == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _sort = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? shopeeOrange.withOpacity(0.08) : Colors.transparent,
            border: Border.all(color: selected ? shopeeOrange : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: selected ? shopeeOrange : Colors.black87,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ================= TAB 3: DANH MỤC HÀNG =================
  Widget _buildCategoryTab() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        return ListView(
          controller: _categoryScrollCtrl,
          primary: false,
          padding: const EdgeInsets.all(10),
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _categoryRow(
                    icon: _categoryIcon,
                    label: widget.categoryLabel,
                    count: items.length,
                    onTap: () => _tabController.animateTo(1),
                  ),
                  const Divider(height: 1, indent: 16),
                  _categoryRow(
                    icon: Icons.widgets_outlined,
                    label: 'Tất cả sản phẩm',
                    count: items.length,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Vì đây là shop chuyên ngành, mọi sản phẩm trong shop đều thuộc '
                'nhóm hàng "${widget.categoryLabel}".',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryRow({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: shopeeOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: shopeeOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
            Text('($count)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ================= TAB 4: LIVE =================
  Widget _buildLiveTab() {
    return _emptyState('Shop chưa có buổi Live nào.', icon: Icons.videocam_off_outlined);
  }

  Widget _emptyState(String text, {IconData icon = Icons.inbox_outlined}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ================= LƯỚI SẢN PHẨM (dùng chung cho các tab) =================
  Widget _productGrid(List<Product> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) => _productCard(items[index]),
    );
  }

  Widget _productCard(Product p) {
    return GestureDetector(
      onTap: () => _openProduct(p),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
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
                        '-${p.discountPercent}%',
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
                  Text(
                    p.priceText,
                    style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 11, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(p.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10.5)),
                      const SizedBox(width: 6),
                      Text('Đã bán ${p.soldText}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
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
