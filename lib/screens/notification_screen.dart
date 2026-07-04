import 'package:flutter/material.dart';
import 'cart_screen.dart';

class ShopeeNotificationPage extends StatefulWidget {
  const ShopeeNotificationPage({super.key});

  @override
  State<ShopeeNotificationPage> createState() => _ShopeeNotificationPageState();
}

class _ShopeeNotificationPageState extends State<ShopeeNotificationPage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);
  static const Color teal = Color(0xFF17A398);

  int _selectedTab = 0;

  // ============== DATA: 5 TAB ICON ==============
  final List<Map<String, dynamic>> _tabs = const [
    {"icon": Icons.thumb_up_alt_rounded, "label": "Thông báo nổi\nbật", "badgeCount": 10},
    {"icon": Icons.local_offer_outlined, "label": "Khuyến mãi", "badgeDot": true},
    {"icon": Icons.live_tv_outlined, "label": "Live, Video &\nThưởng", "badgeDot": true},
    {"icon": Icons.account_balance_wallet_outlined, "label": "Thông tin Tài\nchính", "badgeDot": true},
    {"icon": Icons.shopping_bag_outlined, "label": "Cập nhật\nShopee", "badgeDot": true},
  ];

  // ============== DATA: THÔNG BÁO NỔI BẬT (có banner freeship) ==============
  final List<Map<String, dynamic>> _highlightNotis = const [
    {
      "icon": Icons.local_shipping,
      "iconBg": teal,
      "title": "Mã freeship cho đơn từ 0Đ có sẵn trong ví 😍",
      "subtitle":
          "⏰ Mã sẽ hết hạn vào 08-07-2026! Áp dụng cho đơn từ 0Đ🤑\n🛒 Voucher freeship có sẵn trong ví, dùng ngay kẻo lỡ!",
      "hasBanner": true,
      "secondaryLabel": "Dành cho bạn",
      "time": "13:24 02-07-2026",
    },
    {
      "icon": Icons.local_shipping,
      "iconBg": teal,
      "title": "⏰ Mau mau sử dụng mã freeship đơn từ 0Đ",
      "subtitle":
          "🛒 Nhanh tay kẻo lỡ mã freeship cho đơn từ 0Đ\n⏰ Mã sẽ hết hạn vào 30-06-2026! Số lượng có hạn.",
      "hasBanner": true,
      "secondaryLabel": "Sắp hết hạn",
      "time": "13:45 29-06-2026",
    },
    {
      "icon": Icons.campaign,
      "iconBg": shopeeOrange,
      "title": "📣 Bạn yêu ơi!",
      "subtitle": "Shopee đang có chương trình ưu đãi cực lớn dành riêng cho bạn, đừng bỏ lỡ nhé!",
      "hasBanner": false,
      "time": "2 ngày trước",
    },
  ];

  // ============== DATA: KHUYẾN MÃI ==============
  final List<Map<String, dynamic>> _promoNotis = const [
    {
      "icon": Icons.card_giftcard,
      "iconBg": Colors.pinkAccent,
      "title": "Nhận ngay Voucher 50K cho đơn đầu tiên",
      "subtitle": "Áp dụng cho đơn hàng từ 0đ, nhập mã tại trang Voucher của tôi.",
      "hasBanner": false,
      "time": "6 giờ trước",
    },
    {
      "icon": Icons.local_fire_department,
      "iconBg": shopeeOrange,
      "title": "Flash Sale bắt đầu sau 2 giờ nữa!",
      "subtitle": "Hàng ngàn sản phẩm giảm đến 50%. Đặt lời nhắc để không bỏ lỡ deal hot.",
      "hasBanner": false,
      "time": "10 phút trước",
    },
  ];

  // ============== DATA: LIVE, VIDEO & THƯỞNG ==============
  final List<Map<String, dynamic>> _liveNotis = const [
    {
      "icon": Icons.videocam,
      "iconBg": Color(0xFF9B51E0),
      "title": "Phiên Live sắp bắt đầu!",
      "subtitle": "Shop yêu thích của bạn sẽ Live sau 15 phút nữa, vào xem để nhận Xu ngay.",
      "hasBanner": false,
      "time": "15 phút trước",
    },
  ];

  // ============== DATA: THÔNG TIN TÀI CHÍNH ==============
  final List<Map<String, dynamic>> _financeNotis = const [
    {
      "icon": Icons.account_balance_wallet,
      "iconBg": Color(0xFF2E9E5B),
      "title": "Hoàn tiền vào ví ShopeePay",
      "subtitle": "Bạn vừa được hoàn 15.000đ vào ví ShopeePay từ đơn hàng đã huỷ.",
      "hasBanner": false,
      "time": "1 ngày trước",
    },
  ];

  // ============== DATA: CẬP NHẬT SHOPEE ==============
  final List<Map<String, dynamic>> _systemNotis = const [
    {
      "icon": Icons.privacy_tip_outlined,
      "iconBg": Colors.grey,
      "title": "Cập nhật Chính Sách Bảo Mật",
      "subtitle": "Shopee đã cập nhật chính sách bảo mật, vui lòng xem chi tiết để biết thêm thông tin.",
      "hasBanner": false,
      "time": "3 ngày trước",
    },
  ];

  List<Map<String, dynamic>> get _currentList {
    switch (_selectedTab) {
      case 1:
        return _promoNotis;
      case 2:
        return _liveNotis;
      case 3:
        return _financeNotis;
      case 4:
        return _systemNotis;
      default:
        return _highlightNotis;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(
          child: RefreshIndicator(
            color: shopeeOrange,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader(),
                _buildTabIconsRow(),
                Container(height: 8, color: const Color(0xFFFDF3F1)),
                ..._currentList.map((item) => Column(
                      children: [
                        _buildNotiCard(item),
                        Divider(height: 1, color: Colors.grey.shade200),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TOP BAR =================
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            "Thông báo",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          Positioned(
            right: 0,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopeeCartPage()),
                    );
                  },
                  child: const Icon(Icons.shopping_cart_outlined, color: shopeeRed, size: 26),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.chat_bubble_outline, color: shopeeRed, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION HEADER =================
  Widget _buildSectionHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "Cập nhật mới nhất",
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
          ),
          Text(
            "Đọc Tất Cả",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= TAB ICONS ROW =================
  Widget _buildTabIconsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final t = _tabs[index];
          final bool selected = index == _selectedTab;
          final Color mainColor = selected ? shopeeOrange : Colors.black87;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(t["icon"] as IconData, size: 28, color: mainColor),
                      if (t["badgeCount"] != null)
                        Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: const BoxDecoration(color: shopeeRed, shape: BoxShape.circle),
                            child: Text(
                              "${t["badgeCount"]}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else if (t["badgeDot"] == true)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: shopeeRed, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t["label"] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: selected ? shopeeOrange : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2.5,
                    width: 34,
                    color: selected ? shopeeOrange : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ================= NOTI CARD =================
  Widget _buildNotiCard(Map<String, dynamic> item) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item["iconBg"] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item["icon"] as IconData, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"] as String,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["subtitle"] as String,
                      style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item["hasBanner"] == true) ...[
            const SizedBox(height: 12),
            _buildFreeshipBanner(item["secondaryLabel"] as String),
            const SizedBox(height: 8),
            Text(
              item["time"] as String,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              item["time"] as String,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  // ================= BANNER MÃ FREESHIP =================
  Widget _buildFreeshipBanner(String secondaryLabel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bên trái: nền teal + icon xe tải
            Expanded(
              flex: 4,
              child: Container(
                color: teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping, color: Colors.white, size: 46),
                    SizedBox(height: 10),
                    Text(
                      "Free\nShipping",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
            // Bên phải: nền trắng + nội dung
            Expanded(
              flex: 6,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 14, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            "Bạn có mã Freeship\ncho đơn từ 0K!",
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.25),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: shopeeRed),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            secondaryLabel,
                            style: const TextStyle(color: shopeeRed, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: shopeeOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Dùng ngay!",
                            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
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
}