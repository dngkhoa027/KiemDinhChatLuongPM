import 'package:flutter/material.dart';
import '../../models/voucher_model.dart';

/// Bottom sheet chọn Voucher kiểu Shopee.
///
/// LƯU Ý: Voucher của Shop và Voucher của Shopee là 2 danh sách HOÀN TOÀN
/// RIÊNG BIỆT — không gộp chung 1 sheet dạng tab. Mỗi lần mở sheet chỉ
/// hiển thị đúng 1 danh sách voucher, tính đủ điều kiện / số tiền giảm dựa
/// trên [orderTotal] tương ứng của phạm vi đó:
///   - Mở từ 1 Shop  -> chỉ truyền voucher của Shop đó + tổng tiền hàng của
///     riêng Shop đó (không tính hàng của Shop khác).
///   - Mở "Shopee Voucher" -> chỉ truyền voucher toàn sàn + tổng tiền của
///     TOÀN BỘ đơn hàng (tất cả các Shop cộng lại).
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

/// Kết quả trả về sau khi đóng sheet: voucher đã chọn (có thể null = bỏ chọn).
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
              _header(),
              _codeInput(),
              const Divider(height: 1),
              Expanded(
                child: widget.vouchers.isEmpty
                    ? const Center(
                        child: Text('Không có voucher khả dụng', style: TextStyle(color: subText)),
                      )
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
                            child: _voucherCard(
                              v,
                              eligible: eligible,
                              selected: selected,
                              onTap: eligible
                                  ? () => setState(() => _picked = selected ? null : v)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
              _bottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _codeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voucherCard(Voucher v, {required bool eligible, required bool selected, VoidCallback? onTap}) {
    final progress = v.quantity > 0 ? (v.used / v.quantity).clamp(0.0, 1.0) : 0.0;
    return Opacity(
      opacity: eligible ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? orange : Colors.grey.shade200),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 84,
                  decoration: BoxDecoration(
                    color: v.kind == VoucherKind.freeship
                        ? const Color(0xFFEAF7F1)
                        : orange.withOpacity(0.08),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        v.kind == VoucherKind.freeship ? Icons.local_shipping : Icons.confirmation_number,
                        color: v.kind == VoucherKind.freeship ? const Color(0xFF26A69A) : orange,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.kind == VoucherKind.freeship ? 'FREESHIP' : 'GIẢM GIÁ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: v.kind == VoucherKind.freeship ? const Color(0xFF26A69A) : orange,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: _DashedLinePainter(color: Colors.grey.shade300),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                v.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            if (v.shopName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  v.shopName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          v.subtitle,
                          style: const TextStyle(fontSize: 12, color: subText),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          v.expiry,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              progress > 0.85 ? orange : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progress > 0.85 ? 'Sắp hết' : 'Còn ${v.quantity - v.used} voucher',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                        ),
                        if (!eligible) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Chưa đủ điều kiện (đơn tối thiểu ${money(v.minSpend)})',
                            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: eligible
                      ? Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? orange : Colors.grey.shade300,
                          size: 22,
                        )
                      : const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final discount = _picked?.calcDiscount(widget.orderTotal) ?? 0;
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _picked != null ? 'Tiết kiệm ${money(discount)}' : 'Chưa chọn voucher',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, VoucherPickResult(_picked)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
