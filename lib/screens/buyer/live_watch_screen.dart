import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/shop_avatar.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../services/shop_service.dart';
import '../../services/product_api_service.dart';
import '../../services/cart_service.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';

/// Video mặc định dùng để GIẢ LẬP (fake) luồng livestream khi chưa có server
/// streaming thật. Hãy đặt 1 file video (vd: quay màn hình bán hàng, video
/// giới thiệu sản phẩm...) vào assets/videos/live_1.mp4 — xem hướng dẫn chi
/// tiết ở assets/videos/HUONG_DAN_VIDEO.md.
///
/// Mỗi item trong MockData.liveStreams có thể tự override video riêng bằng
/// cách thêm field "video": "assets/videos/xxx.mp4" — nếu không có sẽ dùng
/// video mặc định này.
const String kDefaultLiveVideoAsset = 'assets/videos/live_1.mp4';

/// Màn hình xem 1 livestream cụ thể, full màn hình — mô phỏng lại đúng giao
/// diện Shopee Live: video nền, thông tin host, banner quảng cáo, khung
/// phần thưởng, thẻ sản phẩm/voucher nổi, khung bình luận + thanh chat, và
/// thanh điều hướng dưới cùng.
class LiveWatchScreen extends StatefulWidget {
  final Map<String, dynamic> stream;

  const LiveWatchScreen({super.key, required this.stream});

  @override
  State<LiveWatchScreen> createState() => _LiveWatchScreenState();
}

class _LiveWatchScreenState extends State<LiveWatchScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color liveRed = Color(0xFFFF424F);

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoError = false;

  // ============== SHOP + SẢN PHẨM THẬT (KHÔNG DÙNG DỮ LIỆU MẪU) ==============
  // Tên shop + danh sách sản phẩm lấy từ 2 nguồn THẬT, gọi song song:
  //  1) Firebase (ShopService) — shop do người dùng tự đăng ký + tự đăng sản
  //     phẩm bán. Đây là nguồn ưu tiên nếu hệ thống đã có shop nào đó.
  //  2) ProductApiService (DummyJSON, đã có sẵn trong lib) — dùng làm nguồn
  //     dự phòng khi CHƯA có shop Firebase nào (ứng dụng mới cài, chưa ai
  //     đăng ký bán hàng). Video livestream không phụ thuộc Firebase vì
  //     người dùng thật sẽ tự phát trực tiếp, không cần dữ liệu mẫu.
  Shop? _shop; // != null nếu có shop Firebase thật -> ưu tiên dùng
  String? _apiShopName; // tên shop "ảo" dựng từ dữ liệu API khi chưa có Firebase
  List<Product> _shopProducts = [];
  bool _shopDataLoading = true; // đang tải shop/sản phẩm -> dùng để hiện loading thay vì "trống"

  // ============== ĐẾM NGƯỢC PHẦN THƯỞNG (giả lập) ==============
  Timer? _rewardTicker;
  int _checkinSeconds = 54; // "Xem 00:54 để điểm danh"
  int _checkinCoins = 80;
  int _watchSeconds = 24; // "Xem 00:24 để nhận thưởng"
  int _watchCoins = 22;
  bool _watchClaimReady = false;
  bool _watchClaimed = false;

  // ============== TIM BAY (like) ==============
  int _likeCount = 3;
  final List<_HeartData> _hearts = [];
  int _heartSeed = 0;
  final Random _rand = Random();

  // ============== SẢN PHẨM ĐANG GHIM (xoay vòng) ==============
  int _productIndex = 0;
  Timer? _productTicker;

  // ============== BÌNH LUẬN ẢO (giả lập người xem chat) ==============
  final List<_ChatMsg> _chatMessages = [];
  Timer? _chatTicker;
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatInputController = TextEditingController();
  final FocusNode _chatInputFocus = FocusNode();
  static const List<List<String>> _fakeChatPool = [
    ["mai_anh92", "Nồi chiên này chiên gà có giòn không shop ơi"],
    ["hoang.thanh", "Còn màu trắng không ạ 😍"],
    ["user_7729", "Ship về Đà Nẵng mất mấy ngày vậy shop"],
    ["linhh.chi", "Vừa mua xong, chờ hàng nè"],
    ["quangkhoi", "Giá này rẻ hơn siêu thị nhiều luôn"],
    ["be_beo", "Bảo hành bao lâu vậy ạ?"],
    ["ngoc.tran99", "Đang phân vân giữa 2 mẫu 😅"],
    ["minh.duc", "Cho xin mã giảm giá với shop ơi"],
    ["thuy_linh", "Nhìn nấu ngon quá trời"],
    ["anh_tuan88", "Chốt đơn 1 cái nồi cơm điện"],
    ["kim.oanh", "Có freeship không shop?"],
    ["pham.hieu", "Dùng bền không mọi người ơi"],
  ];

  @override
  void initState() {
    super.initState();
    _initVideo();
    _rewardTicker = Timer.periodic(const Duration(seconds: 1), (_) => _tickRewards());
    _loadShopData();
    // Giả lập vài bình luận ban đầu rồi tiếp tục thêm theo thời gian
    _seedInitialChat();
    _chatTicker = Timer.periodic(const Duration(milliseconds: 2600), (_) => _addFakeChat());
  }

  void _seedInitialChat() {
    _chatMessages.addAll([
      _ChatMsg('hoang.thanh', 'Chào shop, đang xem livestream nè'),
      _ChatMsg('mai_anh92', 'Sản phẩm đẹp quá ạ'),
    ]);
  }

  void _addFakeChat() {
    if (!mounted) return;
    final pick = _fakeChatPool[_rand.nextInt(_fakeChatPool.length)];
    setState(() {
      _chatMessages.add(_ChatMsg(pick[0], pick[1]));
      if (_chatMessages.length > 40) {
        _chatMessages.removeAt(0);
      }
    });
    _scrollChatToBottom();
  }

  void _sendMyMessage() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMsg('Bạn', text, isMe: true));
      if (_chatMessages.length > 40) {
        _chatMessages.removeAt(0);
      }
    });
    _chatInputController.clear();
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    if (_chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted || !_chatScrollController.hasClients) return;
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // ============== TẢI SHOP + SẢN PHẨM THẬT (API ƯU TIÊN TRƯỚC, FIREBASE DỰ PHÒNG) ==============
  Future<void> _loadShopData() async {
    try {
      // Gọi Firebase (shop do người dùng đăng ký) và API sản phẩm thật cùng
      // lúc, không chờ tuần tự, để không mất thời gian oan nếu 1 trong 2
      // nguồn chậm.
      final results = await Future.wait([
        ShopService.instance.fetchFirstShop(),
        _fetchKitchenProducts(),
      ]);
      if (!mounted) return;
      final shop = results[0] as Shop?;
      final apiProducts = results[1] as List<Product>;

      if (apiProducts.isNotEmpty) {
        // ƯU TIÊN dữ liệu API (nhóm hàng nhà bếp) trước — gán chung về 1
        // shop đồ gia dụng nhà bếp duy nhất. Chỉ khi API không có sản phẩm
        // nào thì mới xét tới shop Firebase, tránh trường hợp 1 shop
        // Firebase (VD: shop test chưa đăng sản phẩm nào) khiến giỏ hàng
        // livestream bị trống dù dữ liệu API hoàn toàn có sẵn.
        final picked = _pickKitchenShopFromApiProducts(apiProducts);
        setState(() {
          _apiShopName = picked.shopName;
          _shopProducts = picked.products;
        });
      } else if (shop != null) {
        // API không trả về sản phẩm nào -> thử dùng shop Firebase thật (nếu
        // seller nào đó đã đăng ký bán hàng và có sản phẩm).
        final entries = await ShopService.instance.fetchShopProducts(shop.id);
        if (!mounted) return;
        if (entries.isNotEmpty) {
          setState(() {
            _shop = shop;
            _shopProducts = entries.map((e) => e.value).toList();
          });
        } else {
          _useFallbackKitchenProducts();
        }
      } else {
        // Cả API lẫn Firebase đều không có gì -> dùng bộ sản phẩm nhà bếp
        // dự phòng cố định (không phụ thuộc mạng), để buổi live KHÔNG BAO
        // GIỜ hiển thị trống trơn.
        _useFallbackKitchenProducts();
      }
    } catch (_) {
      // Lỗi mạng/Firestore bất ngờ -> vẫn đảm bảo có hàng để bán.
      _useFallbackKitchenProducts();
    } finally {
      _shopDataLoading = false;
      _setupProductTicker();
    }
  }

  void _useFallbackKitchenProducts() {
    if (!mounted) return;
    setState(() {
      _apiShopName = kKitchenShopName;
      _shopProducts = _fallbackKitchenProducts;
    });
  }

  /// Bộ sản phẩm đồ gia dụng nhà bếp dự phòng, KHÔNG phụ thuộc mạng/API —
  /// phương án cuối cùng để buổi live luôn có hàng hiển thị, kể cả khi mất
  /// mạng hoặc API/Firebase đều không phản hồi được sản phẩm nào.
  static final List<Product> _fallbackKitchenProducts = [
    Product(
      id: -101,
      name: 'Nồi Chiên Không Dầu 5L Đa Năng',
      description: 'Nồi chiên không dầu công suất lớn, tiết kiệm điện, dễ vệ sinh.',
      price: 890000,
      originalPrice: 1290000,
      discountPercent: 31,
      rating: 4.8,
      ratingCount: 2400,
      soldCount: 15000,
      stock: 999,
      category: 'kitchen-accessories',
      categoryLabel: 'Phụ Kiện Nhà Bếp',
      brand: 'Bếp Xinh',
      shopName: kKitchenShopName,
      location: 'TP. Hồ Chí Minh',
      images: const ['https://picsum.photos/id/292/400/400'],
    ),
    Product(
      id: -102,
      name: 'Máy Xay Sinh Tố Đa Năng 2 Cối',
      description: 'Máy xay công suất mạnh, đi kèm 2 cối xay tiện lợi.',
      price: 450000,
      originalPrice: 650000,
      discountPercent: 31,
      rating: 4.7,
      ratingCount: 1800,
      soldCount: 9800,
      stock: 999,
      category: 'kitchen-accessories',
      categoryLabel: 'Phụ Kiện Nhà Bếp',
      brand: 'Bếp Xinh',
      shopName: kKitchenShopName,
      location: 'TP. Hồ Chí Minh',
      images: const ['https://picsum.photos/id/312/400/400'],
    ),
    Product(
      id: -103,
      name: 'Nồi Cơm Điện Tử Cao Cấp 1.8L',
      description: 'Nồi cơm điện tử nhiều chế độ nấu, lòng nồi chống dính cao cấp.',
      price: 690000,
      originalPrice: 990000,
      discountPercent: 30,
      rating: 4.9,
      ratingCount: 3100,
      soldCount: 21000,
      stock: 999,
      category: 'kitchen-accessories',
      categoryLabel: 'Phụ Kiện Nhà Bếp',
      brand: 'Bếp Xinh',
      shopName: kKitchenShopName,
      location: 'TP. Hồ Chí Minh',
      images: const ['https://picsum.photos/id/365/400/400'],
    ),
    Product(
      id: -104,
      name: 'Bộ Dao Kéo Nhà Bếp 6 Món',
      description: 'Bộ dao kéo thép không gỉ, sắc bén, kèm giá đựng tiện lợi.',
      price: 259000,
      originalPrice: 399000,
      discountPercent: 35,
      rating: 4.6,
      ratingCount: 950,
      soldCount: 5400,
      stock: 999,
      category: 'kitchen-accessories',
      categoryLabel: 'Phụ Kiện Nhà Bếp',
      brand: 'Bếp Xinh',
      shopName: kKitchenShopName,
      location: 'TP. Hồ Chí Minh',
      images: const ['https://picsum.photos/id/431/400/400'],
    ),
    Product(
      id: -105,
      name: 'Bộ Hộp Đựng Thực Phẩm Thủy Tinh 5 Món',
      description: 'Hộp thủy tinh chịu nhiệt, có nắp kín hơi, dùng được lò vi sóng.',
      price: 329000,
      originalPrice: 459000,
      discountPercent: 28,
      rating: 4.7,
      ratingCount: 1200,
      soldCount: 6700,
      stock: 999,
      category: 'kitchen-accessories',
      categoryLabel: 'Phụ Kiện Nhà Bếp',
      brand: 'Bếp Xinh',
      shopName: kKitchenShopName,
      location: 'TP. Hồ Chí Minh',
      images: const ['https://picsum.photos/id/1080/400/400'],
    ),
  ];

  /// Lấy sản phẩm nhà bếp từ API, có dự phòng nhiều tầng để KHÔNG BAO GIỜ
  /// trả về danh sách rỗng nếu API còn hoạt động:
  ///  1) Ưu tiên đúng nhóm hàng "kitchen-accessories" (Phụ Kiện Nhà Bếp).
  ///  2) Nếu nhóm đó rỗng/lỗi -> thử "home-decoration" (Trang Trí Nhà Cửa,
  ///     vẫn thuộc nhóm đồ gia dụng nói chung).
  ///  3) Nếu vẫn rỗng/lỗi -> lấy tạm danh sách sản phẩm chung từ API, để
  ///     buổi live luôn có hàng để bán thay vì hiện trống trơn.
  Future<List<Product>> _fetchKitchenProducts() async {
    try {
      final kitchen = await ProductApiService.fetchSimilarProducts('kitchen-accessories', limit: 30);
      if (kitchen.isNotEmpty) return kitchen;
    } catch (_) {}
    try {
      final homeDeco = await ProductApiService.fetchSimilarProducts('home-decoration', limit: 30);
      if (homeDeco.isNotEmpty) return homeDeco;
    } catch (_) {}
    try {
      final generic = await ProductApiService.fetchProducts(limit: 30);
      if (generic.isNotEmpty) return generic;
    } catch (_) {}
    return const [];
  }

  /// Tên shop "ảo" đại diện cho toàn bộ buổi live đồ gia dụng nhà bếp.
  static const String kKitchenShopName = 'bepxinh.official';

  /// Từ danh sách sản phẩm API thuộc nhóm hàng nhà bếp, gán chung về đúng 1
  /// shop đồ gia dụng nhà bếp (bỏ qua tên thương hiệu gốc từng sản phẩm lẻ),
  /// để toàn bộ giỏ hàng trong livestream đồng nhất là 1 cửa hàng chuyên bán
  /// dụng cụ/đồ gia dụng nhà bếp — đúng tinh thần 1 buổi live chỉ bán hàng
  /// của 1 shop duy nhất.
  _ApiShopPick _pickKitchenShopFromApiProducts(List<Product> products) {
    if (products.isEmpty) return _ApiShopPick(kKitchenShopName, const []);
    final unified = products.map((p) => p.copyWith(shopName: kKitchenShopName)).toList();
    return _ApiShopPick(kKitchenShopName, unified);
  }

  void _setupProductTicker() {
    _productTicker?.cancel();
    final products = _displayProducts;
    if (products.length > 1) {
      _productTicker = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) return;
        setState(() => _productIndex = (_productIndex + 1) % products.length);
      });
    }
  }

  /// Tên shop hiển thị: ưu tiên shop Firebase THẬT, nếu chưa có thì dùng tên
  /// shop dựng từ dữ liệu API THẬT — không còn dùng tên mẫu trong mock_data.
  String get _displayShopName => _shop?.name ?? _apiShopName ?? 'shop.livestream';

  /// Danh sách sản phẩm hiển thị (khung sản phẩm nổi + giỏ hàng livestream):
  /// luôn lấy từ dữ liệu THẬT (_shopProducts đã được nạp từ Firebase hoặc
  /// API ở [_loadShopData]) — không còn dùng danh sách mẫu trong mock_data.
  List<Map<String, dynamic>> get _displayProducts =>
      _shopProducts.map(_productToSheetMap).toList();

  /// Chuyển 1 [Product] thật (Shop_API) sang đúng định dạng Map mà các
  /// widget hiển thị sản phẩm trong màn hình này đang dùng, để không phải
  /// viết lại UI — chỉ đổi nguồn dữ liệu.
  Map<String, dynamic> _productToSheetMap(Product p) {
    return {
      'thumb': p.thumbnail,
      'name': p.name,
      'price': _vndNoSuffix(p.price),
      'originalPrice': p.discountPercent > 0 ? _vndNoSuffix(p.originalPrice) : null,
      'discount': p.discountPercent > 0 ? '-${p.discountPercent}%' : '',
      'sold': p.soldText,
      'rating': p.rating.toStringAsFixed(1),
      'category': p.category,
    };
  }

  String _vndNoSuffix(int amount) {
    final text = formatVnd(amount);
    return text.endsWith('đ') ? text.substring(0, text.length - 1) : text;
  }

  /// Số liệu đánh giá / lượt theo dõi của shop — Shop model chưa lưu 2 trường
  /// này, nên sinh 1 cách ổn định dựa theo tên shop (giống cách ShopDetailScreen
  /// đang làm), để cùng 1 shop luôn hiện đúng 1 con số, không nhảy số mỗi lần mở.
  Map<String, dynamic> _shopStats(String shopName) {
    final seed = shopName.codeUnits.fold<int>(0, (a, b) => a + b) + 17;
    final followers = 800 + (seed * 137) % 600000;
    final rating = 4.5 + (seed % 5) / 10;
    return {'followers': followers, 'rating': rating};
  }

  String _formatFollowers(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return '$n';
  }

  Future<void> _initVideo() async {
    final asset = (widget.stream['video'] as String?) ?? kDefaultLiveVideoAsset;
    final controller = VideoPlayerController.asset(asset);
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // fake livestream: mặc định tắt tiếng
      await controller.play();
      if (!mounted) return;
      setState(() => _videoReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoError = true);
    }
  }

  void _tickRewards() {
    if (!mounted) return;
    setState(() {
      if (_checkinSeconds > 0) {
        _checkinSeconds--;
      } else {
        // Lặp lại mốc điểm danh tiếp theo (giả lập vòng lặp phần thưởng)
        _checkinSeconds = 60;
        _checkinCoins += 10;
      }
      if (!_watchClaimed) {
        if (_watchSeconds > 0) {
          _watchSeconds--;
        } else {
          _watchClaimReady = true;
        }
      }
    });
  }

  void _addHeart() {
    final id = _heartSeed++;
    setState(() {
      _likeCount++;
      _hearts.add(_HeartData(id: id, dx: _rand.nextDouble() * 36 - 18));
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _hearts.removeWhere((h) => h.id == id));
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  void dispose() {
    _rewardTicker?.cancel();
    _productTicker?.cancel();
    _chatTicker?.cancel();
    _chatScrollController.dispose();
    _chatInputController.dispose();
    _chatInputFocus.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _fmtTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.stream;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoBackground(),
          // Lớp phủ mờ nhẹ trên/dưới giúp chữ dễ đọc hơn trên nền video
          const _ScrimOverlay(),
          for (final h in _hearts) _FloatingHeart(key: ValueKey(h.id), dx: h.dx),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNav(),
                const SizedBox(height: 6),
                _buildHostRow(item),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(right: 10, top: 0, child: _buildRightColumn(item)),
                      Positioned(left: 10, top: 4, child: _buildVoucherCard(item)),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBottomArea(item),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= THANH TAB TRÊN CÙNG (Video / Live / Phim / Cho bạn) =================
  // Không còn nút "X" đóng riêng — giống app mẫu, người xem thoát livestream
  // bằng thao tác vuốt lùi/back thông thường của hệ điều hành (vuốt từ cạnh
  // trái trên iOS, nút back trên Android), Navigator vẫn hoạt động bình
  // thường nên không mất khả năng đóng màn hình.
  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toast('Trang cá nhân'),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => _toast('Tìm kiếm'),
            child: const Icon(Icons.search, color: Colors.white, size: 23),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _topNavTab('Video'),
                const SizedBox(width: 20),
                _topNavTab('Live'),
                const SizedBox(width: 20),
                _topNavTab('Phim', badge: 'Mới'),
                const SizedBox(width: 20),
                _topNavTab('Cho bạn', selected: true),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toast('Tạo nội dung mới'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.videocam_outlined, color: Colors.white, size: 25),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: shopeeOrange, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topNavTab(String label, {bool selected = false, String? badge}) {
    return GestureDetector(
      onTap: () {
        if (!selected) _toast('$label — tính năng đang phát triển');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontStyle: label == 'Phim' ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: liveRed, borderRadius: BorderRadius.circular(6)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (selected)
            Container(
              width: 20,
              height: 2.5,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      ),
    );
  }

  // ================= VIDEO NỀN =================
  Widget _buildVideoBackground() {
    final controller = _videoController;
    if (_videoError || controller == null) {
      // Không tìm thấy / không load được video -> nền giả lập + gợi ý cho dev
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B2B2B), Color(0xFF141414)],
          ),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(
                'Chưa tìm thấy video giả lập.\nHãy đặt file vào ${(widget.stream['video'] as String?) ?? kDefaultLiveVideoAsset}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    if (!_videoReady) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  // ================= HÀNG THÔNG TIN HOST =================
  Widget _buildHostRow(Map<String, dynamic> item) {
    final shopName = _displayShopName;
    final viewers = (item['viewers'] as String?) ?? '0';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => _toast('Xem trang shop $shopName'),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShopAvatar(shopName: shopName, radius: 18, showBorder: true),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    shopName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: Color(0xFFFFC107), size: 15),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: liveRed, borderRadius: BorderRadius.circular(3)),
                                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$viewers người xem',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _toast('Đã theo dõi $shopName'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(14)),
                  child: const Text('+ Theo dõi', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _toast('Bảng xếp hạng nhà sáng tạo'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text('Top nhà sáng tạo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, color: Colors.white, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CỘT PHẢI: BANNER QUẢNG CÁO + PHẦN THƯỞNG =================
  Widget _buildRightColumn(Map<String, dynamic> item) {
    return SizedBox(
      width: 152,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAdBanner(),
          const SizedBox(height: 8),
          _buildRewardCard(),
        ],
      ),
    );
  }

  Widget _buildAdBanner() {
    return GestureDetector(
      onTap: () => _toast('Xem chi tiết ưu đãi'),
      child: Container(
        width: 152,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: const Row(
          children: [
            Icon(Icons.local_offer, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Ưu đãi hôm nay\nGiảm đến 25%',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard() {
    return Container(
      width: 152,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E5FD9),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PHẦN THƯỞNG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _rewardRow(
            label: 'Xem ${_fmtTime(_checkinSeconds)} để điểm danh',
            coins: _checkinCoins,
            buttonLabel: 'Điểm d...',
            enabled: false,
            onTap: () => _toast('Chưa đủ thời gian điểm danh'),
          ),
          const SizedBox(height: 8),
          _rewardRow(
            label: _watchClaimed
                ? 'Bạn đã nhận thưởng'
                : 'Xem ${_fmtTime(_watchSeconds)} để nhận thưởng',
            coins: _watchCoins,
            buttonLabel: _watchClaimed ? 'Đã nhận' : 'Nhận',
            enabled: _watchClaimReady && !_watchClaimed,
            onTap: () {
              if (!_watchClaimReady || _watchClaimed) return;
              setState(() => _watchClaimed = true);
              _toast('Nhận thành công $_watchCoins xu!');
            },
          ),
        ],
      ),
    );
  }

  Widget _rewardRow({
    required String label,
    required int coins,
    required String buttonLabel,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 9.5, height: 1.25),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 14),
                  const SizedBox(width: 3),
                  Text('$coins', style: const TextStyle(color: Color(0xFFFFC107), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: enabled ? shopeeOrange : Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ================= THẺ SẢN PHẨM / VOUCHER NỔI (trái) =================
  Widget _buildVoucherCard(Map<String, dynamic> item) {
    final products = _displayProducts;
    Map<String, dynamic>? product;
    if (products.isNotEmpty) {
      product = products[_productIndex % products.length];
    }
    final thumb = (product?['thumb'] as String?) ?? (item['thumb'] as String?) ?? 'https://picsum.photos/id/1027/300/300';
    final price = (product?['price'] as String?) ?? (item['price'] as String?) ?? '0';
    final discount = (product?['discount'] as String?) ?? '-21%';
    final productCount = products.isEmpty ? 1 : products.length;
    return GestureDetector(
      key: ValueKey(_productIndex),
      onTap: () => _openProductSheet(item),
      child: Container(
        width: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(thumb, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: Text('$productCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: liveRed,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(6)),
                    ),
                    child: Text(discount, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product != null)
                    Text(
                      product['name'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w600),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA000)]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'VOUCHER XTRA',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${price}đ',
                          style: const TextStyle(color: Colors.black87, fontSize: 12.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.local_shipping_outlined, color: shopeeOrange, size: 13),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _toast('Đang chuyển đến trang sản phẩm...'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shopeeOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Mua ngay', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= KHU VỰC DƯỚI CÙNG: CHAT ẢO + Ô NHẬP =================
  Widget _buildBottomArea(Map<String, dynamic> item) {
    final title = (item['title'] as String?) ?? 'livestream';
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign, color: Color(0xFFFFC107), size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Chào mừng đến Shopee Live! Đang phát: $title',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFakeChatFeed(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _quickReply('Có khuyến mãi không shop?'),
              _quickReply('Giá bao nhiêu ạ?'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildGiftCluster(item),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _chatInputController,
                    focusNode: _chatInputFocus,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.white,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMyMessage(),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Bạn đang nghĩ gì...',
                      hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMyMessage,
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _toast('Chia sẻ livestream'),
                child: const Icon(Icons.reply_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addHeart,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 26),
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: liveRed, borderRadius: BorderRadius.circular(8)),
                        child: Text('$_likeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= KHUNG BÌNH LUẬN ẢO (giả lập người xem chat) =================
  Widget _buildFakeChatFeed() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 118),
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white, Colors.white],
            stops: [0.0, 0.18, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _chatScrollController,
          reverse: false,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _chatMessages.length,
          itemBuilder: (context, index) {
            final msg = _chatMessages[index];
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${msg.name}  ',
                            style: TextStyle(
                              color: msg.isMe ? shopeeOrange : const Color(0xFFFFC107),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: msg.text,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= BOTTOM SHEET GIỎ HÀNG / DANH SÁCH SẢN PHẨM =================
  void _openProductSheet(Map<String, dynamic> item) {
    // Nếu dữ liệu shop/sản phẩm vẫn đang tải (Firebase + API), không mở
    // sheet trống — vì sheet được build 1 lần tại thời điểm mở, sẽ không tự
    // cập nhật khi dữ liệu tải xong sau đó. Báo cho người dùng và để họ bấm
    // lại khi đã có dữ liệu.
    if (_shopDataLoading) {
      _toast('Đang tải sản phẩm, vui lòng thử lại sau giây lát...');
      return;
    }
    final shopName = _displayShopName;
    final products = _displayProducts;
    final stats = _shopStats(shopName);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                    child: Row(
                      children: [
                        ShopAvatar(shopName: shopName, radius: 16),
                        const SizedBox(width: 8),
                        Text(shopName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: shopeeOrange), borderRadius: BorderRadius.circular(4)),
                          child: Text('Yêu thích+', style: TextStyle(color: shopeeOrange, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.black45),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _toast('Tìm kiếm trong shop'),
                          child: const Icon(Icons.search, color: Colors.black87, size: 21),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _openRealCart,
                          child: AnimatedBuilder(
                            // Lắng nghe CartService để hiện đúng số lượng sản
                            // phẩm đang có trong giỏ, tự cập nhật ngay khi vừa
                            // bấm "Thêm giỏ hàng" / "Mua ngay" ở bên dưới.
                            animation: CartService.instance,
                            builder: (context, _) {
                              final count = CartService.instance.totalItemCount;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 21),
                                  if (count > 0)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        constraints: const BoxConstraints(minWidth: 15),
                                        decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(8)),
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
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close, color: Colors.black87, size: 21),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 3),
                        Text('${(stats['rating'] as double).toStringAsFixed(1)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Text('|', style: TextStyle(color: Colors.black26)),
                        const SizedBox(width: 6),
                        Text('${_formatFollowers(stats['followers'] as int)} Người theo dõi', style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  Expanded(
                    child: products.isEmpty
                        ? _buildEmptyProductsState()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                            itemCount: products.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildPromoBannerRow();
                              final productIdx = index - 1;
                              return _buildSheetProductRow(
                                products[productIdx],
                                index,
                                isCurrent: productIdx == _productIndex % products.length,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyProductsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.black26, size: 42),
            const SizedBox(height: 10),
            const Text(
              'Chưa tải được sản phẩm cho buổi live này',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vui lòng kiểm tra kết nối mạng rồi thử lại.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _shopDataLoading = true);
                _loadShopData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(18)),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBannerRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildCouponCard(
              bgColor: const Color(0xFFDEF7EE),
              icon: Icons.local_shipping,
              iconColor: const Color(0xFF1DB954),
              title: 'Miễn Phí Vận Chuyển',
              subtitle: 'Cho đơn từ 40.000đ',
              tag: 'Live',
              tagColor: const Color(0xFF1DB954),
              trailing: GestureDetector(
                onTap: () => _toast('Đã lưu mã miễn phí vận chuyển'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(14)),
                  child: const Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCouponCard(
              bgColor: const Color(0xFFFFEDE8),
              icon: Icons.storefront,
              iconColor: shopeeOrange,
              title: 'Giảm 22%',
              subtitle: 'Giảm tối đa 200k',
              tag: 'Live',
              tag2: 'Độc quyền Shopee',
              tagColor: shopeeOrange,
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ dạng "coupon" (vé giảm giá) — có đường kẻ đứt nét ngăn giữa phần nội
  /// dung và phần nút/nhãn bên phải, mô phỏng đúng khối FreeShip/Giảm giá
  /// trong livestream Shopee thật.
  Widget _buildCouponCard({
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    String? tag2,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _miniTag(tag, tagColor),
                    if (tag2 != null) _miniTag(tag2, tagColor),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.6)), borderRadius: BorderRadius.circular(3)),
      child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  /// Thêm 1 sản phẩm đang hiển thị trong sheet livestream vào giỏ hàng
  /// DÙNG CHUNG ([CartService]) — trước đây các nút "Thêm giỏ hàng" / "Mua
  /// ngay" trong livestream chỉ hiện toast giả chứ KHÔNG thực sự lưu gì cả,
  /// nên khi mở giỏ hàng lại thấy trống trơn. Giờ gọi thẳng
  /// [CartService.instance.addToCart] giống hệt cách trang chi tiết sản
  /// phẩm đang làm, để sản phẩm thật sự nằm trong giỏ và đồng bộ với toàn
  /// bộ app (badge số lượng, trang giỏ hàng...).
  void _addLiveProductToCart(Map<String, dynamic> p) {
    final name = (p['name'] as String?)?.trim();
    final priceStr = p['price'] as String? ?? '0';
    final originalPriceStr = p['originalPrice'] as String?;
    final rawThumb = p['thumb'] as String? ?? '';
    final category = p['category'] as String? ?? '';

    final price = parseVndPriceString(priceStr);
    // Nếu sản phẩm không giảm giá thì "giá gốc" = giá hiện tại (không có
    // gạch ngang), tránh để originalPrice = 0 gây hiển thị sai ở giỏ hàng.
    final originalPrice = originalPriceStr != null ? parseVndPriceString(originalPriceStr) : price;
    final image = rawThumb.isNotEmpty ? rawThumb : 'https://via.placeholder.com/150';

    CartService.instance.addToCart(
      shopName: _displayShopName,
      image: image,
      name: (name != null && name.isNotEmpty) ? name : 'Sản phẩm',
      variant: 'Mặc định',
      price: price,
      originalPrice: originalPrice,
      quantity: 1,
      category: category,
    );
  }

  /// Mở màn hình giỏ hàng THẬT (dùng chung toàn app), thay vì chỉ hiện
  /// toast "Giỏ hàng" như trước — đó chính là lý do bấm vào giỏ hàng
  /// không thấy sản phẩm nào cả.
  void _openRealCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
    );
  }

  /// Bấm "Mua ngay" trên 1 sản phẩm trong giỏ hàng live: chuyển thẳng sang
  /// trang Thanh toán với đúng sản phẩm đó, giống hệt luồng "Mua ngay" ở
  /// trang chi tiết sản phẩm — không cần qua bước thêm vào giỏ hàng trước.
  void _buyNowFromLive(Map<String, dynamic> p) {
    final name = (p['name'] as String?)?.trim();
    final priceStr = p['price'] as String? ?? '0';
    final originalPriceStr = p['originalPrice'] as String?;
    final rawThumb = p['thumb'] as String? ?? '';
    final category = p['category'] as String? ?? '';

    final price = parseVndPriceString(priceStr);
    final originalPrice = originalPriceStr != null ? parseVndPriceString(originalPriceStr) : price;
    final image = rawThumb.isNotEmpty ? rawThumb : 'https://via.placeholder.com/150';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen.buyNow(
          shopName: _displayShopName,
          image: image,
          productName: (name != null && name.isNotEmpty) ? name : 'Sản phẩm',
          variant: 'Mặc định',
          price: price,
          originalPrice: originalPrice,
          quantity: 1,
          category: category,
        ),
      ),
    );
  }

  Widget _buildSheetProductRow(Map<String, dynamic> p, int rank, {bool isCurrent = false}) {
    final name = p['name'] as String? ?? '';
    final price = p['price'] as String? ?? '0';
    final originalPrice = p['originalPrice'] as String?;
    final discount = p['discount'] as String? ?? '';
    final sold = p['sold'] as String? ?? '';
    final rating = p['rating'] as String? ?? '';
    final thumb = p['thumb'] as String? ?? '';

    // Số tiền được giảm khi mua trong buổi Live (nếu có giá gốc), hiển thị
    // đúng kiểu "↘ Giảm 64,4k trên Live" như trên Shopee thật.
    String? liveSavingsText;
    if (originalPrice != null) {
      final origVnd = parseVndPriceString(originalPrice);
      final curVnd = parseVndPriceString(price);
      final diff = origVnd - curVnd;
      if (diff > 0) liveSavingsText = 'Giảm ${_shortVnd(diff)} trên Live';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(thumb, width: 78, height: 78, fit: BoxFit.cover),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  color: Colors.black54,
                  child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
              if (discount.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    color: liveRed,
                    child: Text(discount, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              // Ribbon dưới ảnh: sản phẩm đang ghim hiển thị trên live thì
              // ghi "Đang hiển thị"; các sản phẩm còn lại mời "Tư vấn".
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 16,
                  alignment: Alignment.center,
                  color: Colors.black54,
                  child: isCurrent
                      ? const Text(
                          'Đang hiển thị',
                          style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.headset_mic, color: Colors.white, size: 9),
                            SizedBox(width: 3),
                            Text('Tư vấn', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(border: Border.all(color: shopeeOrange), borderRadius: BorderRadius.circular(3)),
                      child: Text('VOUCHER XTRA', style: TextStyle(color: shopeeOrange, fontSize: 8.5, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(border: Border.all(color: shopeeOrange), borderRadius: BorderRadius.circular(3)),
                      child: Text('Mua để nhận quà', style: TextStyle(color: shopeeOrange, fontSize: 8.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 11),
                    const SizedBox(width: 2),
                    Text(rating, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                    const SizedBox(width: 6),
                    Text('Đã bán $sold', style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${price}đ', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 4),
                    const Icon(Icons.confirmation_num_outlined, color: shopeeOrange, size: 13),
                  ],
                ),
                if (liveSavingsText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.south_east, color: shopeeOrange, size: 10),
                      const SizedBox(width: 2),
                      Text(liveSavingsText, style: const TextStyle(fontSize: 10.5, color: shopeeOrange, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ] else if (originalPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${originalPrice}đ',
                    style: const TextStyle(fontSize: 11, color: Colors.black38, decoration: TextDecoration.lineThrough),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      _addLiveProductToCart(p);
                      _toast('Đã thêm "$name" vào giỏ hàng');
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: shopeeOrange), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.add_shopping_cart, color: shopeeOrange, size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _buyNowFromLive(p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(16)),
                      child: const Text('Mua ngay', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Rút gọn số tiền kiểu Shopee: 64.400 -> "64,4k".
  String _shortVnd(int amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return '$amount';
  }

  Widget _quickReply(String text) {
    return GestureDetector(
      onTap: () {
        setState(() => _chatMessages.add(_ChatMsg('Bạn', text, isMe: true)));
        _scrollChatToBottom();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  Widget _buildGiftCluster(Map<String, dynamic> item) {
    final count = _displayProducts.length;
    return GestureDetector(
      onTap: () => _openProductSheet(item),
      child: SizedBox(
        width: 42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 30,
              child: Icon(Icons.shopping_cart, color: Colors.white, size: 26),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: shopeeOrange, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.white, size: 10),
                  const SizedBox(width: 2),
                  Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ================= KẾT QUẢ CHỌN 1 "SHOP" TỪ DANH SÁCH SẢN PHẨM API =================
class _ApiShopPick {
  final String shopName;
  final List<Product> products;
  _ApiShopPick(this.shopName, this.products);
}

// ================= 1 DÒNG BÌNH LUẬN TRONG LIVESTREAM =================
class _ChatMsg {
  final String name;
  final String text;
  final bool isMe;
  _ChatMsg(this.name, this.text, {this.isMe = false});
}

// ================= LỚP PHỦ GRADIENT GIÚP CHỮ DỄ ĐỌC =================
class _ScrimOverlay extends StatelessWidget {
  const _ScrimOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.35),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.45),
            ],
            stops: const [0.0, 0.18, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

// ================= HIỆU ỨNG TIM BAY LÊN KHI BẤM LIKE =================
class _HeartData {
  final int id;
  final double dx;
  _HeartData({required this.id, required this.dx});
}

class _FloatingHeart extends StatefulWidget {
  final double dx;
  const _FloatingHeart({super.key, required this.dx});

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rand = Random(widget.dx.hashCode);
    final color = [
      const Color(0xFFFF424F),
      const Color(0xFFFF7A7A),
      const Color(0xFFFFC107),
    ][rand.nextInt(3)];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Positioned(
          right: 24 + widget.dx * t,
          bottom: 90 + 260 * t,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + 0.6 * (t < 0.3 ? t / 0.3 : 1.0),
              child: Icon(Icons.favorite, color: color, size: 22),
            ),
          ),
        );
      },
    );
  }
}
