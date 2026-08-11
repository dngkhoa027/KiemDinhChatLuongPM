import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/address_model.dart';
import '../../models/voucher_model.dart';
import '../../models/cart_models.dart';
import '../../models/product_model.dart';
import '../../services/address_service.dart';
import '../../data/mock_data.dart';
import '../shared/address_book_screen.dart';
import '../shared/voucher_selection_screen.dart';
import 'payment_method_screen.dart';
import 'payment_processing_screen.dart';

class CheckoutScreen extends StatefulWidget {
  /// Danh sách sản phẩm sẽ đặt hàng — có thể là 1 sản phẩm (mua ngay từ
  /// trang chi tiết sản phẩm / livestream) hoặc nhiều sản phẩm/nhiều shop
  /// (bấm "Mua Hàng" ở trang Giỏ hàng).
  final List<CheckoutLineItem> items;

  const CheckoutScreen({
    super.key,
    required this.items,
  });

  /// Mua ngay 1 sản phẩm duy nhất (trang chi tiết sản phẩm, livestream...).
  factory CheckoutScreen.buyNow({
    Key? key,
    required String shopName,
    required String image,
    required String productName,
    required int price,
    required int originalPrice,
    required int quantity,
    String? variant,
    bool isMall = false,
    String category = '',
  }) {
    return CheckoutScreen(
      key: key,
      items: [
        CheckoutLineItem(
          shopName: shopName,
          image: image,
          name: productName,
          variant: variant ?? '',
          price: price,
          originalPrice: originalPrice,
          quantity: quantity,
          isMall: isMall,
          category: category,
        ),
      ],
    );
  }

  /// Thanh toán các sản phẩm ĐANG ĐƯỢC CHỌN trong Giỏ hàng (nút "Mua Hàng"
  /// ở trang Giỏ hàng / Giỏ hàng live).
  factory CheckoutScreen.fromCart(List<CartShop> shops) {
    return CheckoutScreen(items: CheckoutLineItem.fromSelectedCart(shops));
  }

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color green = Color(0xFF26A69A);
  static const Color pageBg = Color(0xFFF5F5F5);
  static const Color subText = Color(0xFF757575);

  Address? _address;
  bool _addressLoading = true;
  bool _placing = false;

  bool _useShopeeXu = false;
  int _installmentMonths = 1; // 1, 2, 3
  PaymentMethod _selectedPaymentMethod = findPaymentMethodById('spaylater');

  /// Các sản phẩm (điện thoại/laptop/máy tính bảng...) mà người dùng đã
  /// tick chọn mua thêm "Bảo hiểm thiết bị di động nâng cao".
  final Set<CheckoutLineItem> _insuredItems = {};

  static const int insurancePrice = 322399;
  static const int shippingFee = 20100;
  static const int shopeeXuAvailable = 1400;

  /// Tên shop hiển thị ở phần Voucher của Shop — khi giỏ hàng có nhiều
  /// shop cùng lúc, lấy shop đầu tiên làm đại diện (giống hành vi Shopee
  /// thật khi vẫn cho áp 1 voucher/lần dù đơn có nhiều shop).
  String get _primaryShopName =>
      widget.items.isNotEmpty ? widget.items.first.shopName : 'Shop';

  /// Danh sách sản phẩm nhóm theo shop, giữ nguyên thứ tự xuất hiện.
  late final List<MapEntry<String, List<CheckoutLineItem>>> _itemsByShop = () {
    final map = <String, List<CheckoutLineItem>>{};
    for (final item in widget.items) {
      map.putIfAbsent(item.shopName, () => []).add(item);
    }
    return map.entries.toList();
  }();

  // ===== Voucher / mã giảm giá =====
  late final List<Voucher> _shopVouchers = MockData.shopVouchers(_primaryShopName);
  final List<Voucher> _platformVouchers = MockData.platformVouchers;
  Voucher? _selectedShopVoucher;
  Voucher? _selectedPlatformFreeship;
  Voucher? _selectedPlatformDiscount;

  // Shipping / message / e-invoice
  String _shippingMethod = 'Hôm Nay 21:00';
  String _shopMessage = '';
  bool _requestEInvoice = false;

  int get shopVoucherDiscount =>
      _selectedShopVoucher?.calcDiscount(itemsTotal) ?? 0;
  int get platformFreeshipDiscount =>
      _selectedPlatformFreeship?.calcDiscount(itemsTotal) ?? 0;
  int get platformDiscountVoucher =>
      _selectedPlatformDiscount?.calcDiscount(itemsTotal) ?? 0;
  int get platformVoucherDiscount => platformFreeshipDiscount + platformDiscountVoucher;
  int get totalVoucherDiscount => shopVoucherDiscount + platformVoucherDiscount;

  /// Mở sheet chọn Voucher CỦA RIÊNG SHOP này — chỉ hiện voucher do Shop
  /// phát hành, không lẫn với Voucher Shopee toàn sàn.
  Future<void> _openShopVoucherSheet() async {
    final result = await VoucherSelectionSheet.show(
      context,
      title: 'Voucher của $_primaryShopName',
      vouchers: _shopVouchers,
      orderTotal: itemsTotal,
      initialSelected: _selectedShopVoucher,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedShopVoucher = result.voucher);
  }

  /// Mở trang chọn Voucher Shopee — có thể chọn đồng thời freeship + mã giảm giá.
  Future<void> _openPlatformVoucherSheet() async {
    final result = await VoucherSelectionSheet.show(
      context,
      title: 'Voucher của Shopee',
      vouchers: _platformVouchers,
      orderTotal: itemsTotal,
      initialSelected: _selectedPlatformDiscount ?? _selectedPlatformFreeship,
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedPlatformFreeship = result.freeshipVoucher;
      _selectedPlatformDiscount = result.discountVoucher;
      // fallback nếu sheet cũ chỉ trả voucher đơn
      if (result.freeshipVoucher == null &&
          result.discountVoucher == null &&
          result.voucher != null) {
        if (result.voucher!.kind == VoucherKind.freeship) {
          _selectedPlatformFreeship = result.voucher;
        } else {
          _selectedPlatformDiscount = result.voucher;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _addressLoading = false);
        return;
      }
      final list = await AddressService.instance.fetchAddresses(uid);
      if (!mounted) return;
      Address? found;
      for (final a in list) {
        if (a.isDefault) {
          found = a;
          break;
        }
      }
      found ??= list.isNotEmpty ? list.first : null;
      setState(() {
        _address = found;
        _addressLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _addressLoading = false);
    }
  }

  Future<void> _openAddressBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressBookScreen()),
    );
    _loadAddress();
  }

  int get itemsTotal =>
      widget.items.fold(0, (sum, i) => sum + i.price * i.quantity);
  int get totalQuantity =>
      widget.items.fold(0, (sum, i) => sum + (i.quantity > 0 ? i.quantity : 1));
  int get insuranceTotal => _insuredItems.length * insurancePrice;
  int get xuDiscount => _useShopeeXu ? shopeeXuAvailable : 0;

  int get grandTotal {
    final t = itemsTotal + insuranceTotal - totalVoucherDiscount - xuDiscount;
    return t > 0 ? t : 0;
  }

  int get totalSaved {
    final priceDiff = widget.items.fold<int>(
      0,
      (sum, i) => sum + (i.originalPrice - i.price) * i.quantity,
    );
    return (priceDiff > 0 ? priceDiff : 0) + totalVoucherDiscount + shippingFee + xuDiscount;
  }

  static String money(int value) {
    final neg = value < 0;
    final v = neg ? -value : value;
    final digits = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buf.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write('.');
    }
    return '${neg ? '-' : ''}${buf.toString()}đ';
  }

  Future<void> _placeOrder() async {
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm địa chỉ nhận hàng')),
      );
      _openAddressBook();
      return;
    }

    final paymentLabel = _selectedPaymentMethod.id == 'spaylater'
        ? '${_selectedPaymentMethod.title} (x$_installmentMonths tháng)'
        : _selectedPaymentMethod.title;

    // Chuyển sang trang xử lý thanh toán -> trang báo thành công, thay vì
    // hiện dialog ngay tại chỗ, giống trải nghiệm thanh toán thật của
    // Shopee. Việc xoá sản phẩm khỏi Giỏ hàng và tạo Order thật sự diễn ra
    // ở PaymentProcessingScreen sau khi "xử lý thanh toán" xong.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(
          items: widget.items,
          address: _address!,
          paymentMethodLabel: paymentLabel,
          itemsTotal: itemsTotal + insuranceTotal,
          discount: totalVoucherDiscount + xuDiscount,
          grandTotal: grandTotal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _section(child: _addressSection()),
            const SizedBox(height: 8),
            _section(child: _productSection()),
            const SizedBox(height: 8),
            _section(child: _shopOptionsSection()),
            const SizedBox(height: 8),
            _section(child: _shippingSection()),
            const SizedBox(height: 8),
            _section(child: _orderSubtotal()),
            const SizedBox(height: 8),
            _section(child: _shopeeVoucherSection()),
            const SizedBox(height: 8),
            _section(child: _shopeeXuSection()),
            const SizedBox(height: 8),
            _section(child: _paymentSection()),
            const SizedBox(height: 8),
            _section(child: _detailSection()),
            const SizedBox(height: 8),
            _termsNote(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: child,
    );
  }

  // ===================== ĐỊA CHỈ =====================
  Widget _addressSection() {
    if (_addressLoading) {
      return const Row(
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: orange)),
          SizedBox(width: 12),
          Text('Đang tải địa chỉ...', style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      );
    }
    if (_address == null) {
      return InkWell(
        onTap: _openAddressBook,
        child: const Row(
          children: [
            Icon(Icons.location_on, color: orange, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Thêm địa chỉ nhận hàng',
                style: TextStyle(fontWeight: FontWeight.w700, color: orange, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      );
    }
    final a = _address!;
    return InkWell(
      onTap: _openAddressBook,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on, color: orange, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: a.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.black87),
                      ),
                      TextSpan(
                        text: '  (${a.phone})',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.fullAddress,
                  style: const TextStyle(fontSize: 13, color: subText, height: 1.35),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  // ===================== SẢN PHẨM =====================
  Widget _shopGroup(String shopName, List<CheckoutLineItem> items) {
    final isMall = items.isNotEmpty && items.first.isMall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop name
        Row(
          children: [
            if (isMall)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'Mall',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                shopName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _productRow(items[i]),
        ],
      ],
    );
  }

  Widget _productRow(CheckoutLineItem item) {
    final price = item.price > 0 ? item.price : 0;
    final original = item.originalPrice > 0 ? item.originalPrice : price;
    final qty = item.quantity > 0 ? item.quantity : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, height: 1.25, color: Colors.black87),
                  ),
                  if (item.variant.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.variant,
                      style: const TextStyle(fontSize: 12.5, color: subText),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // SPayLater tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: orange.withValues(alpha: 0.7)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      '0% SPayLater (đến 1 kỳ)',
                      style: TextStyle(color: orange, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        money(price),
                        style: const TextStyle(color: orange, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.monetization_on, size: 13, color: Color(0xFFFFB300)),
                      if (original > price) ...[
                        const SizedBox(width: 6),
                        Text(
                          money(original),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text('x$qty', style: const TextStyle(fontSize: 13, color: subText)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _protectionRow(item),
      ],
    );
  }

  /// Dòng bảo hiểm/bảo hành ngay dưới mỗi sản phẩm:
  /// - Thiết bị điện tử/di động (điện thoại, laptop, máy tính bảng, phụ
  ///   kiện điện thoại): cho chọn mua thêm "Bảo hiểm thiết bị di động
  ///   nâng cao" (có phí, tick chọn).
  /// - Các sản phẩm khác: chỉ hiển thị bảo hành tiêu chuẩn, đặt tên theo
  ///   đúng sản phẩm tương ứng, không phải trả thêm phí.
  Widget _protectionRow(CheckoutLineItem item) {
    if (isMobileDeviceCategory(item.category)) {
      final insured = _insuredItems.contains(item);
      return InkWell(
        onTap: () => setState(() {
          if (insured) {
            _insuredItems.remove(item);
          } else {
            _insuredItems.add(item);
          }
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: insured,
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _insuredItems.add(item);
                    } else {
                      _insuredItems.remove(item);
                    }
                  }),
                  activeColor: orange,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bảo hiểm thiết bị di động nâng cao',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${money(insurancePrice)} x1',
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 11.5, color: subText, height: 1.35),
                        children: [
                          const TextSpan(
                            text:
                                'Bảo vệ toàn diện thiết bị di động trước những thiệt hại do sự cố, tiếp xúc với chất lỏng và mất cắp/mất trộm. ',
                          ),
                          TextSpan(
                            text: 'Tìm hiểu thêm',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 11.5),
                          ),
                        ],
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

    // Sản phẩm không phải thiết bị điện tử: chỉ hiện bảo hành tiêu chuẩn,
    // đặt tên theo đúng sản phẩm, không phải mục có thể bấm/trả phí.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
                children: [
                  const TextSpan(text: 'Bảo hành: '),
                  TextSpan(
                    text: item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int g = 0; g < _itemsByShop.length; g++) ...[
          if (g > 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
          ],
          _shopGroup(_itemsByShop[g].key, _itemsByShop[g].value),
        ],
      ],
    );
  }

  // ===================== VOUCHER SHOP / LỜI NHẮN / HÓA ĐƠN =====================
  Widget _shopOptionsSection() {
    return Column(
      children: [
        _optionRow(
          title: 'Voucher của Shop',
          onTap: _openShopVoucherSheet,
          trailing: _selectedShopVoucher != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: orange.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-${money(shopVoucherDiscount)}',
                    style: const TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          trailingText: _selectedShopVoucher == null ? 'Chọn Voucher' : null,
          trailingGrey: true,
        ),
        const Divider(height: 1, thickness: 0.5),
        _optionRow(
          title: 'Lời nhắn cho Shop',
          trailingText: _shopMessage.isEmpty ? 'Để lại lời nhắn' : _shopMessage,
          trailingGrey: _shopMessage.isEmpty,
          onTap: _openShopMessageDialog,
        ),
        const Divider(height: 1, thickness: 0.5),
        _optionRow(
          title: 'Hóa đơn điện tử',
          titleSuffix: const Icon(Icons.help_outline, size: 14, color: Colors.grey),
          trailingText: _requestEInvoice ? 'Đã yêu cầu' : 'Yêu cầu',
          trailingGrey: !_requestEInvoice,
          onTap: _openEInvoiceDialog,
        ),
      ],
    );
  }

  Widget _optionRow({
    required String title,
    Widget? titleSuffix,
    Widget? trailing,
    String? trailingText,
    bool trailingGrey = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (titleSuffix != null) ...[const SizedBox(width: 4), titleSuffix],
            const Spacer(),
            if (trailing != null) ...[trailing, const SizedBox(width: 4)],
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 13,
                  color: trailingGrey ? Colors.grey.shade400 : Colors.black87,
                ),
              ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ===================== VẬN CHUYỂN =====================
  Widget _shippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _openShippingPicker,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Phương thức vận chuyển',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              Text('Xem tất cả', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: green.withValues(alpha: 0.55)),
            color: const Color(0xFFF1FAF8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shippingMethod,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    const Text('Nhanh', style: TextStyle(fontSize: 12.5, color: subText)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(shippingFee),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Row(
                    children: [
                      Text('Miễn Phí', style: TextStyle(color: green, fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(width: 2),
                      Icon(Icons.monetization_on, size: 12, color: Color(0xFFFFB300)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nhận tối đa 15.000đ nếu đơn hàng giao trễ',
          style: TextStyle(fontSize: 12.5, color: subText),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('Không đồng kiểm', style: TextStyle(fontSize: 12.5, color: subText)),
            const SizedBox(width: 4),
            Icon(Icons.help_outline, size: 13, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }

  // ===================== TỔNG SẢN PHẨM =====================
  Widget _orderSubtotal() {
    return Row(
      children: [
        Text(
          'Tổng số tiền ($totalQuantity sản phẩm)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          money(itemsTotal),
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ===================== SHOPEE VOUCHER + VIP =====================
  Widget _shopeeVoucherSection() {
    return Column(
      children: [
        InkWell(
          onTap: _openPlatformVoucherSheet,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.confirmation_number, color: orange, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Shopee Voucher', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              ),
              // Hiển thị 1-2 tag theo voucher đã chọn (giảm giá + freeship)
              if (_selectedPlatformDiscount != null)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: orange),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-${money(platformDiscountVoucher)}',
                    style: const TextStyle(color: orange, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_selectedPlatformFreeship != null)
                Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: green),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Miễn Phí Vận Chuyển',
                    style: TextStyle(color: Color(0xFF26A69A), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_selectedPlatformFreeship == null && _selectedPlatformDiscount == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: green),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Chọn Voucher',
                    style: TextStyle(color: Color(0xFF26A69A), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // VIP banner
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Shopee',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: orange,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, color: Colors.white, size: 11),
                              SizedBox(width: 2),
                              Text(
                                'VIP',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 12.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Nhận Voucher '),
                          TextSpan(text: 'giảm 35%', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: ' cho lần đầu đăng ký'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Mua Ngay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== SHOPEE XU =====================
  Widget _shopeeXuSection() {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Text('S', style: TextStyle(color: Color(0xFFE6A800), fontWeight: FontWeight.w900, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Dùng $shopeeXuAvailable Shopee Xu',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Switch.adaptive(
          value: _useShopeeXu,
          onChanged: (v) => setState(() => _useShopeeXu = v),
          activeColor: orange,
        ),
      ],
    );
  }

  // ===================== PHƯƠNG THỨC THANH TOÁN =====================
  /// Tính trả góp SPayLater theo tổng đơn thật.
  /// x1 tháng: 0% phí. Các kỳ khác: có phí (tỷ lệ tăng theo số kỳ).
  ({int perMonth, int feePerMonth}) _spayInstallment(int total, int months) {
    if (months <= 1) return (perMonth: total, feePerMonth: 0);
    // Tổng phí ước lượng: 2 tháng ~2.8%, 3 tháng ~4.5%, 6 ~8%, 12 ~12%
    final rate = switch (months) {
      2 => 0.028,
      3 => 0.045,
      6 => 0.08,
      12 => 0.12,
      _ => 0.03 * (months / 2),
    };
    final totalFee = (total * rate).round();
    final feePerMonth = (totalFee / months).round();
    final perMonth = ((total + totalFee) / months).round();
    return (perMonth: perMonth, feePerMonth: feePerMonth);
  }

  Widget _paymentSection() {
    final isSPay = _selectedPaymentMethod.id == 'spaylater';
    final amount = grandTotal > 0 ? grandTotal : itemsTotal;
    final i1 = _spayInstallment(amount, 1);
    final i2 = _spayInstallment(amount, 2);
    final i3 = _spayInstallment(amount, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _openPaymentMethodPicker,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
              Text('Xem tất cả', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(3)),
              child: const Center(
                child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 6),
            const Text('ShopeePay', style: TextStyle(color: orange, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
        if (isSPay) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.schedule, color: orange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SPayLater (15.000.000đ)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Có thể kết hợp hạn mức SPayLater với một phương thức thanh toán khác',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: orange, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Áp dụng cùng chương trình Shopee Hoàn Xu',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
                  ),
                ),
                Container(
                  width: 32,
                  height: 28,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.percent, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Lưới 2 cột giống Shopee
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
            children: [
              _installmentChip(
                months: 1,
                perMonth: i1.perMonth,
                feePerMonth: i1.feePerMonth,
                selected: _installmentMonths == 1,
                suggested: true,
              ),
              _installmentChip(
                months: 2,
                perMonth: i2.perMonth,
                feePerMonth: i2.feePerMonth,
                selected: _installmentMonths == 2,
              ),
              _installmentChip(
                months: 3,
                perMonth: i3.perMonth,
                feePerMonth: i3.feePerMonth,
                selected: _installmentMonths == 3,
              ),
              InkWell(
                onTap: _openPaymentMethodPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Xem thêm', style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700)),
                      Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: _openPaymentMethodPicker,
            child: Row(
              children: [
                Icon(_selectedPaymentMethod.icon, color: _selectedPaymentMethod.iconColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedPaymentMethod.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.check_circle, color: orange, size: 20),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Thẻ tín dụng / nội địa — bấm chọn được
        InkWell(
          onTap: () async {
            await _openPaymentMethodPicker();
          },
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF1565C0), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPaymentMethod.id == 'credit_card' || _selectedPaymentMethod.id == 'napas'
                          ? _selectedPaymentMethod.title
                          : 'Thẻ Tín dụng/Ghi nợ',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _miniTag('Giảm thêm 50.000đ'),
                        const SizedBox(width: 6),
                        _miniTag('Giảm thêm 55.000đ'),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _openPaymentMethodPicker,
                style: OutlinedButton.styleFrom(
                  foregroundColor: orange,
                  side: const BorderSide(color: orange),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  (_selectedPaymentMethod.id == 'credit_card' || _selectedPaymentMethod.id == 'napas')
                      ? 'Đổi'
                      : 'Thêm',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _installmentChip({
    required int months,
    required int perMonth,
    required int feePerMonth,
    required bool selected,
    bool suggested = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPaymentMethod = findPaymentMethodById('spaylater');
        _installmentMonths = months;
      }),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: selected ? orange : Colors.grey.shade300,
                width: selected ? 1.4 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  money(perMonth),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? orange : const Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'x$months tháng',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selected ? orange : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                if (feePerMonth <= 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: selected ? orange : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '0% Phí',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: selected ? orange : Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  Text(
                    'Gồm ${money(feePerMonth)} phí / kỳ',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          if (suggested)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  'Đề xuất',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: orange.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: const TextStyle(color: orange, fontSize: 11)),
    );
  }

  Future<void> _openPaymentMethodPicker() async {
    final result = await Navigator.push<PaymentSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          selectedId: _selectedPaymentMethod.id,
          initialInstallmentMonths: _installmentMonths,
          orderTotal: grandTotal,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedPaymentMethod = result.method;
      if (result.installmentMonths != null) {
        _installmentMonths = result.installmentMonths!;
      }
    });
  }

  Future<void> _openShopMessageDialog() async {
    final ctrl = TextEditingController(text: _shopMessage);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lời nhắn cho Shop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Lưu ý cho Người bán...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Xong', style: TextStyle(color: Color(0xFFEE4D2D))),
          ),
        ],
      ),
    );
    if (result != null && mounted) setState(() => _shopMessage = result);
  }

  Future<void> _openEInvoiceDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hóa đơn điện tử', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
          'Bạn có muốn xuất hóa đơn điện tử cho đơn hàng này không?\n'
          'Thông tin hóa đơn sẽ được gửi qua email sau khi đơn hoàn thành.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yêu cầu', style: TextStyle(color: Color(0xFFEE4D2D))),
          ),
        ],
      ),
    );
    if (result != null && mounted) setState(() => _requestEInvoice = result);
  }

  Future<void> _openShippingPicker() async {
    final options = [
      'Hôm Nay 21:00',
      'Trong Ngày',
      'Nhanh (2-3 ngày)',
      'Tiết kiệm (3-5 ngày)',
    ];
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Phương thức vận chuyển', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ...options.map((o) => ListTile(
                  title: Text(o),
                  trailing: _shippingMethod == o
                      ? const Icon(Icons.check_circle, color: Color(0xFFEE4D2D))
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _shippingMethod = result);
  }

  // ===================== CHI TIẾT =====================
  Widget _detailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        _line('Tổng tiền hàng', money(itemsTotal + insuranceTotal)),
        _line('Tổng tiền phí vận chuyển', money(shippingFee)),
        _line('Giảm giá phí vận chuyển', '-${money(shippingFee)}', valueColor: orange),
        if (totalVoucherDiscount > 0)
          _line('Tổng cộng Voucher giảm giá', '-${money(totalVoucherDiscount)}', valueColor: orange),
        if (_useShopeeXu) _line('Shopee Xu', '-${money(xuDiscount)}', valueColor: orange),
        const Divider(height: 20),
        _line('Tổng thanh toán', money(grandTotal), bold: true),
      ],
    );
  }

  Widget _line(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14.5 : 13.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? Colors.black87 : subText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 14.5 : 13.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
          children: [
            const TextSpan(text: 'Nhấn "Đặt hàng" đồng nghĩa với việc bạn đồng ý tuân theo '),
            TextSpan(
              text: 'Điều khoản Shopee',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== BOTTOM BAR =====================
  Widget _bottomBar() {
    return Material(
      elevation: 10,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Tổng cộng ',
                            style: TextStyle(fontSize: 13.5, color: Colors.black87),
                          ),
                          TextSpan(
                            text: money(grandTotal),
                            style: const TextStyle(color: orange, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    if (totalSaved > 0)
                      Text(
                        'Tiết kiệm ${money(totalSaved)}',
                        style: const TextStyle(fontSize: 12, color: subText),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _placing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _placing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text(
                          'Đặt hàng',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
