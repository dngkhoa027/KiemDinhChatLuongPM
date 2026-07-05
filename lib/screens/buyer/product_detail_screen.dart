import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
import '../../services/product_api_service.dart';
import '../../services/shop_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/shop_avatar.dart';
import 'cart_screen.dart';
import 'shop_screen.dart';

/// Trang chi tiết sản phẩm – dùng chung cho TẤT CẢ sản phẩm trong app.
/// Khi người dùng bấm vào bất kỳ sản phẩm nào (ở Trang chủ, Mall, Live...),
/// điều hướng tới màn hình này kèm [seedId] + dữ liệu tạm (fallback) để
/// hiển thị ngay lập tức, trong lúc màn hình gọi [ProductApiService] để
/// lấy đầy đủ thông tin sản phẩm (ảnh, mô tả, tồn kho, đánh giá...).
class ProductDetailScreen extends StatefulWidget {
  final int seedId;
  final String fallbackName;
  final String fallbackImage;
  final int fallbackPrice;
  final int fallbackOriginalPrice;
  final int fallbackDiscount;
  final double fallbackRating;
  final int fallbackSoldCount;
  final String fallbackLocation;
  // Khi mở sản phẩm này từ TRONG 1 trang Shop cụ thể, truyền tên shop đó vào
  // đây để ép sản phẩm luôn hiển thị đúng thuộc shop đang xem — tránh trường
  // hợp brand/shop do API tự sinh ra khác với shop mà người dùng đang đứng
  // trong đó (VD: đang ở shop Nike, bấm sản phẩm khác lại hiện "Adidas").
  final String? overrideShopName;

  const ProductDetailScreen({
    super.key,
    required this.seedId,
    required this.fallbackName,
    required this.fallbackImage,
    this.fallbackPrice = 0,
    this.fallbackOriginalPrice = 0,
    this.fallbackDiscount = 0,
    this.fallbackRating = 4.8,
    this.fallbackSoldCount = 0,
    this.fallbackLocation = 'TP. Hồ Chí Minh',
    this.overrideShopName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);

  late Future<Product> _productFuture;
  Future<List<Product>>? _similarFuture;

  final PageController _galleryController = PageController();
  int _galleryIndex = 0;
  int _selectedVariant = 0;
  bool _isFavorite = false;

  // ---- Theo dõi shop ----
  // Vì demo dùng sản phẩm từ DummyJSON (không có shopId thật trong Firestore),
  // shop được nhận diện bằng product.shopId nếu có (sản phẩm seller thật),
  // hoặc rơi về 1 id tạm dựa trên shopName để vẫn theo dõi/bỏ theo dõi được.
  bool _isFollowingShop = false;
  bool _followBusy = false;
  String? _shopKey;

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProduct();
  }

  String _resolveShopKey(Product product) {
    return product.shopId ?? 'demo_${product.shopName}';
  }

  Future<void> _loadFollowState(Product product) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final shopKey = _resolveShopKey(product);
    final following = await ShopService.instance.isFollowingShop(uid: uid, shopId: shopKey);
    if (!mounted) return;
    setState(() {
      _shopKey = shopKey;
      _isFollowingShop = following;
    });
  }

  Future<void> _toggleFollowShop() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _shopKey == null) {
      _showComingSoon('Theo dõi Shop');
      return;
    }
    setState(() => _followBusy = true);
    try {
      if (_isFollowingShop) {
        await ShopService.instance.unfollowShop(uid: uid, shopId: _shopKey!);
      } else {
        await ShopService.instance.followShop(uid: uid, shopId: _shopKey!);
      }
      if (!mounted) return;
      setState(() => _isFollowingShop = !_isFollowingShop);
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<Product> _loadProduct() async {
    try {
      var product = await ProductApiService.fetchProductById(
        widget.seedId,
        overrideName: widget.fallbackName,
        overrideImage: widget.fallbackImage,
        overridePrice: widget.fallbackPrice,
        overrideOriginalPrice: widget.fallbackOriginalPrice,
        overrideDiscountPercent: widget.fallbackDiscount,
      );
      if (widget.overrideShopName != null && widget.overrideShopName!.trim().isNotEmpty) {
        product = product.copyWith(shopName: widget.overrideShopName);
      }
      _similarFuture = ProductApiService.fetchSimilarProducts(
        product.category,
        excludeId: product.id,
      );
      return product;
    } catch (_) {
      // Không có mạng hoặc API lỗi -> dùng dữ liệu tạm để trang vẫn hiển thị được.
      var fallback = _fallbackProduct();
      if (widget.overrideShopName != null && widget.overrideShopName!.trim().isNotEmpty) {
        fallback = fallback.copyWith(shopName: widget.overrideShopName);
      }
      _similarFuture = Future.value(const []);
      return fallback;
    }
  }

  Product _fallbackProduct() {
    final price = widget.fallbackPrice > 0 ? widget.fallbackPrice : 99000;
    final original = widget.fallbackOriginalPrice > price ? widget.fallbackOriginalPrice : price;
    return Product(
      id: widget.seedId,
      name: widget.fallbackName,
      description:
          '${widget.fallbackName} chính hãng, chất lượng cao, được nhiều khách hàng tin dùng. '
          'Sản phẩm đóng gói cẩn thận, hỗ trợ đổi trả trong 7 ngày nếu lỗi do nhà sản xuất.\n\n'
          '(Không thể kết nối tới máy chủ sản phẩm lúc này, đang hiển thị thông tin tạm thời.)',
      price: price,
      originalPrice: original,
      discountPercent: widget.fallbackDiscount,
      rating: widget.fallbackRating,
      ratingCount: 128,
      soldCount: widget.fallbackSoldCount > 0 ? widget.fallbackSoldCount : 100,
      stock: 999,
      category: '',
      categoryLabel: 'Sản phẩm',
      brand: 'Chính Hãng',
      shopName: 'shop.chinhhang',
      location: widget.fallbackLocation,
      images: [widget.fallbackImage],
      highlights: const [],
    );
  }

  void _openShop(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(
          shopName: product.shopName.trim().isNotEmpty ? product.shopName : 'Shop',
          category: product.category,
          categoryLabel: product.categoryLabel,
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — tính năng minh hoạ, chưa kết nối backend thật.')),
    );
  }

  /// Thêm sản phẩm (với phân loại đang chọn) vào giỏ hàng dùng chung.
  /// Chỉ dừng lại ở bước đưa vào giỏ — KHÔNG điều hướng sang thanh toán.
  void _addToCart(Product product) {
    final variants = product.images.take(4).toList();
    final hasVariants = variants.length > 1;
    final safeIndex = variants.isEmpty ? 0 : _selectedVariant.clamp(0, variants.length - 1).toInt();
    final rawVariantImage = variants.isNotEmpty ? variants[safeIndex] : product.thumbnail;
    // Không để ảnh/tên trống lọt vào giỏ hàng — nếu vì lý do gì đó sản phẩm
    // không có ảnh (API lỗi, ảnh rỗng...), dùng ảnh đầu tiên còn lại hoặc
    // một placeholder, và tên mặc định thay vì chuỗi rỗng.
    final variantImage = rawVariantImage.isNotEmpty
        ? rawVariantImage
        : (product.images.isNotEmpty ? product.images.first : 'https://via.placeholder.com/150');
    final productName = product.name.trim().isNotEmpty ? product.name : 'Sản phẩm';
    final variantLabel = hasVariants ? 'Phân loại ${_selectedVariant + 1}' : 'Mặc định';

    CartService.instance.addToCart(
      shopName: product.shopName.trim().isNotEmpty ? product.shopName : 'Shop',
      image: variantImage,
      name: productName,
      variant: variantLabel,
      price: product.price,
      originalPrice: product.originalPrice,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'XEM GIỎ HÀNG',
          textColor: Colors.yellow,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                const Center(child: CircularProgressIndicator(color: shopeeOrange)),
                _buildTopBar(context, null),
              ],
            ),
          );
        }

        final product = snapshot.data ?? _fallbackProduct();
        if (_shopKey == null) {
          // Chỉ nạp trạng thái theo dõi 1 lần khi đã có dữ liệu sản phẩm thật.
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowState(product));
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGallery(product),
                    if (product.images.length > 1) _buildVariantSelector(product),
                    _buildPriceAndTitle(product),
                    _buildSPayLaterBanner(product),
                    const SizedBox(height: 8),
                    _buildShippingCard(product),
                    const SizedBox(height: 8),
                    _buildDescriptionCard(product),
                    const SizedBox(height: 8),
                    _buildShopCard(product),
                    const SizedBox(height: 8),
                    _buildRatingCard(product),
                    const SizedBox(height: 8),
                    _buildSimilarSection(product),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              _buildTopBar(context, product),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, product),
        );
      },
    );
  }

  // ================= TOP BAR (nổi trên ảnh) =================
  Widget _buildTopBar(BuildContext context, Product? product) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.35), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _circleIconButton(Icons.arrow_back, () => Navigator.of(context).pop()),
                const Spacer(),
                _circleIconButton(Icons.search, () => _showComingSoon('Tìm kiếm')),
                const SizedBox(width: 8),
                _circleIconButton(Icons.share_outlined, () => _showComingSoon('Chia sẻ')),
                const SizedBox(width: 8),
                _cartIconButtonWithBadge(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  /// Icon giỏ hàng (dạng nổi trên ảnh) có hiển thị số lượng sản phẩm,
  /// tự cập nhật khi CartService thay đổi (vd. vừa bấm "Thêm Vào Giỏ Hàng").
  Widget _cartIconButtonWithBadge({required VoidCallback onTap}) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.totalItemCount;
        return InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 19),
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1)),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ================= GALLERY ẢNH SẢN PHẨM =================
  Widget _buildGallery(Product product) {
    final images = product.images.isNotEmpty ? product.images : [''];
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _galleryController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _galleryIndex = i),
            itemBuilder: (context, index) {
              final img = images[index];
              if (img.isEmpty) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey),
                );
              }
              return Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2)),
                  );
                },
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${_galleryIndex + 1}/${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= PHÂN LOẠI SẢN PHẨM (biến thể) =================
  Widget _buildVariantSelector(Product product) {
    final variants = product.images.take(4).toList();
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${variants.length} phân loại có sẵn', style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: variants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedVariant;
                return InkWell(
                  onTap: () => setState(() => _selectedVariant = index),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: selected ? shopeeOrange : Colors.grey.shade300, width: selected ? 1.6 : 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      variants[index],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= BANNER SPAYLATER =================
  Widget _buildSPayLaterBanner(Product product) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(3)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('SPayLater', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Text('0%', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kích hoạt nhận ngay 150.000Đ',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ================= GIÁ + TÊN SẢN PHẨM + ĐÁNH GIÁ =================
  Widget _buildPriceAndTitle(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.priceText,
                style: const TextStyle(color: shopeeOrange, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (product.discountPercent > 0) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    product.originalPriceText,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13.5,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(3)),
                  child: Text(
                    '-${product.discountPercent}%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _isFavorite = !_isFavorite),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? shopeeRed : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 12, color: Color(0xFF2E9E5B)),
                    SizedBox(width: 2),
                    Text('Freeship Xtra', style: TextStyle(fontSize: 10.5, color: Color(0xFF2E9E5B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 3),
              ...List.generate(5, (i) {
                final filled = i < product.rating.round();
                return Icon(filled ? Icons.star : Icons.star_border, size: 14, color: Colors.orange);
              }),
              const SizedBox(width: 8),
              Container(width: 1, height: 12, color: Colors.grey.shade300),
              const SizedBox(width: 8),
              Text('${product.ratingCount} Đánh Giá', style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              const SizedBox(width: 8),
              Container(width: 1, height: 12, color: Colors.grey.shade300),
              const SizedBox(width: 8),
              Text('Đã Bán ${product.soldText}', style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= VẬN CHUYỂN / VOUCHER / BẢO HIỂM =================
  Widget _buildShippingCard(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          _infoRow(Icons.local_shipping_outlined, 'Vận Chuyển', 'Giao đến ${product.location} · Dự kiến nhận hàng 3-5 ngày'),
          const Divider(height: 18),
          _infoRow(Icons.confirmation_number_outlined, 'Voucher', 'Giảm 10K · Giảm 15% Giảm Tối Đa 20K'),
          const Divider(height: 18),
          _infoRow(Icons.verified_user_outlined, 'Bảo Hiểm', 'Shopee đảm bảo hàng chính hãng, hoàn tiền nếu phát hiện hàng giả'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12.5, height: 1.3)),
        ),
        Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
      ],
    );
  }

  // ================= MÔ TẢ SẢN PHẨM =================
  Widget _buildDescriptionCard(Product product) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHI TIẾT SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 10),
          if (product.highlights.isNotEmpty) ...[
            ...product.highlights.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E9E5B)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(h, style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          const Text('Mô Tả Sản Phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 8),
          Text(product.description, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  // ================= THÔNG TIN SHOP =================
  Widget _buildShopCard(Product product) {
    final productCount = 150 + (product.id * 37) % 400;
    final responseRate = 45 + (product.id * 7) % 50;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openShop(product),
                child: ShopAvatar(
                  shopName: product.shopName,
                  radius: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openShop(product),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: Color(0xFF2E9E5B), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          const Text('Online', style: TextStyle(color: Colors.grey, fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 30,
                    child: _isFollowingShop
                        ? OutlinedButton(
                            onPressed: _followBusy ? null : _toggleFollowShop,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Đang theo dõi', style: TextStyle(fontSize: 12)),
                          )
                        : ElevatedButton(
                            onPressed: _followBusy ? null : _toggleFollowShop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shopeeOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              elevation: 0,
                            ),
                            child: const Text('+ Theo dõi', style: TextStyle(fontSize: 12)),
                          ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _openShop(product),
                    child: const Text(
                      'Xem Shop',
                      style: TextStyle(color: shopeeOrange, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _shopStat(product.rating.toStringAsFixed(1), 'Đánh giá')),
              _shopStatDivider(),
              Expanded(child: _shopStat('$productCount', 'Sản phẩm')),
              _shopStatDivider(),
              Expanded(child: _shopStat('$responseRate%', 'Phản hồi Chat')),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Các sản phẩm khác của Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Product>>(
            future: _similarFuture,
            builder: (context, snapshot) {
              final items = snapshot.data ?? const [];
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2)),
                );
              }
              if (items.isEmpty) {
                return const Text('Chưa có sản phẩm khác.', style: TextStyle(color: Colors.grey, fontSize: 12.5));
              }
              return SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _buildShopProductCard(items[index], product.shopName),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shopStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
      ],
    );
  }

  Widget _shopStatDivider() => Container(width: 1, height: 30, color: Colors.grey.shade300);

  Widget _buildShopProductCard(Product p, String shopName) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
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
              overrideShopName: shopName,
            ),
          ),
        );
      },
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: p.thumbnail.isEmpty
                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                  : Image.network(
                      p.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(p.priceText, style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ĐÁNH GIÁ SẢN PHẨM =================
  Widget _buildRatingCard(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ĐÁNH GIÁ SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('Xem tất cả >', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(product.rating.toStringAsFixed(1), style: const TextStyle(color: shopeeOrange, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < product.rating.round();
                      return Icon(filled ? Icons.star : Icons.star_border, size: 16, color: Colors.orange);
                    }),
                  ),
                  const SizedBox(height: 2),
                  Text('${product.ratingCount} lượt đánh giá', style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 24),
          ..._mockReviews(product).map(_buildReviewTile),
        ],
      ),
    );
  }

  // Đánh giá minh hoạ (chưa có API đánh giá thật) để giao diện hiển thị đầy đủ.
  List<_Review> _mockReviews(Product product) {
    final names = ['yho3orz06y', 's0nu1earob', 'ngan.tran88', 'khanhlinh_'];
    final comments = [
      'Hàng đã nhận, đóng gói cẩn thận, giao nhanh hơn dự kiến. Sản phẩm dùng khá ổn so với giá tiền.',
      'Chất lượng tạm ổn, nhưng màu sắc hơi khác so với hình. Shop phản hồi nhiệt tình.',
      'Rất ưng ý, sẽ ủng hộ shop lần sau. Đóng gói chắc chắn không lo vỡ.',
      'Sản phẩm đúng mô tả, dùng thử vài hôm thấy ổn định, đáng tiền.',
    ];
    final stars = [5, 1, 5, 4];
    return List.generate(2, (i) {
      return _Review(name: names[i], stars: stars[i], comment: comments[i]);
    });
  }

  Widget _buildReviewTile(_Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              review.name.isNotEmpty ? review.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(review.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Icon(Icons.thumb_up_alt_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('Hữu ích (0)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: List.generate(5, (i) => Icon(
                        i < review.stars ? Icons.star : Icons.star_border,
                        size: 13,
                        color: Colors.orange,
                      )),
                ),
                const SizedBox(height: 6),
                Text(review.comment, style: const TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SẢN PHẨM TƯƠNG TỰ =================
  Widget _buildSimilarSection(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CÓ THỂ BẠN CŨNG THÍCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          FutureBuilder<List<Product>>(
            future: _similarFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2)),
                );
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có sản phẩm gợi ý.', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) => _buildSimilarCard(items[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarCard(Product p) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
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
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: p.thumbnail.isEmpty
                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                  : Image.network(
                      p.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(p.priceText, style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= THANH DƯỚI CÙNG =================
  Widget _buildBottomBar(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _bottomIconButton(Icons.storefront_outlined, 'Shop', () => _showComingSoon('Xem Shop')),
              _bottomIconButton(Icons.chat_bubble_outline, 'Chat', () => _showComingSoon('Chat với Shop')),
              _bottomCartIconButton(
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopeeCartPage())),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _addToCart(product),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: shopeeOrange,
                    side: const BorderSide(color: shopeeOrange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(4))),
                  ),
                  child: const FittedBox(child: Text('Thêm Vào Giỏ Hàng')),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showComingSoon('Mua ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shopeeOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(4))),
                  ),
                  child: const Text('Mua Ngay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomIconButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  /// Giống [_bottomIconButton] nhưng dành riêng cho icon "Giỏ Hàng", có
  /// hiển thị số lượng sản phẩm và tự cập nhật theo CartService.
  Widget _bottomCartIconButton(VoidCallback onTap) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.totalItemCount;
        return InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.grey.shade700),
                    if (count > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 15),
                          decoration: const BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.all(Radius.circular(8))),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Giỏ Hàng', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cấu trúc dữ liệu đánh giá minh hoạ, dùng nội bộ cho màn hình này.
class _Review {
  final String name;
  final int stars;
  final String comment;

  const _Review({required this.name, required this.stars, required this.comment});
}
