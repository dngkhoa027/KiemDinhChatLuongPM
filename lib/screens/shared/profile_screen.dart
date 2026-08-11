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
import '../../data/mock_data.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class ShopeeProfilePage extends StatefulWidget {
  const ShopeeProfilePage({super.key});

  @override
  State<ShopeeProfilePage> createState() => _ShopeeProfilePageState();
}

class _ShopeeProfilePageState extends State<ShopeeProfilePage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color bgGrey = Color(0xFFF5F5F5);

  bool _showEmailVerify = true;

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

  String get _displayName {
    final username = _currentUser?.username?.trim();
    if (username != null && username.isNotEmpty) return username;
    final name = _currentUser?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return "Người dùng Shopee";
  }

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

  void _openOrders(int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyOrdersScreen(initialTabIndex: tabIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgGrey,
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
              _buildUtilitiesSection(),
              const SizedBox(height: 8),
              _buildFinanceSection(),
              const SizedBox(height: 8),
              _buildOtherUtilitiesSection(context),
              const SizedBox(height: 8),
              _buildSupportSection(),
              const SizedBox(height: 8),
              _buildRecommendSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ORANGE HEADER
  // =========================================================
  Widget _buildOrangeHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7043), Color(0xFFEE4D2D)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + icons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                  );
                  _loadProfile();
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: ClipOval(
                    child: () {
                      final image = resolveAvatarImage(_currentUser?.avatarUrl);
                      if (image != null) {
                        return Image(image: image, fit: BoxFit.cover);
                      }
                      return const Icon(Icons.person, size: 36, color: Colors.white70);
                    }(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + stats
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
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentUser?.membershipTier ?? "Bạc",
                                style: const TextStyle(
                                  color: shopeeOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 13, color: shopeeOrange),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$_followingCount Đang theo dõi   0 Người theo",
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              // Right icons
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopeeSettingsPage()),
                      );
                    },
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                  ),
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
                                right: -6,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD600),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 23),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // VIP banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC9A227), Color(0xFFE8C547)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.white, size: 13),
                      SizedBox(width: 2),
                      Text(
                        "VIP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Nhận voucher giảm 35% cho lần đầu đăng ký",
                    style: TextStyle(
                      color: Color(0xFF8B5A00),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
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
  // EMAIL VERIFY CARD
  // =========================================================
  Widget _buildEmailVerifyCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mail_outline, color: shopeeOrange, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Xác minh email",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Cập nhật email thường xuyên để đảm bảo bạn luôn có thể đăng nhập vào Shopee",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showEmailVerify = false),
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 46),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF333333),
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text("Đổi Email", style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF333333),
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text("Xác minh ngay", style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ĐƠN MUA
  // =========================================================
  Widget _buildOrderSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              const Text(
                "Đơn mua",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openOrders(0),
                child: Row(
                  children: [
                    Text(
                      "Xem lịch sử mua hàng",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4 status icons — badge = số đơn thật theo trạng thái
          AnimatedBuilder(
            animation: OrderService.instance,
            builder: (context, _) {
              final svc = OrderService.instance;
              final toConfirm = svc.byStatus(OrderStatus.toConfirm).length;
              final toShip = svc.byStatus(OrderStatus.toShip).length;
              final toReceive = svc.byStatus(OrderStatus.toReceive).length;
              // Đánh giá: đơn đã giao (có thể đánh giá)
              final toReview = svc.byStatus(OrderStatus.completed).length;
              return Row(
                children: [
                  _orderStatusItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Chờ xác nhận",
                    badge: toConfirm,
                    onTap: () => _openOrders(1),
                  ),
                  _orderStatusItem(
                    icon: Icons.inventory_2_outlined,
                    label: "Chờ lấy hàng",
                    badge: toShip,
                    onTap: () => _openOrders(2),
                  ),
                  _orderStatusItem(
                    icon: Icons.local_shipping_outlined,
                    label: "Chờ giao hàng",
                    badge: toReceive,
                    onTap: () => _openOrders(3),
                  ),
                  _orderStatusItem(
                    icon: Icons.star_border_rounded,
                    label: "Đánh giá",
                    badge: toReview,
                    onTap: () => _openOrders(4),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          // Sub links
          _orderSubLink(
            icon: Icons.phone_android_outlined,
            iconColor: const Color(0xFF26A69A),
            title: "Đơn Nạp điện thoại & Dịch vụ",
            trailing: "Bạn mới giảm 50%",
            trailingColor: shopeeOrange,
          ),
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          _orderSubLink(
            icon: Icons.restaurant_outlined,
            iconColor: shopeeOrange,
            title: "Đơn ShopeeFood",
            trailing: "Đang có ưu đãi",
            trailingColor: shopeeOrange,
          ),
        ],
      ),
    );
  }

  Widget _orderStatusItem({
    required IconData icon,
    required String label,
    required int badge,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: const Color(0xFF333333)),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: shopeeOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF444444)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderSubLink({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
    required Color trailingColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333)),
            ),
          ),
          Text(trailing, style: TextStyle(fontSize: 12.5, color: trailingColor)),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
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
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 12),
            child: Text(
              "Tiện ích của tôi",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
          ),
          Row(
            children: [
              _utilityItem(
                icon: Icons.account_balance_wallet_outlined,
                label: "Ví ShopeePay",
                subtitle: "Nạp Điện Thoại chỉ\n1 Đồng",
              ),
              _utilityItem(
                icon: Icons.credit_card_outlined,
                label: "SPayLater",
                subtitle: "đ 15.000.000",
              ),
              _utilityItem(
                icon: Icons.monetization_on_outlined,
                label: "Shopee Xu",
                subtitle: "Nhấn để nhận Xu\nmỗi ngày!",
                hasDot: true,
              ),
              _utilityItem(
                icon: Icons.confirmation_number_outlined,
                label: "Kho Voucher",
                subtitle: "50+ Voucher",
                hasDot: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _utilityItem({
    required IconData icon,
    required String label,
    required String subtitle,
    bool hasDot = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 28, color: const Color(0xFF333333)),
              if (hasDot)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: shopeeOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: shopeeOrange,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DỊCH VỤ TÀI CHÍNH
  // =========================================================
  Widget _buildFinanceSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "Dịch vụ tài chính",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              const Spacer(),
              Text(
                "Xem thêm",
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _financeCard(
                  icon: Icons.account_balance_outlined,
                  iconColor: shopeeOrange,
                  title: "Vay Tiền Nhanh",
                  subtitle: "Miễn lãi kỳ đầu tiên",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _financeCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: shopeeOrange,
                  title: "Tải ShopeePay",
                  subtitle: "Gói voucher 1.000.000Đ",
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _financeCard(
            icon: Icons.verified_user_outlined,
            iconColor: shopeeOrange,
            title: "Bảo hiểm của tôi",
            subtitle: "Ưu đãi 30% khi thanh toán bằng ShopeePay!",
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _financeCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // =========================================================
  // TIỆN ÍCH KHÁC
  // =========================================================
  Widget _buildOtherUtilitiesSection(BuildContext context) {
    final items = [
      (Icons.storefront_outlined, "Bắt đầu bán"),
      (Icons.card_membership_outlined, "Khách hàng thân thiết"),
      (Icons.live_tv_outlined, "Kênh người sáng tạo"),
      (Icons.account_balance_outlined, "Số dư TK Shopee"),
      (Icons.card_giftcard_outlined, "Săn Thưởng Shopee"),
      (Icons.campaign_outlined, "Shopee Tiếp Thị Liên Kết"),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "Tiện ích khác",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              const Spacer(),
              Text(
                "Xem tất cả",
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return GestureDetector(
                onTap: i == 0 ? () => _openSellerChannel(context) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$1, size: 20, color: shopeeOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              );
            },
          ),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hỗ trợ",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          _supportTile(icon: Icons.help_outline, label: "Trung tâm trợ giúp"),
          _supportTile(icon: Icons.headset_mic_outlined, label: "Chăm sóc khách hàng"),
          _supportTile(icon: Icons.article_outlined, label: "Shopee Blog"),
        ],
      ),
    );
  }

  Widget _supportTile({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF444444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // =========================================================
  // CÓ THỂ BẠN CŨNG THÍCH
  // =========================================================
  Widget _buildRecommendSection() {
    final products = MockData.homeProducts.take(6).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.7)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Có thể bạn cũng thích",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.7)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.66,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => _recommendCard(products[i]),
          ),
        ),
      ],
    );
  }

  Widget _recommendCard(Map<String, dynamic> p) {
    final discount = p['discount'] as int? ?? 0;
    final title = p['title'] as String? ?? '';
    final price = p['price'] as String? ?? '';
    final image = p['image'] as String? ?? '';
    final sold = p['sold'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: const Color(0xFFFFF0E5),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: shopeeOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.25),
                  ),
                  const Spacer(),
                  Text(
                    '${price}đ',
                    style: const TextStyle(
                      color: shopeeOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sold.isNotEmpty)
                    Text(
                      '$sold đã bán',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
