import 'package:flutter/material.dart';

class ShopeeNotificationPage extends StatefulWidget {
  const ShopeeNotificationPage({super.key});

  @override
  State<ShopeeNotificationPage> createState() => _ShopeeNotificationPageState();
}

class _ShopeeNotificationPageState extends State<ShopeeNotificationPage>
    with SingleTickerProviderStateMixin {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  late TabController _tabController;
  int _newIdCounter = 1000;

  // ============== DATA: ĐƠN HÀNG (mutable để hỗ trợ vuốt xoá / làm mới) ==============
  final List<Map<String, dynamic>> _orderNotis = [
    {
      "id": 1,
      "icon": Icons.local_shipping,
      "color": const Color(0xFF2E9E5B),
      "title": "Đơn hàng đã được giao thành công",
      "subtitle": "Đơn hàng #SPE23456789 của bạn đã được giao. Hãy đánh giá sản phẩm để nhận 300 Shopee Xu.",
      "time": "5 phút",
      "unread": true,
    },
    {
      "id": 2,
      "icon": Icons.local_shipping_outlined,
      "color": shopeeOrange,
      "title": "Đơn hàng đang được vận chuyển",
      "subtitle": "Shopee Express đang giao đơn hàng #SPE23456700 đến bạn, dự kiến nhận trong 2 ngày tới.",
      "time": "2 giờ",
      "unread": true,
    },
    {
      "id": 3,
      "icon": Icons.check_circle,
      "color": const Color(0xFF2E9E5B),
      "title": "Đơn hàng đã được xác nhận",
      "subtitle": "Người bán đã xác nhận và đang chuẩn bị đơn hàng #SPE23456321 của bạn.",
      "time": "1 ngày",
      "unread": false,
    },
    {
      "id": 4,
      "icon": Icons.star,
      "color": Colors.amber,
      "title": "Đánh giá sản phẩm nhận Xu",
      "subtitle": "Đánh giá 5 sản phẩm bạn vừa nhận để nhận ngay 500 Shopee Xu vào tài khoản.",
      "time": "2 ngày",
      "unread": false,
    },
  ];

  // ============== DATA: NGƯỜI BÁN ==============
  final List<Map<String, dynamic>> _sellerNotis = [
    {
      "id": 5,
      "icon": Icons.storefront,
      "color": const Color(0xFF1877F2),
      "title": "ABC Official Store",
      "subtitle": "Shop vừa gửi cho bạn 1 voucher giảm 20k, đơn tối thiểu 99k. Nhanh tay lưu lại!",
      "time": "30 phút",
      "unread": true,
    },
    {
      "id": 6,
      "icon": Icons.chat_bubble,
      "color": const Color(0xFF1877F2),
      "title": "Kho Sỉ Giá Tốt",
      "subtitle": "Đã trả lời tin nhắn của bạn về đơn hàng #SPE23456111.",
      "time": "3 giờ",
      "unread": false,
    },
    {
      "id": 7,
      "icon": Icons.storefront,
      "color": const Color(0xFF1877F2),
      "title": "Deli Official Store",
      "subtitle": "Shop đang có Flash Sale nội bộ giảm đến 50% cho tất cả sản phẩm văn phòng.",
      "time": "1 ngày",
      "unread": false,
    },
  ];

  // ============== DATA: SHOPEE ==============
  final List<Map<String, dynamic>> _shopeeNotis = [
    {
      "id": 8,
      "icon": Icons.campaign,
      "color": shopeeOrange,
      "title": "Flash Sale bắt đầu sau 2 giờ nữa!",
      "subtitle": "Hàng ngàn sản phẩm giảm đến 50%. Đặt lời nhắc để không bỏ lỡ deal hot.",
      "time": "10 phút",
      "unread": true,
    },
    {
      "id": 9,
      "icon": Icons.card_giftcard,
      "color": Colors.pinkAccent,
      "title": "Nhận ngay Voucher 50K cho đơn đầu tiên",
      "subtitle": "Áp dụng cho đơn hàng từ 0đ, nhập mã tại trang Voucher của tôi.",
      "time": "6 giờ",
      "unread": true,
    },
    {
      "id": 10,
      "icon": Icons.monetization_on,
      "color": Colors.orange,
      "title": "Bạn nhận được 100 Shopee Xu",
      "subtitle": "Cảm ơn bạn đã điểm danh 7 ngày liên tiếp trên Shopee.",
      "time": "1 ngày",
      "unread": false,
    },
    {
      "id": 11,
      "icon": Icons.privacy_tip_outlined,
      "color": Colors.grey,
      "title": "Cập nhật Chính Sách Bảo Mật",
      "subtitle": "Shopee đã cập nhật chính sách bảo mật, vui lòng xem chi tiết để biết thêm thông tin.",
      "time": "3 ngày",
      "unread": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentList {
    switch (_tabController.index) {
      case 1:
        return _sellerNotis;
      case 2:
        return _shopeeNotis;
      default:
        return _orderNotis;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(_orderNotis),
              _buildList(_sellerNotis),
              _buildList(_shopeeNotis),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TOP BAR =================
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Thông Báo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (final item in _currentList) {
                  item["unread"] = false;
                }
              });
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Row(
              children: [
                Icon(Icons.done_all, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  "Đánh dấu đã đọc",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB BAR =================
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: shopeeOrange,
        indicatorWeight: 2.5,
        labelColor: shopeeOrange,
        unselectedLabelColor: Colors.black87,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        tabs: [
          _buildTabItem(Icons.local_shipping_outlined, "Đơn Hàng", _unreadCount(_orderNotis)),
          _buildTabItem(Icons.storefront_outlined, "Người Bán", _unreadCount(_sellerNotis)),
          _buildTabItem(Icons.campaign_outlined, "Shopee", _unreadCount(_shopeeNotis)),
        ],
      ),
    );
  }

  int _unreadCount(List<Map<String, dynamic>> items) {
    return items.where((e) => e["unread"] == true).length;
  }

  Widget _buildTabItem(IconData icon, String label, int unread) {
    return Tab(
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 3),
              Text(label),
            ],
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const BoxDecoration(
                  color: shopeeOrange,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  "$unread",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= LIST (kéo để làm mới + vuốt để xoá) =================
  Widget _buildList(List<Map<String, dynamic>> items) {
    return RefreshIndicator(
      color: shopeeOrange,
      onRefresh: () => _onRefresh(items),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 420,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text("Chưa có thông báo nào", style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text("Kéo xuống để làm mới", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200, indent: 14, endIndent: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item["id"]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                  ),
                  onDismissed: (_) {
                    final removed = item;
                    setState(() {
                      items.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Đã xoá thông báo"),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: "Hoàn tác",
                          textColor: Colors.yellow,
                          onPressed: () {
                            setState(() {
                              items.insert(index, removed);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: _buildNotiTile(item),
                );
              },
            ),
    );
  }

  Future<void> _onRefresh(List<Map<String, dynamic>> items) async {
    await Future.delayed(const Duration(milliseconds: 900));
    _newIdCounter++;
    setState(() {
      items.insert(0, {
        "id": _newIdCounter,
        "icon": Icons.notifications_active,
        "color": shopeeOrange,
        "title": "Bạn có thông báo mới",
        "subtitle": "Danh sách thông báo vừa được cập nhật mới nhất cho bạn.",
        "time": "Vừa xong",
        "unread": true,
      });
    });
  }

  Widget _buildNotiTile(Map<String, dynamic> item) {
    final bool unread = item["unread"] as bool;
    return Container(
      color: unread ? const Color(0xFFFFF4F0) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item["color"] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item["icon"] as IconData, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item["title"] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item["time"] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item["subtitle"] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),
          if (unread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: shopeeOrange, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
