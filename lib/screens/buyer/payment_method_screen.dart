import 'package:flutter/material.dart';

/// Model 1 phương thức thanh toán (kiểu Shopee).
class PaymentMethod {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBg;
  final bool enabled;
  final String? disabledReason;

  const PaymentMethod({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.iconBg,
    this.enabled = true,
    this.disabledReason,
  });
}

class PaymentMethodGroup {
  final String label;
  final List<PaymentMethod> methods;
  const PaymentMethodGroup({required this.label, required this.methods});
}

/// Kết quả trả về sau khi chọn phương thức thanh toán. [installmentMonths]
/// chỉ có giá trị khi phương thức chọn là SPayLater (trả góp 1/2/3 tháng).
class PaymentSelectionResult {
  final PaymentMethod method;
  final int? installmentMonths;
  const PaymentSelectionResult(this.method, {this.installmentMonths});
}

/// Toàn bộ danh sách phương thức thanh toán có trong Shopee, nhóm theo loại
/// — dùng chung cho [PaymentMethodScreen] và giá trị mặc định ở trang
/// Thanh toán.
const List<PaymentMethodGroup> kPaymentMethodGroups = [
  PaymentMethodGroup(
    label: 'Ví điện tử',
    methods: [
      PaymentMethod(
        id: 'shopeepay',
        title: 'Số dư Ví ShopeePay',
        subtitle: 'Số dư: 0đ · Giảm thêm 200.000đ khi thanh toán bằng Ví',
        icon: Icons.account_balance_wallet,
        iconColor: Color(0xFFEE4D2D),
      ),
      PaymentMethod(
        id: 'spaylater',
        title: 'SPayLater',
        subtitle: 'Mua trước trả sau · Hạn mức khả dụng 14.326.968đ',
        icon: Icons.schedule,
        iconColor: Color(0xFFEE4D2D),
      ),
      PaymentMethod(
        id: 'momo',
        title: 'Ví MoMo',
        subtitle: 'Liên kết Ví MoMo để thanh toán',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: Color(0xFFAE2070),
      ),
      PaymentMethod(
        id: 'zalopay',
        title: 'ZaloPay',
        subtitle: 'Liên kết ZaloPay để thanh toán',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: Color(0xFF0068FF),
      ),
    ],
  ),
  PaymentMethodGroup(
    label: 'Thẻ / Tài khoản ngân hàng',
    methods: [
      PaymentMethod(
        id: 'credit_card',
        title: 'Thẻ Tín dụng/Ghi nợ',
        subtitle: 'Visa, Mastercard, JCB',
        icon: Icons.credit_card,
        iconColor: Color(0xFF1565C0),
      ),
      PaymentMethod(
        id: 'installment_card',
        title: 'Trả góp qua thẻ tín dụng',
        subtitle: '0% lãi suất một số kỳ hạn',
        icon: Icons.calendar_month,
        iconColor: Color(0xFFEE4D2D),
      ),
      PaymentMethod(
        id: 'internet_banking',
        title: 'Internet Banking',
        subtitle: 'Thanh toán qua tài khoản ngân hàng nội địa',
        icon: Icons.account_balance,
        iconColor: Color(0xFF2E7D32),
      ),
    ],
  ),
  PaymentMethodGroup(
    label: 'Khác',
    methods: [
      PaymentMethod(
        id: 'cod',
        title: 'Thanh toán khi nhận hàng',
        subtitle: 'Tiền mặt (COD)',
        icon: Icons.payments_outlined,
        iconColor: Color(0xFF2E9E5B),
      ),
    ],
  ),
];

PaymentMethod findPaymentMethodById(String id) {
  for (final group in kPaymentMethodGroups) {
    for (final m in group.methods) {
      if (m.id == id) return m;
    }
  }
  return kPaymentMethodGroups.first.methods.first;
}

/// Trang chọn phương thức thanh toán — liệt kê đầy đủ các cách thanh toán
/// có trong Shopee (Ví ShopeePay, SPayLater, ví liên kết, thẻ tín dụng/ghi
/// nợ, trả góp, Internet Banking, thanh toán khi nhận hàng...), cho phép
/// chọn đúng 1 phương thức áp dụng cho đơn hàng, giống hành vi thật của
/// Shopee.
class PaymentMethodScreen extends StatefulWidget {
  final String? selectedId;
  final int initialInstallmentMonths;

  const PaymentMethodScreen({
    super.key,
    this.selectedId,
    this.initialInstallmentMonths = 1,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color subText = Color(0xFF757575);
  static const Color pageBg = Color(0xFFF5F5F5);

  late String _selectedId = widget.selectedId ?? kPaymentMethodGroups.first.methods.first.id;
  late int _installmentMonths = widget.initialInstallmentMonths;

  static String money(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buf.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write('.');
    }
    return "$bufđ";
  }

  void _confirm() {
    final method = findPaymentMethodById(_selectedId);
    Navigator.pop(
      context,
      PaymentSelectionResult(
        method,
        installmentMonths: method.id == 'spaylater' ? _installmentMonths : null,
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
          'Chọn phương thức thanh toán',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          for (final group in kPaymentMethodGroups) _groupSection(group),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _groupSection(PaymentMethodGroup group) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text(
                group.label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            for (int i = 0; i < group.methods.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 14, endIndent: 14, color: Colors.grey.shade200),
              _methodTile(group.methods[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodTile(PaymentMethod m) {
    final selected = _selectedId == m.id;
    return Column(
      children: [
        Opacity(
          opacity: m.enabled ? 1 : 0.45,
          child: InkWell(
            onTap: m.enabled ? () => setState(() => _selectedId = m.id) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: m.iconBg ?? m.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(m.icon, color: m.iconColor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        if ((m.enabled ? m.subtitle : m.disabledReason) != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            (m.enabled ? m.subtitle : m.disabledReason)!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: !m.enabled ? Colors.redAccent : subText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? orange : Colors.grey.shade400,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
        // SPayLater mở rộng thành các kỳ hạn trả góp khi đang được chọn.
        if (selected && m.id == 'spaylater') _installmentPicker(),
      ],
    );
  }

  Widget _installmentPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          for (final months in [1, 2, 3]) ...[
            if (months > 1) const SizedBox(width: 8),
            Expanded(child: _installmentChip(months)),
          ],
        ],
      ),
    );
  }

  Widget _installmentChip(int months) {
    final selected = _installmentMonths == months;
    return InkWell(
      onTap: () => setState(() => _installmentMonths = months),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? orange : Colors.grey.shade300),
          color: selected ? orange.withOpacity(0.05) : const Color(0xFFF7F7F7),
        ),
        child: Text(
          'x$months tháng',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? orange : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}
