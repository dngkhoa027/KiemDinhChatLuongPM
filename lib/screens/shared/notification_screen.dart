import 'package:flutter/material.dart';
import '../buyer/cart_screen.dart';
import '../../data/mock_data.dart';
import '../../services/cart_service.dart';

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
  // Dữ liệu lấy từ lib/data/mock_data.dart -> sau này thay bằng API tại đây
  final List<Map<String, dynamic>> _tabs = MockData.notificationTabs;

  // ============== DATA: THÔNG BÁO NỔI BẬT (có banner freeship) ==============
  final List<Map<String, dynamic>> _highlightNotis = MockData.notificationHighlight;

  // ============== DATA: KHUYẾN MÃI ==============
  final List<Map<String, dynamic>> _promoNotis = MockData.notificationPromo;

  // ============== DATA: LIVE, VIDEO & THƯỞNG ==============
  final List<Map<String, dynamic>> _liveNotis = MockData.notificationLive;

  // ============== DATA: THÔNG TIN TÀI CHÍNH ==============
  final List<Map<String, dynamic>> _financeNotis = MockData.notificationFinance;

  // ============== DATA: CẬP NHẬT SHOPEE ==============
  final List<Map<String, dynamic>> _systemNotis = MockData.notificationSystem;

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
    // Lưu ý: trước đây dùng Stack đặt trực tiếp trong Container không có
    // width tường minh -> Stack chỉ co lại bằng đúng kích thước chữ
    // "Thông báo" (child không Positioned duy nhất), khiến Positioned(right:0)
    // tính theo bề rộng đó và đẩy icon đè lên ngay sát chữ.
    // Cách sửa: bọc width: double.infinity cho Container ngoài cùng và
    // SizedBox full width cho Stack để Stack thực sự rộng bằng cả hàng,
    // từ đó Positioned(right: 0) mới nằm đúng ở mép phải màn hình.
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: SizedBox(
        width: double.infinity,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                "Thông báo",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            const Icon(Icons.shopping_cart_outlined, color: shopeeRed, size: 26),
                            if (count > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  constraints: const BoxConstraints(minWidth: 16),
                                  decoration: BoxDecoration(
                                    color: shopeeRed,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1),
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
                  const Icon(Icons.chat_bubble_outline, color: shopeeRed, size: 26),
                ],
              ),
            ),
          ],
        ),
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: shopeeRed),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                secondaryLabel,
                                maxLines: 1,
                                style: const TextStyle(color: shopeeRed, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: shopeeOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                "Dùng ngay!",
                                maxLines: 1,
                                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
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