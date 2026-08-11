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

class PaymentSelectionResult {
  final PaymentMethod method;
  final int? installmentMonths;
  const PaymentSelectionResult(this.method, {this.installmentMonths});
}

const List<PaymentMethodGroup> kPaymentMethodGroups = [
  PaymentMethodGroup(
    label: 'Ví điện tử',
    methods: [
      PaymentMethod(
        id: 'shopeepay',
        title: 'Số dư Ví ShopeePay',
        subtitle: 'Nhanh chóng, nhiều ưu đãi',
        icon: Icons.account_balance_wallet,
        iconColor: Color(0xFFEE4D2D),
      ),
      PaymentMethod(
        id: 'spaylater',
        title: 'SPayLater',
        subtitle: 'Hạn mức 15.000.000đ',
        icon: Icons.schedule,
        iconColor: Color(0xFFEE4D2D),
      ),
    ],
  ),
  PaymentMethodGroup(
    label: 'Thẻ',
    methods: [
      PaymentMethod(
        id: 'credit_card',
        title: 'Thẻ Tín dụng/Ghi nợ',
        subtitle: 'Visa/Mastercard/JCB/Amex/UnionPay',
        icon: Icons.credit_card,
        iconColor: Color(0xFF1565C0),
      ),
      PaymentMethod(
        id: 'napas',
        title: 'Thẻ nội địa NAPAS',
        subtitle: 'Chỉ hỗ trợ thẻ đầu số 9704',
        icon: Icons.credit_card_outlined,
        iconColor: Color(0xFF00897B),
      ),
      PaymentMethod(
        id: 'installment_card',
        title: 'Trả góp bằng Thẻ Tín dụng',
        subtitle: null,
        icon: Icons.calendar_month,
        iconColor: Color(0xFF00897B),
      ),
    ],
  ),
  PaymentMethodGroup(
    label: 'Khác',
    methods: [
      PaymentMethod(
        id: 'cod',
        title: 'Thanh toán khi nhận hàng',
        subtitle: null,
        icon: Icons.payments_outlined,
        iconColor: Color(0xFFE65100),
      ),
      PaymentMethod(
        id: 'qr',
        title: 'Thanh toán QR',
        subtitle: null,
        icon: Icons.qr_code,
        iconColor: Color(0xFFF9A825),
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

/// Trang chọn phương thức thanh toán — bám sát UI Shopee.
class PaymentMethodScreen extends StatefulWidget {
  final String? selectedId;
  final int initialInstallmentMonths;
  final int orderTotal;

  const PaymentMethodScreen({
    super.key,
    this.selectedId,
    this.initialInstallmentMonths = 1,
    this.orderTotal = 0,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color pageBg = Color(0xFFF5F5F5);

  late String _selectedId;
  late int _installmentMonths;
  bool _spayExpanded = true;
  bool _cardExpanded = true;
  bool _napasExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId ?? 'spaylater';
    _installmentMonths = widget.initialInstallmentMonths;
  }

  static String money(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buf.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write('.');
    }
    return '$bufđ';
  }

  int get _baseAmount {
    // Dùng orderTotal nếu có, không thì demo 14.326.968
    return widget.orderTotal > 0 ? widget.orderTotal : 14326968;
  }

  void _confirm() {
    final method = findPaymentMethodById(_selectedId);
    Navigator.pop(
      context,
      PaymentSelectionResult(
        method,
        installmentMonths: _selectedId == 'spaylater' ? _installmentMonths : null,
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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phương thức thanh toán',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SizedBox(height: 8),
          // ShopeePay group
          _whiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('ShopeePay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: orange)),
                  ],
                ),
                const SizedBox(height: 14),
                // Số dư Ví
                _methodRow(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.grey.shade400,
                  title: 'Số dư Ví ShopeePay',
                  subtitle: 'Nhanh chóng, nhiều ưu đãi',
                  selected: _selectedId == 'shopeepay',
                  enabled: false,
                  badge: 'Ưu đãi phí vận chuyển',
                  onTap: null,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 40, top: 6, bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Ưu đãi 200.000đ Giảm — Chương trình khuyến mãi đã vượt quá số lượt sử dụng.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBF360C), height: 1.35),
                  ),
                ),
                const Divider(height: 1),
                // SPayLater
                _spayLaterBlock(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Credit card
          _whiteCard(
            child: Column(
              children: [
                _expandableHeader(
                  icon: Icons.credit_card,
                  iconColor: const Color(0xFF1565C0),
                  title: 'Thẻ Tín dụng/Ghi nợ',
                  subtitle: '(Visa/Mastercard/JCB/Amex/UnionPay)',
                  expanded: _cardExpanded,
                  onToggle: () => setState(() => _cardExpanded = !_cardExpanded),
                  badge: 'Ưu đãi phí vận chuyển',
                ),
                if (_cardExpanded) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _promoBanner(
                          color: const Color(0xFF2E7D32),
                          title: '50.000đ Giảm',
                          sub: 'Mỗi Thứ Hai - Thẻ ghi nợ VPBank Shopee',
                        ),
                        const SizedBox(width: 8),
                        _promoBanner(
                          color: const Color(0xFF00897B),
                          title: '55.000đ',
                          sub: 'cho đơn từ 500k',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _addNewTile(label: 'Thêm thẻ mới', onTap: () {}),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // NAPAS
          _whiteCard(
            child: Column(
              children: [
                _expandableHeader(
                  icon: Icons.account_balance,
                  iconColor: const Color(0xFF00897B),
                  title: 'Thẻ nội địa NAPAS',
                  subtitle: 'Chỉ hỗ trợ thẻ đầu số 9704',
                  expanded: _napasExpanded,
                  onToggle: () => setState(() => _napasExpanded = !_napasExpanded),
                  badge: 'Ưu đãi phí vận chuyển',
                  isNew: true,
                ),
                if (_napasExpanded) ...[
                  const SizedBox(height: 8),
                  _addNewTile(label: 'Thẻ mới', onTap: () {}, icon: Icons.credit_card),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Installment card
          _whiteCard(
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _selectedId = 'installment_card'),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF00897B), size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trả góp bằng Thẻ Tín dụng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            SizedBox(height: 3),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _smallBadge('Ưu đãi phí vận chuyển'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _promoBanner(
                        color: const Color(0xFFC62828),
                        title: '400.000đ Giảm',
                        sub: 'cho đơn trả góp từ 10 triệu',
                      ),
                      const SizedBox(width: 8),
                      _promoBanner(
                        color: const Color(0xFFE91E63),
                        title: '500.000đ',
                        sub: 'Chương trình quà sốc',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Other methods
          _whiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phương thức thanh toán khác', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                _radioMethod(
                  id: 'cod',
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFFE65100),
                  title: 'Thanh toán khi nhận hàng',
                  badge: true,
                ),
                const Divider(height: 20),
                _radioMethod(
                  id: 'qr',
                  icon: Icons.qr_code_2,
                  iconColor: const Color(0xFFF9A825),
                  title: 'Thanh toán QR',
                  badge: true,
                  hasHelp: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  ({int perMonth, int feePerMonth}) _calcInstallment(int total, int months) {
    if (months <= 1) return (perMonth: total, feePerMonth: 0);
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

  Widget _spayLaterBlock() {
    final limit = 15000000;
    final amount = _baseAmount;
    final o1 = _calcInstallment(amount, 1);
    final o2 = _calcInstallment(amount, 2);
    final o3 = _calcInstallment(amount, 3);
    final o6 = _calcInstallment(amount, 6);
    final o12 = _calcInstallment(amount, 12);
    final options = [
      (1, o1.perMonth, o1.feePerMonth),
      (2, o2.perMonth, o2.feePerMonth),
      (3, o3.perMonth, o3.feePerMonth),
      (6, o6.perMonth, o6.feePerMonth),
      (12, o12.perMonth, o12.feePerMonth),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            _selectedId = 'spaylater';
            _spayExpanded = !_spayExpanded;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SPayLater (${money(limit)})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.help_outline, size: 14, color: Colors.grey.shade500),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Có thể kết hợp hạn mức SPayLater với một phương thức thanh toán khác',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      _smallBadge('Ưu đãi phí vận chuyển'),
                    ],
                  ),
                ),
                if (_selectedId == 'spaylater')
                  const Icon(Icons.check_circle, color: orange, size: 22)
                else
                  Icon(Icons.radio_button_off, color: Colors.grey.shade400, size: 22),
                const SizedBox(width: 4),
                Icon(
                  _spayExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        if (_spayExpanded && _selectedId == 'spaylater')
          ...options.map((o) {
            final months = o.$1;
            final perMonth = o.$2;
            final fee = o.$3;
            final selected = _installmentMonths == months;
            return InkWell(
              onTap: () => setState(() {
                _selectedId = 'spaylater';
                _installmentMonths = months;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(
                  children: [
                    if (months == 3)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('Đề xuất', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    Expanded(
                      child: Text(
                        'Thanh toán trong $months kỳ',
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          months == 1 ? money(perMonth) : '${money(perMonth)}/tháng',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? orange : const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          fee > 0 ? 'Gồm ${money(fee)} phí / kỳ' : '0% Phí',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: fee > 0 ? Colors.grey.shade600 : orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected ? Icons.check : null,
                      color: orange,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: child,
    );
  }

  Widget _expandableHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    String? badge,
    bool isNew = false,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(3)),
                        child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (badge != null) ...[
                  const SizedBox(height: 3),
                  _smallBadge(badge),
                ],
              ],
            ),
          ),
          Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade500),
        ],
      ),
    );
  }

  Widget _methodRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool selected,
    required bool enabled,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (badge != null) ...[
                    const SizedBox(height: 3),
                    _smallBadge(badge),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_off,
              color: selected ? orange : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioMethod({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    bool badge = false,
    bool hasHelp = false,
  }) {
    final selected = _selectedId == id;
    return InkWell(
      onTap: () => setState(() => _selectedId = id),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (hasHelp) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.help_outline, size: 14, color: Colors.grey.shade500),
                    ],
                  ],
                ),
                if (badge) ...[
                  const SizedBox(height: 3),
                  _smallBadge('Ưu đãi phí vận chuyển'),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_off,
            color: selected ? orange : Colors.grey.shade400,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EB),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: const TextStyle(color: orange, fontSize: 11)),
    );
  }

  Widget _promoBanner({required Color color, required String title, required String sub}) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.25)),
        ],
      ),
    );
  }

  Widget _addNewTile({required String label, required VoidCallback onTap, IconData icon = Icons.add}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
