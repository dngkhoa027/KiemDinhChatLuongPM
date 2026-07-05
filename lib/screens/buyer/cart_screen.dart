import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cart_models.dart';
import '../../models/address_model.dart';
import '../../services/cart_service.dart';
import '../../services/address_service.dart';
import '../../widgets/shop_avatar.dart';
import '../shared/address_book_screen.dart';

/// Trang Giỏ Hàng kiểu Shopee.
///
/// Viết lại gọn, đơn giản hoá cấu trúc widget để dễ bảo trì và tránh các
/// lỗi hiển thị (ẩn chữ, ảnh vỡ, layout lệch...). Dữ liệu lấy trực tiếp từ
/// [CartService.instance] — nguồn dữ liệu giỏ hàng dùng chung toàn app.
class ShopeeCartPage extends StatefulWidget {
  const ShopeeCartPage({super.key});

  @override
  State<ShopeeCartPage> createState() => _ShopeeCartPageState();
}

class _ShopeeCartPageState extends State<ShopeeCartPage> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color mallRed = Color(0xFFD0011B);
  static const Color pageBg = Color(0xFFF2F3F5);
  static const Color green = Color(0xFF2E9E5B);

  bool _editMode = false;

  Address? _shippingAddress;
  bool _addressLoading = true;

  @override
  void initState() {
    super.initState();
    CartService.instance.addListener(_onCartChanged);
    _loadAddress();
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  // Lấy địa chỉ giao hàng thật từ sổ địa chỉ (mục "Địa chỉ" trong Cài đặt):
  // ưu tiên địa chỉ mặc định, nếu chưa đặt mặc định thì lấy địa chỉ đầu tiên.
  Future<void> _loadAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _addressLoading = false);
      return;
    }
    setState(() => _addressLoading = true);
    final list = await AddressService.instance.fetchAddresses(uid);
    if (!mounted) return;
    setState(() {
      _shippingAddress = list.isEmpty ? null : list.first;
      _addressLoading = false;
    });
  }

  Future<void> _openAddressBook() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
    _loadAddress(); // Sau khi quay lại (vừa thêm/sửa/đổi mặc định) thì tải lại
  }

  // ============== DỮ LIỆU ==============
  List<CartShop> get _shops => CartService.instance.shops;

  List<CartItem> get _allItems => _shops.expand((s) => s.items).toList();

  bool get _isCartEmpty => _allItems.isEmpty;

  bool get _allSelected => _allItems.isNotEmpty && _allItems.every((i) => i.selected);

  int get _selectedCount => _allItems.where((i) => i.selected).length;

  int get _selectedTotal =>
      _allItems.where((i) => i.selected).fold(0, (sum, i) => sum + i.price * i.quantity);

  int get _selectedSavings => _allItems
      .where((i) => i.selected)
      .fold(0, (sum, i) => sum + (i.originalPrice - i.price) * i.quantity);

  static String _money(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      out.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) out.write('.');
    }
    return out.toString();
  }

  // ============== HÀNH ĐỘNG ==============
  void _setAllSelected(bool value) {
    setState(() {
      for (final shop in _shops) {
        for (final item in shop.items) {
          item.selected = value;
        }
      }
    });
    CartService.instance.refresh();
  }

  void _setShopSelected(CartShop shop, bool value) {
    setState(() {
      for (final item in shop.items) {
        item.selected = value;
      }
    });
    CartService.instance.refresh();
  }

  void _setItemSelected(CartItem item, bool value) {
    setState(() => item.selected = value);
    CartService.instance.refresh();
  }

  void _changeQuantity(CartItem item, int delta) {
    setState(() {
      final next = item.quantity + delta;
      if (next >= 1) item.quantity = next;
    });
    CartService.instance.refresh();
  }

  void _removeItem(CartShop shop, CartItem item) {
    setState(() {
      shop.items.remove(item);
      _shops.removeWhere((s) => s.items.isEmpty);
    });
    CartService.instance.refresh();
  }

  void _removeSelected() {
    setState(() {
      for (final shop in _shops) {
        shop.items.removeWhere((i) => i.selected);
      }
      _shops.removeWhere((s) => s.items.isEmpty);
      _editMode = false;
    });
    CartService.instance.refresh();
  }

  // ============== GIAO DIỆN ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Giỏ Hàng (${_allItems.length})'),
        actions: [
          if (!_isCartEmpty)
            TextButton(
              onPressed: () => setState(() => _editMode = !_editMode),
              child: Text(
                _editMode ? 'Xong' : 'Sửa',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isCartEmpty ? _buildEmptyState() : _buildItemList(),
      ),
      bottomNavigationBar: _isCartEmpty ? null : _buildBottomBar(),
    );
  }

  // ---------------- Trạng thái trống ----------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 96, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            '"Hổng" có gì trong giỏ hết',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Lướt Shopee, lựa hàng ngay đi!',
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: orange,
              side: const BorderSide(color: orange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Mua sắm ngay!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------- Danh sách sản phẩm ----------------
  Widget _buildItemList() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _buildAddressBar(),
        const SizedBox(height: 8),
        for (final shop in _shops) _buildShopCard(shop),
        const SizedBox(height: 8),
        _buildVoucherRow(),
        const SizedBox(height: 8),
        _buildShippingNote(),
      ],
    );
  }

  Widget _buildAddressBar() {
    if (_addressLoading) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: orange)),
            SizedBox(width: 12),
            Text('Đang tải địa chỉ...', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
          ],
        ),
      );
    }

    final address = _shippingAddress;

    // Chưa có địa chỉ nào trong sổ địa chỉ -> mời thêm, bấm vào đi thẳng
    // tới trang "Địa chỉ" ở Cài đặt (AddressBookScreen).
    if (address == null) {
      return InkWell(
        onTap: _openAddressBook,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: const Row(
            children: [
              Icon(Icons.location_on_outlined, color: orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thêm địa chỉ nhận hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: orange),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    // Có địa chỉ -> hiển thị dữ liệu thật lấy từ sổ địa chỉ.
    return InkWell(
      onTap: _openAddressBook,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${address.fullName}  ${address.phone}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(CartShop shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShopHeader(shop),
          const Divider(height: 1),
          for (final item in shop.items) _buildProductRow(shop, item),
        ],
      ),
    );
  }

  Widget _buildShopHeader(CartShop shop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: [
          Checkbox(
            value: shop.allSelected,
            activeColor: orange,
            onChanged: (v) => _setShopSelected(shop, v ?? false),
          ),
          ShopAvatar(shopName: shop.shopName, radius: 10),
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
              decoration: BoxDecoration(color: mallRed, borderRadius: BorderRadius.circular(2)),
              child: const Text('Mall', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildProductRow(CartShop shop, CartItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            activeColor: orange,
            onChanged: (v) => _setItemSelected(item, v ?? false),
          ),
          _buildProductImage(item.image),
          const SizedBox(width: 8),
          Expanded(child: _buildProductInfo(shop, item)),
        ],
      ),
    );
  }

  Widget _buildProductImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 76,
        height: 76,
        color: pageBg,
        child: url.isEmpty
            ? Icon(Icons.image_outlined, color: Colors.grey.shade400)
            : Image.network(
                url,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400),
              ),
      ),
    );
  }

  Widget _buildProductInfo(CartShop shop, CartItem item) {
    final name = item.name.trim().isEmpty ? 'Sản phẩm' : item.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, height: 1.25, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        if (item.variant.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: pageBg, borderRadius: BorderRadius.circular(3)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.variant, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.grey),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    '₫${_money(item.price)}',
                    style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (item.originalPrice > item.price) ...[
                    const SizedBox(width: 6),
                    Text(
                      '₫${_money(item.originalPrice)}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10.5,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildQuantityStepper(item),
          ],
        ),
        if (_editMode) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _removeItem(shop, item),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text('Xóa', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantityStepper(CartItem item) {
    return Container(
      height: 26,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperBtn(Icons.remove, item.quantity > 1 ? () => _changeQuantity(item, -1) : null),
          Container(
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text('${item.quantity}', style: const TextStyle(fontSize: 12)),
          ),
          _stepperBtn(Icons.add, () => _changeQuantity(item, 1)),
        ],
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(icon, size: 13, color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade700),
      ),
    );
  }

  Widget _buildVoucherRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFFFFF0EC), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.confirmation_num_outlined, color: orange, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Shopee Voucher', style: TextStyle(fontSize: 13))),
          const Text('Chọn hoặc nhập mã', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildShippingNote() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: const Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('Miễn phí vận chuyển cho đơn hàng từ ₫0', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  // ---------------- Thanh dưới cùng ----------------
  Widget _buildBottomBar() {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: _allSelected,
                activeColor: orange,
                onChanged: (v) => _setAllSelected(v ?? false),
              ),
              const Text('Tất Cả', style: TextStyle(fontSize: 13)),
              const Spacer(),
              if (_editMode)
                _buildDeleteButton()
              else
                _buildCheckoutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final hasSelection = _selectedCount > 0;
    return ElevatedButton(
      onPressed: hasSelection ? _removeSelected : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade200,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: Text('Xóa ($_selectedCount)', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCheckoutSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tổng cộng: ', style: TextStyle(fontSize: 11.5)),
                Text(
                  '₫${_money(_selectedTotal)}',
                  style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            if (_selectedSavings > 0)
              Text('Tiết kiệm ₫${_money(_selectedSavings)}', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _selectedCount == 0
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chuyển đến trang thanh toán...'), duration: Duration(seconds: 1)),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          child: Text('Mua Hàng ($_selectedCount)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
