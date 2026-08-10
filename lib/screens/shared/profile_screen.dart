import 'package:flutter/material.dart';
import '../buyer/cart_screen.dart';
import 'settings_screen.dart';
import 'personal_info_screen.dart';
import '../seller/seller_register_screen.dart';
import '../seller/seller_dashboard_screen.dart';
import '../../widgets/role_gate.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/shop_service.dart';
import '../../services/cart_service.dart';
import '../../utils/avatar_utils.dart';
import '../buyer/my_orders_screen.dart';

class ShopeeProfilePage extends StatefulWidget {
  const ShopeeProfilePage({super.key});

  @override
  State<ShopeeProfilePage> createState() => _ShopeeProfilePageState();
}

class _ShopeeProfilePageState extends State<ShopeeProfilePage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);
  static const Color bgGrey = Color(0xFFF2F3F5);

  bool _showEmailVerify = true;

  // ---- Thông tin thật lấy từ Firebase (thay cho tên/số cố định) ----
  AppUser? _currentUser;
  int _followingCount = 0;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.instance.fetchCurrentUser();
    int followingCount = 0;
    if (user != null) {
      followingCount = await ShopService.instance.fetchFollowingCount(user.uid);
    }
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _followingCount = followingCount;
      _loadingProfile = false;
    });
  }

  /// Tên hiển thị: ưu tiên "tên đăng nhập" (username, kiểu @thenhan_),
  /// nếu chưa đặt thì hiển thị "họ và tên", cuối cùng mới rơi về mặc định.
  String get _displayName {
    final username = _currentUser?.username?.trim();
    if (username != null && username.isNotEmpty) return username;
    final name = _currentUser?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return "Người dùng Shopee";
  }

  // "Bắt đầu bán": nếu tài khoản đã là seller -> vào thẳng trang quản lý
  // shop; nếu còn là buyer -> đưa tới form đăng ký kênh người bán.
  // (RoleGate tự kiểm tra quyền qua AuthService, xem widgets/role_gate.dart)
  void _openSellerChannel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleGate(
          sellerBuilder: (context, user) => SellerDashboardScreen(shopId: user.shopId!),
          buyerBuilder: (context) => const SellerRegisterScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgGrey,
      // Cho phép kéo xuống để làm mới -> cập nhật lại số "Đang theo dõi"
      // sau khi người dùng bấm theo dõi 1 shop ở màn hình khác rồi quay lại
      // (tab Profile được giữ nguyên state nhờ IndexedStack nên không tự load lại).
      child: RefreshIndicator(
        color: shopeeOrange,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrangeHeader(context),
            if (_showEmailVerify) _buildEmailVerifyCard(),
            const SizedBox(height: 8),
            _buildOrderSection(context),
            const SizedBox(height: 8),
            _buildSaleSection(),
            const SizedBox(height: 8),
            _buildUtilitiesSection(),
            const SizedBox(height: 8),
            _buildFinanceSection(),
            const SizedBox(height: 8),
            _buildOtherUtilitiesSection(),
            const SizedBox(height: 8),
            _buildSupportSection(),
            const SizedBox(height: 8),
            _buildRecommendSection(),
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }

  // =========================================================
  // ORANGE HEADER: top icons + avatar + VIP banner
  // =========================================================
  Widget _buildOrangeHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6E40), shopeeOrange],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Top bar: Bắt đầu bán + icons ----
          Row(
            children: [
              GestureDetector(
                onTap: () => _openSellerChannel(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 18, color: Colors.black87),
                      const SizedBox(width: 6),
                      const Text(
                        "Bắt đầu bán",
                        style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopeeSettingsPage()),
                  );
                },
                child: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 18),
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
              const SizedBox(width: 18),
              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Avatar + name ----
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                  );
                  _loadProfile();
                },
                child: Stack(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 66,
                        height: 66,
                        child: () {
                          final image = resolveAvatarImage(_currentUser?.avatarUrl);
                          if (image != null) {
                            return Image(image: image, fit: BoxFit.cover);
                          }
                          return const Icon(Icons.person, size: 44, color: Colors.white70);
                        }(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.edit, size: 12, color: Colors.white),
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _loadingProfile ? "Đang tải..." : _displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentUser?.membershipTier ?? "Thành viên",
                                style: const TextStyle(color: shopeeOrange, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.chevron_right, size: 13, color: shopeeOrange),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("0 Người theo", style: TextStyle(color: Colors.white, fontSize: 12.5)),
                        const SizedBox(width: 14),
                        Text(
                          "$_followingCount Đang theo dõi",
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ---- VIP voucher banner ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE1B3), Color(0xFFFFF6E5)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFF0C24B)]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text("VIP", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Nhận voucher giảm 35% cho lần đầu đăng ký",
                    style: TextStyle(color: Color(0xFF8B5A00), fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF8B5A00), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMAIL VERIFY CARD (overlapping white card)
  // =========================================================
  Widget _buildEmailVerifyCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mail_outline, color: shopeeOrange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Xác minh email",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Cập nhật email thường xuyên để đảm bảo bạn luôn có thể đăng nhập vào Shopee",
                      style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showEmailVerify = false),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text("Đổi Email", style: TextStyle(color: Colors.black87, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text("Xác minh ngay", style: TextStyle(color: Colors.black87, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ĐƠN MUA + Đơn nạp điện thoại + ShopeeFood
  // =========================================================
  Widget _buildOrderSection(BuildContext context) {
    final items = [
      {"icon": Icons.account_balance_wallet_outlined, "label": "Chờ xác nhận", "tabIndex": 1},
      {"icon": Icons.inventory_2_outlined, "label": "Chờ lấy hàng", "tabIndex": 2},
      {"icon": Icons.local_shipping_outlined, "label": "Chờ giao hàng", "tabIndex": 3},
      {"icon": Icons.star_border, "label": "Đánh giá", "tabIndex": 4},
    ];

    void openOrders(int tabIndex) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MyOrdersScreen(initialTabIndex: tabIndex)),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Đơn mua",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () => openOrders(0),
                  child: const Row(
                    children: [
                      Text(
                        "Xem lịch sử mua hàng",
                        style: TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((it) {
                return GestureDetector(
                  onTap: () => openOrders(it["tabIndex"] as int),
                  child: Column(
                    children: [
                      Icon(it["icon"] as IconData, color: Colors.black87, size: 26),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 66,
                        child: Text(
                          it["label"] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: const Icon(Icons.perm_phone_msg_outlined, color: Colors.black87, size: 22),
            title: const Text("Đơn Nạp điện thoại & Dịch vụ", style: TextStyle(fontSize: 13.5)),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("View Purchase History", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
            onTap: () {},
          ),
          Divider(height: 1, indent: 14, endIndent: 14, color: Colors.grey.shade200),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: shopeeOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 15),
            ),
            title: const Text("Đơn ShopeeFood", style: TextStyle(fontSize: 13.5)),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Đang có ưu đãi", style: TextStyle(color: shopeeOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, color: shopeeOrange, size: 18),
              ],
            ),
            onTap: () {},
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // =========================================================
  // 7.7 SIÊU SALE ĐÓN HÈ
  // =========================================================
  Widget _buildSaleSection() {
    final items = [
      {"label": "Trang Chính", "colors": const [Color(0xFFFF7A45), Color(0xFFEE4D2D)], "child": "7.7"},
      {"label": "ShopeeVIP", "colors": const [Color(0xFFEE4D2D), Color(0xFFB8860B)], "icon": Icons.emoji_events},
      {"label": "Hàng Mới Về Sàn", "colors": const [Color(0xFF223A70), Color(0xFF3E5FA6)], "icon": Icons.star},
      {"label": "Mặc Trend Sống Ch...", "colors": const [Color(0xFFEE4D2D), Color(0xFFF53D2D)], "icon": Icons.local_fire_department},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "7.7 Siêu Sale Đón Hè",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items.map((it) {
                return Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: it["colors"] as List<Color>),
                      ),
                      alignment: Alignment.center,
                      child: it.containsKey("child")
                          ? Text(
                              it["child"] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            )
                          : Icon(it["icon"] as IconData, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 74,
                      child: Text(
                        it["label"] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIỆN ÍCH CỦA TÔI
  // =========================================================
  Widget _buildUtilitiesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "Tiện ích của tôi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: _utilityItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: const Color(0xFF2E9E5B),
                    label: "Ví ShopeePay",
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: shopeeOrange),
                        minimumSize: const Size(0, 26),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text("Kích hoạt ngay", style: TextStyle(color: shopeeOrange, fontSize: 10)),
                    ),
                  ),
                ),
                Expanded(
                  child: _utilityItem(
                    icon: Icons.schedule,
                    iconColor: shopeeOrange,
                    label: "SPayLater",
                    child: const Text(
                      "Kích hoạt nhận ngay 150.000Đ",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: shopeeOrange, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: _utilityItem(
                    icon: Icons.monetization_on,
                    iconColor: shopeeOrange,
                    label: "Shopee Xu",
                    hasDot: true,
                    child: const Text(
                      "Nhấn để nhận Xu mỗi ngày!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: shopeeOrange, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: _utilityItem(
                    icon: Icons.confirmation_num_outlined,
                    iconColor: Colors.black87,
                    label: "Kho Voucher",
                    hasDot: true,
                    child: const Text(
                      "50+ Voucher",
                      style: TextStyle(color: shopeeOrange, fontSize: 10.5, fontWeight: FontWeight.w600),
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

  Widget _utilityItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    bool hasDot = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: iconColor, size: 28),
            if (hasDot)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: shopeeRed, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11.5)),
        const SizedBox(height: 6),
        SizedBox(height: 30, child: Center(child: child)),
      ],
    );
  }

  // =========================================================
  // DỊCH VỤ TÀI CHÍNH
  // =========================================================
  Widget _buildFinanceSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Dịch vụ tài chính",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Text("Xem thêm", style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                  Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _financeCard(
                  icon: Icons.bolt,
                  iconColor: Colors.white,
                  iconBg: shopeeOrange,
                  title: "Vay Tiền Nhanh",
                  subtitle: "Nhận lên đến đ50.000.000",
                  badge: "Mới",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _financeCard(
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.white,
                  iconBg: const Color(0xFF2E9E5B),
                  title: "Tải ShopeePay",
                  subtitle: "Gói voucher 1.000.000Đ",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _financeCard(
            icon: Icons.security,
            iconColor: Colors.white,
            iconBg: shopeeOrange,
            title: "Bảo hiểm của tôi",
            subtitle: "Ưu đãi 30% khi thanh toán bằng ShopeePay!",
          ),
        ],
      ),
    );
  }

  Widget _financeCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: shopeeOrange),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: shopeeRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // TIỆN ÍCH KHÁC
  // =========================================================
  Widget _buildOtherUtilitiesSection() {
    final items = [
      {"icon": Icons.workspace_premium_outlined, "label": "Khách hàng thân thiết", "color": shopeeOrange},
      {"icon": Icons.show_chart, "label": "Kênh người sáng tạo", "color": shopeeOrange},
      {"icon": Icons.swap_horizontal_circle_outlined, "label": "Số dư TK Shopee", "color": shopeeOrange},
      {"icon": Icons.card_giftcard, "label": "Săn Thưởng Shopee", "color": const Color(0xFF2F80ED)},
      {"icon": Icons.storefront_outlined, "label": "Shopee Tiếp Thị Liên Kết", "color": shopeeOrange},
      {"icon": Icons.shopping_bag_outlined, "label": "Mua lại", "color": Colors.amber.shade800},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Tiện ích khác",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Text("Xem tất cả", style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                  Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _otherUtilityCard(
                      icon: items[i]["icon"] as IconData,
                      color: items[i]["color"] as Color,
                      label: items[i]["label"] as String,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < items.length
                        ? _otherUtilityCard(
                            icon: items[i + 1]["icon"] as IconData,
                            color: items[i + 1]["color"] as Color,
                            label: items[i + 1]["label"] as String,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _otherUtilityCard({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.25),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  // =========================================================
  // HỖ TRỢ
  // =========================================================
  Widget _buildSupportSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hỗ trợ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          _supportTile(icon: Icons.help_outline, label: "Trung tâm trợ giúp"),
          Divider(height: 1, color: Colors.grey.shade200),
          _supportTile(icon: Icons.headset_mic_outlined, label: "Chăm sóc khách hàng"),
          Divider(height: 1, color: Colors.grey.shade200),
          _supportTile(icon: Icons.chat_bubble_outline, label: "Shopee Blog", hasDot: true),
        ],
      ),
    );
  }

  Widget _supportTile({required IconData icon, required String label, bool hasDot = false}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.black87, size: 22),
          if (hasDot)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: shopeeRed, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {},
    );
  }

  // =========================================================
  // CÓ THỂ BẠN CŨNG THÍCH
  // =========================================================
  Widget _buildRecommendSection() {
    final products = [
      {
        "image": "https://picsum.photos/id/26/300/300",
        "title": "Bút Deli màu học sinh 12 màu cao cấp",
        "price": "15.000",
        "originalPrice": "25.000",
        "discount": 40,
        "sold": "2,3k",
        "rating": 4.9,
      },
      {
        "image": "https://picsum.photos/id/60/300/300",
        "title": "Áo thun nam nữ form rộng phong cách Hàn Quốc",
        "price": "89.000",
        "originalPrice": "159.000",
        "discount": 44,
        "sold": "5,1k",
        "rating": 4.8,
      },
      {
        "image": "https://picsum.photos/id/96/300/300",
        "title": "Tai nghe Bluetooth không dây chống nước thể thao",
        "price": "199.000",
        "originalPrice": "399.000",
        "discount": 50,
        "sold": "10k",
        "rating": 4.7,
      },
      {
        "image": "https://picsum.photos/id/21/300/300",
        "title": "Giày sneaker nữ đế cao êm chân đi học đi làm",
        "price": "219.000",
        "originalPrice": "350.000",
        "discount": 38,
        "sold": "876",
        "rating": 4.9,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: bgGrey,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: const [
              Expanded(
                child: Divider(thickness: 1, indent: 12, endIndent: 8, color: Colors.grey),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "CÓ THỂ BẠN CŨNG THÍCH",
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) => _buildRecommendCard(products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendCard(Map<String, dynamic> p) {
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
