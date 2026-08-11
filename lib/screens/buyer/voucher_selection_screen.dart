import 'package:flutter/material.dart';
import '../../models/voucher_model.dart';

/// Bottom sheet / trang chọn Voucher kiểu Shopee.
///
/// - Shop Voucher: giữ layout cũ (đơn giản).
/// - Shopee Voucher: layout mới giống ảnh (FREE SHIP, mã giảm giá, không khả dụng...).
class VoucherSelectionSheet extends StatefulWidget {
  final String title;
  final List<Voucher> vouchers;
  final int orderTotal;
  final Voucher? initialSelected;

  const VoucherSelectionSheet({
    super.key,
    required this.title,
    required this.vouchers,
    required this.orderTotal,
    this.initialSelected,
  });

  static Future<VoucherPickResult?> show(
    BuildContext context, {
    required String title,
    required List<Voucher> vouchers,
    required int orderTotal,
    Voucher? initialSelected,
  }) {
    final isShopee = title.toLowerCase().contains('shopee');
    if (isShopee) {
      return Navigator.of(context).push<VoucherPickResult>(
        MaterialPageRoute(
          builder: (_) => VoucherSelectionSheet(
            title: title,
            vouchers: vouchers,
            orderTotal: orderTotal,
            initialSelected: initialSelected,
          ),
        ),
      );
    }
    return showModalBottomSheet<VoucherPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoucherSelectionSheet(
        title: title,
        vouchers: vouchers,
        orderTotal: orderTotal,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class VoucherPickResult {
  final Voucher? voucher;
  const VoucherPickResult(this.voucher);
}

class _VoucherSelectionSheetState extends State<VoucherSelectionSheet> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color subText = Color(0xFF757575);

  Voucher? _picked;
  final TextEditingController _codeCtrl = TextEditingController();
  String? _codeError;
  bool _showMoreShip = false;
  bool _showMoreUnavailable = false;

  bool get _isShopee => widget.title.toLowerCase().contains('shopee');

  @override
  void initState() {
    super.initState();
    _picked = widget.initialSelected;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  static String money(int v) {
    final neg = v < 0;
    final n = neg ? -v : v;
    final digits = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final r = digits.length - i;
      b.write(digits[i]);
      if (r > 1 && r % 3 == 1) b.write('.');
    }
    return '${neg ? '-' : ''}${b}đ';
  }

  void _applyCode() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    Voucher? found;
    for (final v in widget.vouchers) {
      if (v.code.toUpperCase() == code) {
        found = v;
        break;
      }
    }
    if (found == null) {
      setState(() => _codeError = 'Mã không hợp lệ hoặc không áp dụng ở đây');
      return;
    }
    if (!found.isEligible(widget.orderTotal)) {
      setState(() => _codeError = 'Đơn hàng chưa đạt giá trị tối thiểu để dùng mã này');
      return;
    }
    setState(() {
      _codeError = null;
      _codeCtrl.clear();
      _picked = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isShopee) {
      return _buildShopeePage();
    }
    return _buildShopSheet();
  }

  // =========================================================
  // SHOP VOUCHER — giữ layout cũ (bottom sheet)
  // =========================================================
  Widget _buildShopSheet() {
    final mediaHeight = MediaQuery.of(context).size.height;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          height: mediaHeight * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã Voucher',
                          hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                          isDense: true,
                          errorText: _codeError,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onSubmitted: (_) => _applyCode(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: _applyCode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: orange,
                          side: const BorderSide(color: orange),
                        ),
                        child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: widget.vouchers.isEmpty
                    ? const Center(child: Text('Không có voucher khả dụng', style: TextStyle(color: subText)))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        itemCount: widget.vouchers.length,
                        itemBuilder: (context, i) {
                          final v = widget.vouchers[i];
                          final eligible = v.isEligible(widget.orderTotal);
                          final selected = _picked?.id == v.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _shopVoucherCard(v, eligible: eligible, selected: selected),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, VoucherPickResult(_picked)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shopVoucherCard(Voucher v, {required bool eligible, required bool selected}) {
    return Opacity(
      opacity: eligible ? 1 : 0.5,
      child: InkWell(
        onTap: eligible ? () => setState(() => _picked = selected ? null : v) : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: selected ? orange : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(v.subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                    if (v.expiry.isNotEmpty)
                      Text(v.expiry, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.radio_button_off, color: selected ? orange : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SHOPEE VOUCHER — layout mới full page
  // =========================================================
  Widget _buildShopeePage() {
    final freeship = widget.vouchers.where((v) => v.kind == VoucherKind.freeship).toList();
    final discount = widget.vouchers.where((v) => v.kind != VoucherKind.freeship && v.isEligible(widget.orderTotal)).toList();
    final unavailable = widget.vouchers.where((v) => !v.isEligible(widget.orderTotal)).toList();

    // Seed thêm voucher demo nếu list trống để UI giống ảnh
    final shipList = freeship.isNotEmpty ? freeship : _demoFreeship;
    final discList = discount.isNotEmpty ? discount : _demoDiscount;
    final unavailList = unavailable.isNotEmpty ? unavailable : _demoUnavailable;

    int savings = 0;
    if (_picked != null) savings = _picked!.calcDiscount(widget.orderTotal);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn Shopee Voucher',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Code input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã shopee voucher',
                      hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                      isDense: true,
                      errorText: _codeError,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _applyCode(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _applyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Ưu đãi phí vận chuyển
                _sectionTitle('Ưu đãi phí vận chuyển'),
                ...shipList.take(_showMoreShip ? shipList.length : 1).map((v) {
                  final selected = _picked?.id == v.id;
                  return _shopeeVoucherCard(
                    v,
                    leftColor: const Color(0xFF26A69A),
                    leftLabel: 'FREE\nSHIP',
                    leftSub: 'Toàn Ngành Hàng',
                    selected: selected,
                    bestChoice: selected || v == shipList.first,
                    onTap: () => setState(() => _picked = selected ? null : v),
                  );
                }),
                if (shipList.length > 1)
                  _seeMoreButton(
                    expanded: _showMoreShip,
                    onTap: () => setState(() => _showMoreShip = !_showMoreShip),
                  ),

                // Mã giảm giá / hoàn Xu
                _sectionTitle('Mã giảm giá/hoàn Xu'),
                ...discList.map((v) {
                  final selected = _picked?.id == v.id;
                  final isSPay = v.title.toLowerCase().contains('spay') || v.code.contains('SPAY');
                  return _shopeeVoucherCard(
                    v,
                    leftColor: orange,
                    leftLabel: isSPay ? 'SPayLater' : 'SHOPEE',
                    leftIcon: isSPay ? Icons.account_balance_wallet_outlined : Icons.shopping_bag_outlined,
                    selected: selected,
                    bestChoice: selected || v == discList.first,
                    showUsageBar: true,
                    onTap: () => setState(() => _picked = selected ? null : v),
                  );
                }),

                // Không khả dụng
                if (unavailList.isNotEmpty) ...[
                  _sectionTitle('Voucher không khả dụng'),
                  ...unavailList.take(_showMoreUnavailable ? unavailList.length : 1).map((v) {
                    return _shopeeVoucherCard(
                      v,
                      leftColor: const Color(0xFFB2DFDB),
                      leftLabel: 'FREE\nSHIP',
                      leftSub: 'Tất cả hình thức\nthanh toán',
                      selected: false,
                      enabled: false,
                      onTap: null,
                    );
                  }),
                  if (unavailList.length > 1)
                    _seeMoreButton(
                      expanded: _showMoreUnavailable,
                      onTap: () => setState(() => _showMoreUnavailable = !_showMoreUnavailable),
                    ),
                ],
              ],
            ),
          ),
          // Bottom summary + button
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_picked != null)
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                      children: [
                        const TextSpan(text: '1 Voucher đã được chọn. '),
                        TextSpan(
                          text: 'Đã áp dụng ${_picked!.kind == VoucherKind.freeship ? 'ưu đãi phí vận chuyển' : 'mã giảm giá'}',
                          style: const TextStyle(color: Color(0xFF00897B)),
                        ),
                        if (savings > 0)
                          TextSpan(
                            text: ', giảm -${money(savings)}',
                            style: const TextStyle(color: Color(0xFF00897B)),
                          ),
                      ],
                    ),
                  )
                else
                  Text('Chưa chọn voucher', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, VoucherPickResult(_picked)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Đồng ý', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
    );
  }

  Widget _seeMoreButton({required bool expanded, required VoidCallback onTap}) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(expanded ? 'Thu gọn' : 'Xem thêm', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _shopeeVoucherCard(
    Voucher v, {
    required Color leftColor,
    required String leftLabel,
    String? leftSub,
    IconData? leftIcon,
    required bool selected,
    bool bestChoice = false,
    bool enabled = true,
    bool showUsageBar = false,
    VoidCallback? onTap,
  }) {
    final usedPct = v.quantity > 0 ? (v.used / v.quantity).clamp(0.0, 1.0) : 0.0;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? orange.withValues(alpha: 0.5) : Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left tab
                Container(
                  width: 88,
                  color: leftColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leftIcon != null)
                        Icon(leftIcon, color: Colors.white, size: 26)
                      else
                        Text(
                          leftLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            height: 1.15,
                          ),
                        ),
                      if (leftIcon != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          leftLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (leftSub != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          leftSub,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, height: 1.2),
                        ),
                      ],
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bestChoice && enabled)
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0E0),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text('Lựa chọn tốt nhất', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        Text(
                          v.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF222222)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          v.minSpend > 0 ? 'Đơn tối thiểu ${money(v.minSpend)}' : v.subtitle,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                        ),
                        if (v.expiry.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                              children: [
                                TextSpan(text: '${v.expiry} '),
                                const TextSpan(text: 'Điều kiện', style: TextStyle(color: Color(0xFF1976D2))),
                              ],
                            ),
                          ),
                        ],
                        if (showUsageBar && usedPct > 0.5) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: usedPct,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF9800)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đã dùng ${(usedPct * 100).round()}%',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                        if (!enabled) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Sản phẩm hoặc Người bán không thỏa điều kiện voucher',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Radio
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_off,
                    color: selected ? orange : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Demo data khi list rỗng — để UI giống ảnh
  static final List<Voucher> _demoFreeship = [
    const Voucher(
      id: 'demo_fs1',
      code: 'FREESHIPXTRA',
      title: 'Miễn phí vận chuyển',
      source: VoucherSource.platform,
      kind: VoucherKind.freeship,
      discountType: VoucherDiscountType.fixed,
      discountValue: 25000,
      minSpend: 50000,
      expiry: 'HSD: 16.08.2026',
      quantity: 100,
      used: 40,
    ),
  ];

  static final List<Voucher> _demoDiscount = [
    const Voucher(
      id: 'demo_d1',
      code: 'SPAY18',
      title: 'Giảm 18% Giảm tối đa 300kđ',
      source: VoucherSource.platform,
      discountType: VoucherDiscountType.percent,
      discountValue: 18,
      maxDiscount: 300000,
      minSpend: 300000,
      expiry: 'hết hạn 14.08.2026',
      quantity: 100,
      used: 74,
    ),
    const Voucher(
      id: 'demo_d2',
      code: 'SALE20K',
      title: 'Giảm 20kđ',
      source: VoucherSource.platform,
      discountType: VoucherDiscountType.fixed,
      discountValue: 20000,
      minSpend: 200000,
      expiry: 'HSD: 20.08.2026',
      quantity: 100,
      used: 30,
    ),
    const Voucher(
      id: 'demo_d3',
      code: 'SALE15K',
      title: 'Giảm 15kđ',
      source: VoucherSource.platform,
      discountType: VoucherDiscountType.fixed,
      discountValue: 15000,
      minSpend: 100000,
      expiry: 'hết hạn trong: Còn 2 ngày',
      quantity: 100,
      used: 93,
    ),
    const Voucher(
      id: 'demo_d4',
      code: 'SALE5K',
      title: 'Giảm 5kđ',
      source: VoucherSource.platform,
      discountType: VoucherDiscountType.fixed,
      discountValue: 5000,
      minSpend: 99000,
      expiry: 'HSD: 20.08.2026',
    ),
  ];

  static final List<Voucher> _demoUnavailable = [
    const Voucher(
      id: 'demo_u1',
      code: 'FS40K',
      title: 'Giảm tối đa 40kđ',
      source: VoucherSource.platform,
      kind: VoucherKind.freeship,
      discountType: VoucherDiscountType.fixed,
      discountValue: 40000,
      minSpend: 999999999, // không đủ điều kiện
      expiry: 'HSD: 15.08.2026',
    ),
  ];
}
