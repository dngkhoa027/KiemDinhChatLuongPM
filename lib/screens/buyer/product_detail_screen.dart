import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product_model.dart';
import '../../services/product_api_service.dart';
import '../../services/shop_service.dart';
import '../../services/cart_service.dart';
import '../../data/mock_data.dart';
import '../../widgets/shop_avatar.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'shop_screen.dart';
import 'shop_chat_screen.dart';
import 'product_search_screen.dart';

/// Trang chi tiết sản phẩm – giao diện bám sát Shopee thật (2025/2026).
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
    this.fallbackRating = 4.9,
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
  int _selectedColor = 0;
  int _selectedSize = 0;
  int _buyNowQuantity = 1;
  bool _isFavorite = false;

  // ---- Theo dõi shop ----
  bool _isFollowingShop = false;
  bool _followBusy = false;
  String? _shopKey;

  // ---- Tìm kiếm trong đánh giá ----
  final TextEditingController _reviewSearchCtrl = TextEditingController();
  String _reviewSearchQuery = '';

  // Expandable sections
  bool _sizeGuideExpanded = false;
  bool _specExpanded = false;
  bool _guaranteeExpanded = false;

  final List<String> _colors = const ['Đen', 'Trắng', 'Xám', 'Be'];
  final List<String> _sizes = const ['M', 'L', 'XL'];

  // ---- Đếm ngược VOUCHER XTRA ----
  // Thời gian đếm ngược ban đầu (giờ:phút:giây). Khi về 0, tự động lặp lại
  // (giống Shopee thật, khung giờ voucher lặp lại theo khung giờ tiếp theo).
  Duration _voucherRemaining = const Duration(hours: 0, minutes: 59, seconds: 44);
  Timer? _voucherTimer;

  void _startVoucherCountdown() {
    _voucherTimer?.cancel();
    _voucherTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_voucherRemaining.inSeconds <= 0) {
          // Hết giờ -> lặp lại một khung giờ mới (2 tiếng) như đợt voucher kế tiếp.
          _voucherRemaining = const Duration(hours: 2);
        } else {
          _voucherRemaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  /// Nhóm danh mục sản phẩm dùng để chọn ĐÚNG bộ bình luận / phân loại /
  /// ảnh minh hoạ cho phần "Đánh Giá Sản Phẩm" — tránh tình trạng sản phẩm
  /// điện tử nhưng review lại ghi "Áo quần vải đẹp" như trước đây.
  String _reviewCategoryGroup(Product product) {
    final slug = product.category.toLowerCase();
    const slugMap = {
      'mens-shirts': 'apparel',
      'tops': 'apparel',
      'womens-dresses': 'apparel',
      'mens-shoes': 'shoes',
      'womens-shoes': 'shoes',
      'mens-watches': 'accessories',
      'womens-watches': 'accessories',
      'sunglasses': 'accessories',
      'womens-bags': 'accessories',
      'womens-jewellery': 'accessories',
      'laptops': 'electronics',
      'smartphones': 'electronics',
      'tablets': 'electronics',
      'mobile-accessories': 'electronics',
      'beauty': 'beauty',
      'fragrances': 'beauty',
      'skin-care': 'beauty',
      'skincare': 'beauty',
      'furniture': 'home',
      'home-decoration': 'home',
      'kitchen-accessories': 'home',
      'groceries': 'food',
      'motorcycle': 'vehicle',
      'vehicle': 'vehicle',
      'sports-accessories': 'sports',
    };
    if (slugMap.containsKey(slug)) return slugMap[slug]!;

    // Fallback theo từ khoá (dùng cho sản phẩm seller tự đăng, không có
    // category slug chuẩn từ API).
    final text = '${product.category} ${product.categoryLabel} ${product.name}'.toLowerCase();
    const keywordGroups = {
      'electronics': ['laptop', 'phone', 'smartphone', 'iphone', 'ipad', 'tablet', 'macbook', 'tai nghe', 'headphone', 'earphone', 'sạc', 'điện thoại', 'máy tính'],
      'beauty': ['beauty', 'cosmetic', 'makeup', 'skincare', 'fragrance', 'perfume', 'mỹ phẩm', 'son', 'phấn', 'kem', 'serum', 'dưỡng', 'nước hoa'],
      'shoes': ['giày', 'dép', 'sneaker', 'shoes', 'sandal', 'boot'],
      'accessories': ['đồng hồ', 'watch', 'kính mát', 'sunglasses', 'túi xách', 'bag', 'trang sức', 'jewellery'],
      'home': ['nội thất', 'furniture', 'gia dụng', 'trang trí', 'nhà bếp', 'kitchen', 'home'],
      'food': ['thực phẩm', 'đồ ăn', 'đồ uống', 'food', 'drink', 'grocery'],
      'vehicle': ['xe máy', 'ô tô', 'vehicle', 'motorcycle', 'moto'],
      'sports': ['thể thao', 'sport', 'fitness', 'gym', 'dumbbell'],
      'apparel': ['áo', 'quần', 'váy', 'dress', 'shirt', 'hoodie', 'jacket', 'thời trang'],
    };
    for (final entry in keywordGroups.entries) {
      if (entry.value.any((k) => text.contains(k))) return entry.key;
    }
    return 'other';
  }

  /// Chỉ hiện Màu sắc / Kích cỡ với sản phẩm thời trang (quần áo, giày...).
  /// Thiết bị điện tử, mỹ phẩm, đồ gia dụng... → KHÔNG hiện.
  bool _isApparel(Product product) {
    final cat = '${product.category} ${product.categoryLabel} ${product.name}'.toLowerCase();

    // Loại trừ rõ ràng: điện tử, mỹ phẩm, thực phẩm, nội thất...
    const exclude = [
      'laptop', 'phone', 'smartphone', 'iphone', 'ipad', 'tablet', 'macbook',
      'computer', 'pc', 'monitor', 'keyboard', 'mouse', 'headphone', 'earphone',
      'camera', 'tv', 'television', 'speaker', 'watch', 'smartwatch',
      'điện thoại', 'máy tính', 'laptop', 'tai nghe', 'đồng hồ',
      'beauty', 'cosmetic', 'makeup', 'skincare', 'fragrance', 'perfume',
      'mỹ phẩm', 'son', 'phấn', 'kem', 'serum', 'dưỡng', 'trang điểm',
      'furniture', 'home', 'kitchen', 'grocery', 'food', 'drink',
      'nội thất', 'gia dụng', 'thực phẩm', 'đồ ăn', 'đồ uống',
      'vehicle', 'motorcycle', 'car', 'xe', 'moto',
      'sport', 'fitness', 'dumbbell', 'thể thao',
      'book', 'sách', 'stationery', 'văn phòng phẩm',
      'pet', 'thú cưng', 'toy', 'đồ chơi',
      'lenovo', 'apple', 'samsung', 'xiaomi', 'asus', 'dell', 'hp', 'acer',
    ];
    if (exclude.any((k) => cat.contains(k))) return false;

    // Chỉ nhận diện thời trang / quần áo / giày dép
    const apparel = [
      'shirt', 't-shirt', 'tshirt', 'dress', 'hoodie', 'jacket', 'jeans',
      'skirt', 'blouse', 'sweater', 'coat', 'pants', 'shorts', 'legging',
      'underwear', 'socks', 'shoes', 'sneakers', 'sandal', 'boot',
      'clothing', 'apparel', 'fashion', 'womens-', 'mens-', 'tops',
      'áo', 'quần', 'giày', 'dép', 'vớ', 'hoodie', 'jacket', 'váy',
      'thời trang', 'phụ kiện thời trang', 'balo', 'túi xách',
    ];
    return apparel.any((k) => cat.contains(k));
  }

  /// Rating hiển thị (đẩy lên cao một chút cho đẹp giống Shopee thật).
  double _displayRating(Product product) {
    final r = product.rating;
    if (r <= 0) return 4.9;
    if (r < 4.5) return (r + 0.4).clamp(4.5, 5.0);
    if (r < 4.8) return (r + 0.15).clamp(4.7, 5.0);
    return r.clamp(0.0, 5.0);
  }

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProduct();
    _startVoucherCountdown();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    _voucherTimer?.cancel();
    _reviewSearchCtrl.dispose();
    super.dispose();
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
      rating: widget.fallbackRating > 0 ? widget.fallbackRating.clamp(4.7, 5.0) : 4.9,
      ratingCount: 1280,
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

  void _openChat(Product product) {
    final shopName = product.shopName.trim().isNotEmpty ? product.shopName : 'Shop';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopChatScreen(
          shopName: shopName,
          initialProduct: product,
        ),
      ),
    );
  }

  // ================= CHIA SẺ SẢN PHẨM =================

  /// Link sản phẩm dùng để chia sẻ (demo). Khi có domain/app link thật,
  /// chỉ cần đổi lại chuỗi này.
  String _productShareLink(Product product) => 'https://shopee.vn/product/${product.id}';

  String _productShareText(Product product) =>
      '${product.name}\nGiá chỉ ₫${_formatVnd(product.price)} — xem ngay trên Shopee!\n${_productShareLink(product)}';

  /// Mở URL bên ngoài (link chia sẻ tới Facebook, Zalo, Telegram, WhatsApp...).
  /// Nếu máy không cài app tương ứng, trình duyệt/mobile OS sẽ tự xử lý fallback.
  Future<void> _launchShareUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được ứng dụng, vui lòng thử lại.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng, vui lòng thử lại.')),
      );
    }
  }

  Future<void> _copyShareLink(Product product) async {
    await Clipboard.setData(ClipboardData(text: _productShareLink(product)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết sản phẩm')),
    );
  }

  /// Mở khung chia sẻ hệ thống (native OS share sheet) — đúng cái khay
  /// "Chia sẻ tới..." mà điện thoại (iOS/Android) hiển thị, liệt kê tất cả
  /// app đã cài (Zalo, Messenger, Gmail, Instagram, Lưu vào Ghi chú...).
  Future<void> _openSystemShareSheet(Product product) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _productShareText(product),
      subject: product.name,
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  void _openShareSheet(Product? product) {
    if (product == null) {
      _showComingSoon('Chia sẻ');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ShareBottomSheet(
        product: product,
        shopeeOrange: shopeeOrange,
        onFacebook: () => _launchShareUrl(
          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_productShareLink(product))}',
        ),
        onMessenger: () => _launchShareUrl(
          'fb-messenger://share?link=${Uri.encodeComponent(_productShareLink(product))}',
        ),
        onZalo: () => _launchShareUrl(
          'https://zalo.me/share?u=${Uri.encodeComponent(_productShareLink(product))}&t=${Uri.encodeComponent(product.name)}',
        ),
        onWhatsApp: () => _launchShareUrl(
          'https://wa.me/?text=${Uri.encodeComponent(_productShareText(product))}',
        ),
        onTelegram: () => _launchShareUrl(
          'https://t.me/share/url?url=${Uri.encodeComponent(_productShareLink(product))}&text=${Uri.encodeComponent(product.name)}',
        ),
        onCopyLink: () => _copyShareLink(product),
        onMore: () => _openSystemShareSheet(product),
      ),
    );
  }

  /// Thêm sản phẩm (với phân loại đang chọn) vào giỏ hàng dùng chung.
  void _addToCart(Product product) {
    final variants = product.images.take(4).toList();
    final safeIndex = variants.isEmpty ? 0 : _selectedColor.clamp(0, variants.length - 1).toInt();
    final rawVariantImage = variants.isNotEmpty ? variants[safeIndex] : product.thumbnail;
    final variantImage = rawVariantImage.isNotEmpty
        ? rawVariantImage
        : (product.images.isNotEmpty ? product.images.first : 'https://via.placeholder.com/150');
    final productName = product.name.trim().isNotEmpty ? product.name : 'Sản phẩm';
    final colorLabel = _colors[_selectedColor.clamp(0, _colors.length - 1)];
    final sizeLabel = _sizes[_selectedSize.clamp(0, _sizes.length - 1)];
    final variantLabel = '$colorLabel,$sizeLabel';

    CartService.instance.addToCart(
      shopName: product.shopName.trim().isNotEmpty ? product.shopName : 'Shop',
      image: variantImage,
      name: productName,
      variant: variantLabel,
      price: product.price,
      originalPrice: product.originalPrice,
      quantity: 1,
      category: product.category,
    );

    _showAddedToCartSnackBar(
      imageUrl: variantImage,
      productName: productName,
      location: product.location,
    );
  }

  /// Snackbar đẹp, kiểu Shopee: nền trắng, thumbnail SP, icon check, nút cam.
  void _showAddedToCartSnackBar({
    required String imageUrl,
    required String productName,
    required String location,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail + check badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined, size: 22, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF26A69A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Text
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã thêm vào giỏ hàng',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Phí vận chuyển 0đ · $location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Nút Xem giỏ hàng
              Material(
                color: shopeeOrange,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      'XEM GIỎ HÀNG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet "Mua ngay" — Shopee luôn hiện sheet này trước khi vào
  /// trang thanh toán, để người mua xác nhận số lượng và (nếu sản phẩm
  /// thời trang) chọn màu sắc / kích cỡ ngay tại đây.
  void _showBuyNowSheet(Product product) {
    final isApparel = _isApparel(product);
    _buyNowQuantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            void updateBoth(VoidCallback fn) {
              sheetSetState(fn);
              setState(fn);
            }

            final maxStock = product.stock > 0 ? product.stock : 999;
            final variantImage = product.images.isNotEmpty
                ? product.images[_selectedColor.clamp(0, product.images.length - 1)]
                : product.thumbnail;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---- Ảnh + giá + nút đóng ----
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                variantImage,
                                width: 78,
                                height: 78,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Container(width: 78, height: 78, color: Colors.grey.shade200),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        product.priceText,
                                        style: const TextStyle(
                                          color: shopeeOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                        ),
                                      ),
                                      if (product.originalPrice > product.price) ...[
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 3),
                                          child: Text(
                                            product.originalPriceText,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Kho: $maxStock', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                  if (isApparel) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Đã chọn: ${_colors[_selectedColor.clamp(0, _colors.length - 1)]}, '
                                      '${_sizes[_selectedSize.clamp(0, _sizes.length - 1)]}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // ---- Màu sắc + Kích cỡ (chỉ với sản phẩm thời trang) ----
                      if (isApparel) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MÀU SẮC',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_colors.length, (i) {
                                  final selected = i == _selectedColor;
                                  return GestureDetector(
                                    onTap: () => updateBoth(() => _selectedColor = i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: selected ? const Color(0xFFFFF0EB) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: selected ? shopeeOrange : Colors.grey.shade300,
                                          width: selected ? 1.4 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        _colors[i],
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: selected ? shopeeOrange : Colors.black87,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 14),
                              const Text('KÍCH CỠ',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_sizes.length, (i) {
                                  final selected = i == _selectedSize;
                                  return GestureDetector(
                                    onTap: () => updateBoth(() => _selectedSize = i),
                                    child: Container(
                                      width: 48,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected ? const Color(0xFFFFF0EB) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: selected ? shopeeOrange : Colors.grey.shade300,
                                          width: selected ? 1.4 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        _sizes[i],
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: selected ? shopeeOrange : Colors.black87,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],

                      // ---- Số lượng ----
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số lượng', style: TextStyle(fontSize: 14)),
                            Row(
                              children: [
                                _qtyButton(
                                  icon: Icons.remove,
                                  onTap: _buyNowQuantity > 1
                                      ? () => sheetSetState(() => _buyNowQuantity--)
                                      : null,
                                ),
                                Container(
                                  width: 44,
                                  alignment: Alignment.center,
                                  child: Text('$_buyNowQuantity', style: const TextStyle(fontSize: 14)),
                                ),
                                _qtyButton(
                                  icon: Icons.add,
                                  onTap: _buyNowQuantity < maxStock
                                      ? () => sheetSetState(() => _buyNowQuantity++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ---- Nút Mua ngay ----
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: shopeeRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _goToCheckout(product, isApparel: isApparel);
                            },
                            child: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey.shade300 : Colors.black87),
      ),
    );
  }

  /// Điều hướng sang trang Thanh toán với đúng phân loại + số lượng vừa chọn.
  void _goToCheckout(Product product, {required bool isApparel}) {
    final variantImage = product.images.isNotEmpty
        ? product.images[_selectedColor.clamp(0, product.images.length - 1)]
        : product.thumbnail;
    final variantLabel = isApparel
        ? '${_colors[_selectedColor.clamp(0, _colors.length - 1)]}, ${_sizes[_selectedSize.clamp(0, _sizes.length - 1)]}'
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen.buyNow(
          shopName: product.shopName.trim().isNotEmpty ? product.shopName : 'Shop',
          image: variantImage.isNotEmpty ? variantImage : product.thumbnail,
          productName: product.name.trim().isNotEmpty ? product.name : 'Sản phẩm',
          variant: variantLabel,
          price: product.price,
          originalPrice: product.originalPrice,
          quantity: _buyNowQuantity,
          category: product.category,
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
            appBar: _buildTopBar(context, null),
            body: const Center(child: CircularProgressIndicator(color: shopeeOrange)),
          );
        }

        final product = snapshot.data ?? _fallbackProduct();
        if (_shopKey == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowState(product));
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: _buildTopBar(context, product),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(product),
                _buildFlashSaleBanner(product),
                _buildPriceAndTitle(product),
                // Màu sắc + Kích cỡ chỉ cho quần áo / thời trang.
                // Sản phẩm khác (điện thoại, mỹ phẩm...) hiện phân loại ảnh nếu có.
                if (_isApparel(product))
                  _buildColorSizeSection(product)
                else if (product.images.length > 1)
                  _buildImageVariantSelector(product),
                _buildShippingCard(product),
                const SizedBox(height: 8),
                _buildExpandableSections(product),
                const SizedBox(height: 8),
                _buildRatingCard(product),
                const SizedBox(height: 8),
                _buildVideosSection(product),
                const SizedBox(height: 8),
                _buildShopCard(product),
                const SizedBox(height: 8),
                _buildSimilarSection(product),
                const SizedBox(height: 12),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, product),
        );
      },
    );
  }

  // ================= TOP BAR (thanh trắng có ô tìm kiếm, giống Shopee) =================
  PreferredSizeWidget _buildTopBar(BuildContext context, Product? product) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 0.6,
        automaticallyImplyLeading: false,
        titleSpacing: 4,
        leadingWidth: 40,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: shopeeOrange, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductSearchScreen(initialHint: product?.name),
              ),
            );
          },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    product?.name ?? 'Tìm kiếm sản phẩm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.share_outlined, color: shopeeOrange, size: 21),
            onPressed: () => _openShareSheet(product),
          ),
          const SizedBox(width: 2),
          _topCartIconButton(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert, color: Colors.grey.shade700, size: 21),
            onPressed: () => _showComingSoon('Thêm tùy chọn'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _topCartIconButton({required VoidCallback onTap}) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.totalItemCount;
        return InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: shopeeOrange, size: 21),
                if (count > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: BoxDecoration(
                        color: shopeeOrange,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
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
          // Indicator 1/8 kiểu Shopee
          if (images.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_galleryIndex + 1}/${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= BANNER FLASH SALE / VOUCHER XTRA (giống 8.8) =================
  Widget _buildFlashSaleBanner(Product product) {
    if (product.discountPercent <= 0) return const SizedBox.shrink();
    final saved = (product.originalPrice - product.price).clamp(0, 999999999);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Hàng 8.8 VOUCHER XTRA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7337), Color(0xFFF53D2D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '8.8',
                    style: TextStyle(color: shopeeRed, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'VOUCHER XTRA',
                    style: TextStyle(color: shopeeRed, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
                const Spacer(),
                const Text('Kết thúc trong', style: TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(width: 4),
                _countdownBox(_two(_voucherRemaining.inHours)),
                const _colon(),
                _countdownBox(_two(_voucherRemaining.inMinutes.remainder(60))),
                const _colon(),
                _countdownBox(_two(_voucherRemaining.inSeconds.remainder(60))),
              ],
            ),
          ),
          // Dòng giảm giá đặc biệt
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF0EB),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 16, color: shopeeRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Giảm giá đặc biệt ₫${_formatVnd(saved)}',
                    style: const TextStyle(color: shopeeRed, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  Widget _countdownBox(String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  String _formatVnd(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  // ================= GIÁ + TÊN SẢN PHẨM =================
  Widget _buildPriceAndTitle(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giá + sold + heart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.priceText,
                          style: const TextStyle(
                            color: shopeeRed,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product.discountPercent > 0)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Giá Sau Voucher',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    if (product.discountPercent > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Chỉ từ ${_formatVnd((product.price / 6).round())}đ x 6 kỳ với SPayLater ›',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    'Đã bán ${product.soldCount}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? shopeeRed : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tagChip('Giảm ₫${_formatVnd((product.originalPrice - product.price).clamp(0, 999999))} sẽ hết sau 1 giờ', const Color(0xFFFFF0EB), shopeeRed),
                const SizedBox(width: 6),
                _tagChip('Rẻ Vô Địch', const Color(0xFFE8F5E9), const Color(0xFF2E7D32), icon: Icons.thumb_up),
                const SizedBox(width: 6),
                _tagChip('Mua để nhận quà', Colors.grey.shade100, Colors.grey.shade700),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Title + Mall badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: shopeeRed,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('Mall', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.35, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ================= MÀU SẮC + KÍCH CỠ =================
  Widget _buildColorSizeSection(Product product) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MÀU SẮC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_colors.length, (i) {
              final selected = i == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFF0EB) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? shopeeOrange : Colors.grey.shade300,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    _colors[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? shopeeOrange : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          const Text('KÍCH CỠ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sizes.length, (i) {
              final selected = i == _selectedSize;
              return GestureDetector(
                onTap: () => setState(() => _selectedSize = i),
                child: Container(
                  width: 52,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFF0EB) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? shopeeOrange : Colors.grey.shade300,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    _sizes[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? shopeeOrange : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Phân loại bằng ảnh (dùng cho điện thoại, mỹ phẩm... — không phải quần áo).
  Widget _buildImageVariantSelector(Product product) {
    final variants = product.images.take(6).toList();
    if (variants.length <= 1) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${variants.length} phân loại có sẵn',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: variants.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedColor;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = index;
                      _galleryIndex = index.clamp(0, product.images.length - 1);
                    });
                    if (_galleryController.hasClients) {
                      _galleryController.animateToPage(
                        _galleryIndex,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? shopeeOrange : Colors.grey.shade300,
                        width: selected ? 1.6 : 1,
                      ),
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

  // ================= VẬN CHUYỂN =================
  Widget _buildShippingCard(Product product) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF26A69A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mua trước 08:00, Nhận trong Hôm Nay 12:00',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phí vận chuyển ₫0  •  ${product.location}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ================= CÁC MỤC MỞ RỘNG (Hướng dẫn size chỉ cho quần áo, Mô tả, Đảm bảo) =================
  Widget _buildExpandableSections(Product product) {
    final isApparel = _isApparel(product);
    final description = product.description.trim().isNotEmpty
        ? product.description.trim()
        : (isApparel
            ? 'Chất liệu: Cotton 100% / Nỉ cao cấp\n'
                'Form: Oversize unisex\n'
                'Có khóa kéo phía trước, mũ trùm đầu, túi kangaroo.\n'
                'In logo chất lượng cao, không bong tróc sau nhiều lần giặt.'
            : '${product.name} chính hãng, chất lượng cao.\n'
                'Sản phẩm được đóng gói cẩn thận, hỗ trợ đổi trả theo chính sách Shopee.\n'
                'Vui lòng xem kỹ thông tin trước khi đặt hàng.');

    final tiles = <Widget>[];

    // Hướng dẫn chọn kích cỡ — CHỈ dành cho quần áo / thời trang
    if (isApparel) {
      tiles.add(
        _expandableTile(
          title: 'Hướng dẫn chọn kích cỡ',
          expanded: _sizeGuideExpanded,
          onTap: () => setState(() => _sizeGuideExpanded = !_sizeGuideExpanded),
          content: const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              '• Size M: 50-58kg, cao 1m60-1m68\n'
              '• Size L: 58-68kg, cao 1m68-1m75\n'
              '• Size XL: 68-80kg, cao 1m75-1m82\n\n'
              'Nên chọn size lớn hơn 1 size nếu thích form rộng (oversized).',
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
            ),
          ),
        ),
      );
      tiles.add(const Divider(height: 1, indent: 12, endIndent: 12));
    }

    // Thông số & Mô tả — dùng description thật của sản phẩm
    tiles.add(
      _expandableTile(
        title: 'Thông số & Mô tả',
        expanded: _specExpanded,
        onTap: () => setState(() => _specExpanded = !_specExpanded),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            description,
            style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
          ),
        ),
      ),
    );
    tiles.add(const Divider(height: 1, indent: 12, endIndent: 12));

    // Shopee đảm bảo — áp dụng mọi sản phẩm
    tiles.add(
      _expandableTile(
        title: 'Shopee đảm bảo',
        expanded: _guaranteeExpanded,
        onTap: () => setState(() => _guaranteeExpanded = !_guaranteeExpanded),
        content: const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Text(
            '✓ Đổi trả miễn phí trong 15 ngày\n'
            '✓ Hàng chính hãng 100%\n'
            '✓ Hoàn tiền nếu hàng giả / lỗi từ nhà bán\n'
            '✓ Bảo vệ người mua Shopee',
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
        ),
      ),
    );

    return Container(
      color: Colors.white,
      child: Column(children: tiles),
    );
  }

  Widget _expandableTile({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        if (expanded) content,
      ],
    );
  }

  // ================= ĐÁNH GIÁ SẢN PHẨM =================
  Widget _buildRatingCard(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _displayRating(product).toStringAsFixed(1),
                style: const TextStyle(color: shopeeOrange, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 18, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                'Đánh Giá Sản Phẩm (${product.ratingCount > 0 ? product.ratingCount : 1280})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Text('Tất cả ›', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          // Ô tìm đánh giá
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _reviewSearchCtrl,
                    onChanged: (v) => setState(() => _reviewSearchQuery = v),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Tìm đánh giá từ những người mua khác',
                      hintStyle: TextStyle(fontSize: 13),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (_reviewSearchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _reviewSearchCtrl.clear();
                      _reviewSearchQuery = '';
                    }),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Builder(builder: (context) {
            final allReviews = _mockReviews(product);
            final q = _reviewSearchQuery.trim().toLowerCase();
            final reviews = q.isEmpty
                ? allReviews
                : allReviews.where((r) => r.comment.toLowerCase().contains(q)).toList();
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Không tìm thấy đánh giá phù hợp.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              );
            }
            return Column(
              children: reviews.map((r) => _buildReviewTile(r, product)).toList(),
            );
          }),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showComingSoon('Đánh giá sản phẩm tương tự'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Text('Đánh giá sản phẩm tương tự', style: TextStyle(fontSize: 13.5)),
                  const SizedBox(width: 4),
                  Icon(Icons.help_outline, size: 15, color: Colors.grey.shade500),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bộ bình luận mẫu theo TỪNG NHÓM danh mục — để lời review luôn khớp với
  /// loại sản phẩm đang xem (không còn ghi "áo quần" cho sản phẩm điện tử).
  static const Map<String, List<String>> _commentsByGroup = {
    'apparel': [
      'Áo quần vải đẹp, hơi bị thừa chỉ nhưng mà ko sao, đóng gói chỉnh chu, có túi bảo vệ bên ngoài, đc tặng 1 chai nước hoa F...',
      'Áo đẹp, mặc mát, giá ổn. Oke ạ!!',
      'Chất vải mịn, form chuẩn, lên dáng đẹp, sẽ ủng hộ shop tiếp.',
      'Đúng hình mô tả, đường may chắc chắn, giao hàng nhanh.',
    ],
    'shoes': [
      'Giày đẹp, đi êm chân, đúng size như bảng size shop tư vấn.',
      'Chất liệu tốt, form giày ôm chân, đóng gói cẩn thận không móp hộp.',
      'Đi vừa chân, giày nhẹ, màu lên thực tế đẹp hơn ảnh.',
    ],
    'accessories': [
      'Hàng đẹp, chắc chắn, đúng mẫu đặt, đóng gói kỹ có hộp cẩn thận.',
      'Đeo lên rất sang, chất liệu ổn so với giá tiền, sẽ ủng hộ tiếp.',
      'Sản phẩm y hình, giao nhanh, có đầy đủ phụ kiện đi kèm.',
    ],
    'electronics': [
      'Máy chạy mượt, đóng gói kỹ có màng bảo vệ, đầy đủ phụ kiện chính hãng.',
      'Hàng zin, kích hoạt bảo hành ok, sạc pin nhanh, đáng tiền.',
      'Đúng mô tả, dùng thử vài hôm ổn định, hiệu năng tốt.',
    ],
    'beauty': [
      'Sản phẩm chính hãng, có tem chống giả, mùi thơm dễ chịu, thấm nhanh.',
      'Dùng thử thấy da mềm mịn hơn, không gây kích ứng, sẽ mua lại.',
      'Đóng gói kỹ, có seal nguyên vẹn, giao hàng nhanh.',
    ],
    'home': [
      'Hàng chắc chắn, đúng kích thước mô tả, lắp ráp dễ dàng.',
      'Chất liệu tốt, màu sắc y hình, đóng gói cẩn thận không trầy xước.',
      'Sản phẩm đẹp, phù hợp không gian nhà, đáng tiền.',
    ],
    'food': [
      'Hàng mới, hạn sử dụng dài, đóng gói kỹ, giao nhanh.',
      'Đúng vị mô tả, đóng gói cẩn thận, sẽ ủng hộ shop tiếp.',
    ],
    'vehicle': [
      'Đồ chắc chắn, lắp vừa xe, chất liệu bền, đóng gói kỹ.',
      'Đúng mẫu đặt, giao nhanh, dùng ổn định.',
    ],
    'sports': [
      'Chất lượng tốt, dùng chắc tay, đáng tiền so với giá.',
      'Đúng mô tả, đóng gói kỹ, tập luyện thoải mái.',
    ],
    'other': [
      'Sản phẩm đúng mô tả, đóng gói chỉnh chu, giao hàng nhanh.',
      'Rất ưng ý, sẽ ủng hộ shop lần sau. Đóng gói chắc chắn không lo vỡ.',
    ],
  };

  /// Nhãn "Phân loại" mẫu theo từng nhóm danh mục (VD: quần áo hiện
  /// Màu,Size; điện tử hiện Màu,Dung lượng; mỹ phẩm hiện dung tích...).
  static const Map<String, List<String>> _variantsByGroup = {
    'apparel': ['Đen,M', 'Đen,L', 'Trắng,XL', 'Đen,S'],
    'shoes': ['Đen,39', 'Trắng,40', 'Đen,38', 'Nâu,41'],
    'accessories': ['Bạc', 'Vàng', 'Đen', 'Nâu'],
    'electronics': ['Đen,128GB', 'Xám,256GB', 'Trắng,8GB/128GB', 'Đen,256GB'],
    'beauty': ['30ml', '50ml', 'Set đầy đủ', '100ml'],
    'home': ['Nâu gỗ', 'Trắng', 'Size lớn', 'Xám'],
    'food': ['Hộp 500g', 'Gói 1kg', 'Hộp 250g'],
    'vehicle': ['Size L', 'Size M', 'Mặc định'],
    'sports': ['M', 'L', 'Bộ đầy đủ'],
    'other': ['Mặc định'],
  };

  List<_Review> _mockReviews(Product product) {
    final group = _reviewCategoryGroup(product);
    final names = ['a*****n', 'bxdtthq8ij', 'ngan.tran88', 'khanhlinh_'];
    final comments = _commentsByGroup[group] ?? _commentsByGroup['other']!;
    final variants = _variantsByGroup[group] ?? _variantsByGroup['other']!;
    final stars = [5, 5, 5, 5];
    final withPhoto = [true, false, false, true];
    return List.generate(2, (i) {
      return _Review(
        name: names[i],
        stars: stars[i],
        comment: comments[i % comments.length],
        variant: variants[i % variants.length],
        hasPhoto: withPhoto[i],
      );
    });
  }

  Widget _buildReviewTile(_Review review, Product product) {
    // Ảnh minh hoạ đính kèm đánh giá lấy theo ĐÚNG NHÓM danh mục sản phẩm
    // (ảnh ngoài, không phải ảnh sản phẩm từ API) để review áo ra ảnh áo,
    // review điện thoại ra ảnh điện thoại... thay vì bị lẫn ảnh lung tung.
    final group = _reviewCategoryGroup(product);
    final images = MockData.reviewPhotosByCategory[group] ?? MockData.reviewPhotosByCategory['other']!;
    final base = product.id + review.name.hashCode.abs();
    String imgAt(int i) => images.isEmpty ? '' : images[(base + i) % images.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  review.name.isNotEmpty ? review.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(review.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ),
              Text('Hữu ích (0)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(width: 4),
              Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey.shade500),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.stars ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Phân loại: ${review.variant}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 6),
          Text(review.comment, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
          if (review.hasPhoto) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _reviewPhotoThumb(imageUrl: imgAt(0), showPlay: true),
                  const SizedBox(width: 6),
                  _reviewPhotoThumb(imageUrl: imgAt(1)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewPhotoThumb({String imageUrl = '', bool showPlay = false}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            )
          else
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
          if (showPlay)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 11, color: Colors.white),
                    SizedBox(width: 2),
                    Text('0:04', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= VIDEO VỀ SẢN PHẨM =================
  Widget _buildVideosSection(Product product) {
    // Thumbnail video lấy từ kho ảnh mock riêng (ảnh ngoài), không dùng ảnh
    // sản phẩm từ API, để giả lập khung hình đầu video thật.
    final images = MockData.productVideoThumbs;
    String imgAt(int i) => images.isEmpty ? '' : images[i % images.length];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Video về sản phẩm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final thumb = imgAt(index);
                return Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh nền lấy từ ảnh sản phẩm (mock) thay vì khối xám.
                      if (thumb.isNotEmpty)
                        Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: Colors.grey.shade300),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(color: Colors.grey.shade300);
                          },
                        )
                      else
                        Container(color: Colors.grey.shade300),
                      // Lớp phủ mờ để chữ + icon play nổi bật hơn.
                      Container(color: Colors.black.withValues(alpha: 0.12)),
                      Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Text(
                          index == 0
                              ? '#ShopeeVideo#LuotVui...'
                              : index == 1
                                  ? '#shopeevideo #koluytin'
                                  : '[BST TẾT 20...',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ]),
                        ),
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

  // ================= SHOP CARD =================
  Widget _buildShopCard(Product product) {
    final productCount = 239;
    final responseRate = 98;
    final shopName = product.shopName.trim().isNotEmpty ? product.shopName : 'Shop';

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
                child: Stack(
                  children: [
                    ShopAvatar(shopName: shopName, radius: 26),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: shopeeRed,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('Shopee Mall', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openShop(product),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: Color(0xFF2E9E5B), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text('Online 2 phút trước', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _openShop(product),
                style: OutlinedButton.styleFrom(
                  foregroundColor: shopeeOrange,
                  side: const BorderSide(color: shopeeOrange),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Xem Shop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _shopStat(_displayRating(product).toStringAsFixed(1), 'Đánh giá')),
              _shopStatDivider(),
              Expanded(child: _shopStat('$productCount', 'Sản phẩm')),
              _shopStatDivider(),
              Expanded(child: _shopStat('$responseRate%', 'Phản hồi Chat')),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Các sản phẩm khác của Shop', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                  height: 180,
                  child: Center(child: CircularProgressIndicator(color: shopeeOrange, strokeWidth: 2)),
                );
              }
              if (items.isEmpty) {
                return const Text('Chưa có sản phẩm khác.', style: TextStyle(color: Colors.grey, fontSize: 12.5));
              }
              return SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length.clamp(0, 8),
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _buildShopProductCard(items[index], shopName),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _shopStatDivider() => Container(width: 1, height: 32, color: Colors.grey.shade300);

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
        width: 118,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              width: double.infinity,
              child: p.thumbnail.isEmpty
                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                  : Image.network(
                      p.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, height: 1.2),
                    ),
                    const Spacer(),
                    Text(
                      p.priceText,
                      style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 11, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(
                          _displayRating(p).toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${p.soldCount} đã bán',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SẢN PHẨM TƯƠNG TỰ =================
  Widget _buildSimilarSection(Product product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '— Có thể bạn cũng thích —',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
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
                itemCount: items.length.clamp(0, 6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
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
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
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
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        ),
                ),
                if (p.discountPercent > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: shopeeRed,
                        borderRadius: BorderRadius.circular(3),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.priceText,
                    style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(_displayRating(p).toStringAsFixed(1), style: const TextStyle(fontSize: 11.5)),
                      const SizedBox(width: 6),
                      Text('${p.soldCount} đã bán', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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

  // ================= THANH DƯỚI CÙNG =================
  Widget _buildBottomBar(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _bottomIconButton(Icons.chat_bubble_outline, 'Chat ngay', () => _openChat(product)),
              Container(width: 1, height: 28, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 4)),
              _bottomCartIconButton(
                'Thêm vào\nGiỏ hàng',
                () => _addToCart(product),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _showBuyNowSheet(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shopeeRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Mua với voucher', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.1)),
                        Text(product.priceText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.15)),
                      ],
                    ),
                  ),
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
            Icon(icon, size: 22, color: Colors.grey.shade700),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomCartIconButton(String label, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.totalItemCount;
        return InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.add_shopping_cart_outlined, size: 22, color: Colors.grey.shade700),
                    if (count > 0)
                      Positioned(
                        right: -7,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 15),
                          decoration: const BoxDecoration(
                            color: shopeeOrange,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
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
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cấu trúc dữ liệu đánh giá minh hoạ.
class _Review {
  final String name;
  final int stars;
  final String comment;
  final String variant;
  final bool hasPhoto;

  const _Review({
    required this.name,
    required this.stars,
    required this.comment,
    this.variant = 'Mặc định',
    this.hasPhoto = false,
  });
}

class _colon extends StatelessWidget {
  const _colon();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      );
}

/// Khay chia sẻ sản phẩm — bám sát khay "Chia sẻ tới..." thật trên điện
/// thoại: 1 hàng preview sản phẩm ở trên, bên dưới là lưới icon các nền
/// tảng mạng xã hội phổ biến (Facebook, Messenger, Zalo, WhatsApp,
/// Telegram, Sao chép liên kết), và cuối cùng là nút mở khay chia sẻ gốc
/// của hệ điều hành (liệt kê TẤT CẢ app đã cài trên máy, giống hệt khi bấm
/// nút Share trong các app khác trên điện thoại).
class _ShareBottomSheet extends StatelessWidget {
  final Product product;
  final Color shopeeOrange;
  final VoidCallback onFacebook;
  final VoidCallback onMessenger;
  final VoidCallback onZalo;
  final VoidCallback onWhatsApp;
  final VoidCallback onTelegram;
  final VoidCallback onCopyLink;
  final VoidCallback onMore;

  const _ShareBottomSheet({
    required this.product,
    required this.shopeeOrange,
    required this.onFacebook,
    required this.onMessenger,
    required this.onZalo,
    required this.onWhatsApp,
    required this.onTelegram,
    required this.onCopyLink,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.only(bottom: 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(top: 10, bottom: 8 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo nhỏ ở đầu sheet
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Preview sản phẩm đang chia sẻ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      product.thumbnail,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₫${product.priceText}',
                          style: TextStyle(fontSize: 12.5, color: shopeeOrange, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 20),
            // Lưới các nền tảng mạng xã hội
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _shareIcon(
                    context,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    icon: Icons.facebook,
                    onTap: onFacebook,
                  ),
                  _shareIcon(
                    context,
                    label: 'Messenger',
                    color: const Color(0xFF00B2FF),
                    icon: Icons.messenger_outline_rounded,
                    onTap: onMessenger,
                  ),
                  _shareIcon(
                    context,
                    label: 'Zalo',
                    color: const Color(0xFF0068FF),
                    icon: Icons.chat_bubble_rounded,
                    onTap: onZalo,
                  ),
                  _shareIcon(
                    context,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    icon: Icons.chat,
                    onTap: onWhatsApp,
                  ),
                  _shareIcon(
                    context,
                    label: 'Telegram',
                    color: const Color(0xFF29A9EA),
                    icon: Icons.send_rounded,
                    onTap: onTelegram,
                  ),
                  _shareIcon(
                    context,
                    label: 'Sao chép link',
                    color: Colors.grey.shade600,
                    icon: Icons.link_rounded,
                    onTap: onCopyLink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),
            // Nút mở khay chia sẻ gốc của điện thoại (liệt kê mọi app đã cài)
            ListTile(
              onTap: onMore,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apps_rounded, color: Colors.black54, size: 22),
              ),
              title: const Text(
                'Chia sẻ qua ứng dụng khác...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Hiển thị toàn bộ ứng dụng trên máy',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            // Nút Huỷ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Huỷ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareIcon(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
