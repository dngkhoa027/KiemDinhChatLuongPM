import 'package:flutter/material.dart';

class CartItem {
  final String image;
  final String name;
  final String variant;
  final int price;
  final int originalPrice;
  final bool freeship;
  int quantity;
  bool selected;

  CartItem({
    required this.image,
    required this.name,
    required this.variant,
    required this.price,
    required this.originalPrice,
    this.freeship = false,
    this.quantity = 1,
    this.selected = true,
  });
}

class CartShop {
  final String shopName;
  final bool isMall;
  final bool isFavorite;
  final List<CartItem> items;

  CartShop({
    required this.shopName,
    required this.items,
    this.isMall = false,
    this.isFavorite = false,
  });

  bool get allSelected => items.every((i) => i.selected);
}

class ShopeeCartPage extends StatefulWidget {
  const ShopeeCartPage({super.key});

  @override
  State<ShopeeCartPage> createState() => _ShopeeCartPageState();
}

class _ShopeeCartPageState extends State<ShopeeCartPage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color mallRed = Color(0xFFD0011B);
  static const Color bgGrey = Color(0xFFF2F3F5);

  bool _editMode = false;
  bool _showPromoBanner = true;

  late List<CartShop> _shops = [
    CartShop(
      shopName: "tech.zone",
      isMall: true,
      items: [
        CartItem(
          image: "https://picsum.photos/id/96/300/300",
          name: "Tai nghe Bluetooth không dây chống nước thể thao",
          variant: "Màu: Đen",
          price: 199000,
          originalPrice: 399000,
          quantity: 1,
          freeship: true,
        ),
        CartItem(
          image: "https://picsum.photos/id/60/300/300",
          name: "Cáp sạc nhanh USB-C 100W dài 2m bọc dù",
          variant: "Loại: 2m",
          price: 59000,
          originalPrice: 99000,
          quantity: 2,
          freeship: true,
        ),
      ],
    ),
    CartShop(
      shopName: "fashion.style",
      isFavorite: true,
      items: [
        CartItem(
          image: "https://picsum.photos/id/21/300/300",
          name: "Giày sneaker nữ đế cao êm chân đi học đi làm",
          variant: "Size: 38 / Trắng",
          price: 219000,
          originalPrice: 350000,
          quantity: 1,
        ),
      ],
    ),
    CartShop(
      shopName: "home.living.vn",
      items: [
        CartItem(
          image: "https://picsum.photos/id/48/300/300",
          name: "Balo laptop chống nước chống trộm đa năng",
          variant: "Màu: Xám",
          price: 175000,
          originalPrice: 280000,
          quantity: 1,
          selected: false,
        ),
      ],
    ),
  ];

  // ============== HELPERS ==============
  List<CartItem> get _allItems => _shops.expand((s) => s.items).toList();

  bool get _allSelected => _allItems.isNotEmpty && _allItems.every((i) => i.selected);

  int get _selectedCount => _allItems.where((i) => i.selected).length;

  int get _totalPrice => _allItems
      .where((i) => i.selected)
      .fold(0, (sum, i) => sum + i.price * i.quantity);

  int get _totalSavings => _allItems
      .where((i) => i.selected)
      .fold(0, (sum, i) => sum + (i.originalPrice - i.price) * i.quantity);

  String _formatPrice(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromRight = s.length - i;
      buffer.write(s[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  void _toggleAll(bool value) {
    setState(() {
      for (final shop in _shops) {
        for (final item in shop.items) {
          item.selected = value;
        }
      }
    });
  }

  void _toggleShop(CartShop shop, bool value) {
    setState(() {
      for (final item in shop.items) {
        item.selected = value;
      }
    });
  }

  void _changeQuantity(CartItem item, int delta) {
    setState(() {
      final newQty = item.quantity + delta;
      if (newQty >= 1) item.quantity = newQty;
    });
  }

  void _deleteItem(CartShop shop, CartItem item) {
    final shopIndex = _shops.indexOf(shop);
    final itemIndex = shop.items.indexOf(item);
    setState(() {
      shop.items.remove(item);
      _shops.removeWhere((s) => s.items.isEmpty);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Đã xóa sản phẩm khỏi giỏ hàng"),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "HOÀN TÁC",
          textColor: Colors.yellow,
          onPressed: () {
            setState(() {
              if (shopIndex <= _shops.length) {
                final targetShop = _shops.firstWhere(
                  (s) => s.shopName == shop.shopName,
                  orElse: () {
                    _shops.insert(shopIndex.clamp(0, _shops.length), shop);
                    return shop;
                  },
                );
                final insertAt = itemIndex.clamp(0, targetShop.items.length);
                targetShop.items.insert(insertAt, item);
              }
            });
          },
        ),
      ),
    );
  }

  void _deleteSelected() {
    setState(() {
      for (final shop in _shops) {
        shop.items.removeWhere((i) => i.selected);
      }
      _shops.removeWhere((s) => s.items.isEmpty);
      _editMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _allItems.isEmpty;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: shopeeOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text("Giỏ Hàng (${_allItems.length})"),
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: () => setState(() => _editMode = !_editMode),
              child: Text(
                _editMode ? "Xong" : "Sửa",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
        ],
      ),
      body: isEmpty ? _buildEmptyCart(context) : _buildCartBody(),
      bottomNavigationBar: isEmpty ? null : _buildBottomBar(),
    );
  }

  // ================= EMPTY CART =================
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 90, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Giỏ hàng của bạn còn trống",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: shopeeOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const Text("Mua Sắm Ngay"),
          ),
        ],
      ),
    );
  }

  // ================= CART BODY =================
  Widget _buildCartBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        if (_showPromoBanner) _buildPromoBanner(),
        _buildAddressBar(),
        const SizedBox(height: 8),
        for (final shop in _shops) _buildShopGroup(shop),
        const SizedBox(height: 8),
        _buildVoucherTicket(),
        const SizedBox(height: 8),
        _buildNoteRow(),
      ],
    );
  }

  // ================= PROMO BANNER =================
  Widget _buildPromoBanner() {
    return Container(
      color: const Color(0xFFFFF0EC),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: shopeeOrange, size: 16),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              "Bạn có 2 voucher sắp hết hạn, dùng ngay kẻo lỡ!",
              style: TextStyle(fontSize: 11.5, color: shopeeOrange, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showPromoBanner = false),
            child: const Icon(Icons.close, size: 15, color: shopeeOrange),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: shopeeOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Nguyễn Văn A  (+84) 912 345 678",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 3),
                Text(
                  "123 Đường Nguyễn Trãi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // ================= SHOP GROUP =================
  Widget _buildShopGroup(CartShop shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
            child: Row(
              children: [
                Checkbox(
                  value: shop.allSelected,
                  activeColor: shopeeOrange,
                  onChanged: (v) => _toggleShop(shop, v ?? false),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: shopeeOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    shop.shopName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                if (shop.isMall) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: mallRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      "Mall",
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                    ),
                  ),
                ] else if (shop.isFavorite) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: shopeeOrange),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      "Yêu Thích",
                      style: TextStyle(color: shopeeOrange, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                const Spacer(),
                Icon(Icons.chat_bubble_outline, size: 17, color: Colors.grey.shade600),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          for (final item in shop.items) ...[
            _buildItemRow(shop, item),
            if (item != shop.items.last) Divider(height: 1, indent: 12, endIndent: 12, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }

  // ================= ITEM ROW (swipe-to-delete) =================
  Widget _buildItemRow(CartShop shop, CartItem item) {
    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _deleteItem(shop, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.selected,
              activeColor: shopeeOrange,
              onChanged: (v) => setState(() => item.selected = v ?? false),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
                child: Image.network(
                  item.image,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.25),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgGrey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.variant,
                              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                      if (item.freeship) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2E9E5B)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            "Freeship Xtra",
                            style: TextStyle(fontSize: 9, color: Color(0xFF2E9E5B), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              "₫${_formatPrice(item.price)}",
                              style: const TextStyle(
                                color: shopeeOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "₫${_formatPrice(item.originalPrice)}",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10.5,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildQuantityStepper(item),
                    ],
                  ),
                  if (_editMode) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _deleteItem(shop, item),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 15, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Text("Xóa", style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= QUANTITY STEPPER (Shopee style) =================
  Widget _buildQuantityStepper(CartItem item) {
    final bool minusDisabled = item.quantity <= 1;
    return Container(
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            Icons.remove,
            minusDisabled ? null : () => _changeQuantity(item, -1),
          ),
          Container(
            width: 30,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text("${item.quantity}", style: const TextStyle(fontSize: 12)),
          ),
          _stepperButton(Icons.add, () => _changeQuantity(item, 1)),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, size: 12, color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade700),
      ),
    );
  }

  // ================= VOUCHER TICKET =================
  Widget _buildVoucherTicket() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.confirmation_num, color: shopeeOrange, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text("Shopee Voucher", style: TextStyle(fontSize: 13)),
          ),
          const Text(
            "Chọn Voucher",
            style: TextStyle(color: Colors.grey, fontSize: 12.5),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildNoteRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: const Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: Color(0xFF2E9E5B), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Miễn phí vận chuyển cho đơn hàng từ ₫0",
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleAll(!_allSelected),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _allSelected,
                      activeColor: shopeeOrange,
                      onChanged: (v) => _toggleAll(v ?? false),
                    ),
                    const Text("Tất Cả", style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              const Spacer(),
              if (_editMode)
                TextButton(
                  onPressed: _selectedCount == 0 ? null : _deleteSelected,
                  style: TextButton.styleFrom(
                    backgroundColor: _selectedCount == 0 ? Colors.grey.shade200 : Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: Text(
                    "Xóa (${_selectedCount})",
                    style: TextStyle(
                      color: _selectedCount == 0 ? Colors.grey.shade500 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Text("Tổng cộng: ", style: TextStyle(fontSize: 11.5)),
                        Text(
                          "₫${_formatPrice(_totalPrice)}",
                          style: const TextStyle(
                            color: shopeeOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_totalSavings > 0)
                      Text(
                        "Tiết kiệm ₫${_formatPrice(_totalSavings)}",
                        style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _selectedCount == 0
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Chuyển đến trang thanh toán..."),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shopeeOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: Text(
                    "Mua Hàng (${_selectedCount})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
