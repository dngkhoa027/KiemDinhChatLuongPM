/// Model cho Voucher / Mã giảm giá (dùng chung cho Voucher Shop và Voucher Shopee).
enum VoucherSource { shop, platform }

enum VoucherDiscountType { percent, fixed }

enum VoucherKind { discount, freeship }

class Voucher {
  final String id;
  final String code;
  final String title;
  final VoucherSource source;
  final VoucherKind kind;
  final VoucherDiscountType discountType;

  /// Nếu [discountType] là percent: giá trị 1-100 (%).
  /// Nếu [discountType] là fixed: số tiền giảm trực tiếp (đ).
  final int discountValue;

  /// Giảm tối đa (chỉ áp dụng khi discountType = percent). 0 = không giới hạn.
  final int maxDiscount;

  /// Đơn hàng tối thiểu để dùng được voucher.
  final int minSpend;

  /// Số lượng còn lại (để hiển thị thanh "sắp hết").
  final int quantity;
  final int used;

  final String expiry;
  final String? shopName;

  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.source,
    required this.discountType,
    required this.discountValue,
    this.kind = VoucherKind.discount,
    this.maxDiscount = 0,
    this.minSpend = 0,
    this.quantity = 100,
    this.used = 0,
    this.expiry = '',
    this.shopName,
  });

  bool isEligible(int orderTotal) => orderTotal >= minSpend;

  /// Tính số tiền được giảm dựa trên [orderTotal] (tổng tiền hàng áp dụng voucher).
  int calcDiscount(int orderTotal) {
    if (!isEligible(orderTotal)) return 0;
    if (kind == VoucherKind.freeship) return discountValue;
    if (discountType == VoucherDiscountType.fixed) {
      return discountValue > orderTotal ? orderTotal : discountValue;
    }
    // percent
    final raw = (orderTotal * discountValue / 100).round();
    if (maxDiscount > 0 && raw > maxDiscount) return maxDiscount;
    return raw;
  }

  String get subtitle {
    final buf = StringBuffer();
    if (kind == VoucherKind.freeship) {
      buf.write('Miễn phí vận chuyển tối đa ${_money(discountValue)}');
    } else if (discountType == VoucherDiscountType.percent) {
      buf.write('Giảm $discountValue%');
      if (maxDiscount > 0) buf.write(' giảm tối đa ${_money(maxDiscount)}');
    } else {
      buf.write('Giảm ${_money(discountValue)}');
    }
    if (minSpend > 0) buf.write(' cho đơn tối thiểu ${_money(minSpend)}');
    return buf.toString();
  }

  static String _money(int v) {
    final digits = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      b.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) b.write('.');
    }
    return '${b}đ';
  }
}
