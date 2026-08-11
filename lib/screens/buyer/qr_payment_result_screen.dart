import 'package:flutter/material.dart';
import '../../models/product_model.dart' show formatVnd;

/// Kết quả sau khi quét 1 mã QR thanh toán (chuẩn EMVCo — cùng chuẩn với
/// VietQR / QR ngân hàng, QR các ví điện tử tại Việt Nam).
///
/// Đây là app demo nên không có backend ngân hàng thật đứng sau — flow này
/// chỉ đọc (parse) đúng cấu trúc dữ liệu mã QR thật, hiển thị lại thông tin
/// người thụ hưởng/số tiền y như app ngân hàng thật hay làm, và giả lập
/// bước xác nhận thanh toán.
class QrPaymentResultScreen extends StatefulWidget {
  final String rawValue;
  final Map<String, String> fields;

  const QrPaymentResultScreen({
    super.key,
    required this.rawValue,
    required this.fields,
  });

  @override
  State<QrPaymentResultScreen> createState() => _QrPaymentResultScreenState();
}

class _QrPaymentResultScreenState extends State<QrPaymentResultScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  bool _processing = false;

  String? get _merchantName => widget.fields['59'];
  String? get _merchantCity => widget.fields['60'];
  int? get _parsedAmount {
    final raw = widget.fields['54'];
    if (raw == null) return null;
    return int.tryParse(raw.split('.').first);
  }

  String? get _purpose {
    final additional = widget.fields['62_parsed'];
    return additional;
  }

  @override
  void initState() {
    super.initState();
    final amount = _parsedAmount;
    _amountCtrl = TextEditingController(text: amount != null && amount > 0 ? amount.toString() : '');
    _noteCtrl = TextEditingController(text: _purpose ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _hasFixedAmount => (_parsedAmount ?? 0) > 0;

  Future<void> _confirmPayment() async {
    final amountValue = int.tryParse(_amountCtrl.text.trim());
    if (amountValue == null || amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _processing = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _QrPaymentSuccessScreen(
          amount: amountValue,
          merchantName: _merchantName ?? 'Người/đơn vị thụ hưởng',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: shopeeOrange,
        foregroundColor: Colors.white,
        title: const Text('Xác nhận thanh toán'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFFFE8E1),
                      child: Icon(Icons.storefront, color: shopeeOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _merchantName ?? 'Người/đơn vị thụ hưởng',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          if (_merchantCity != null && _merchantCity!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _merchantCity!,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 8),
                _hasFixedAmount
                    ? Text(
                        formatVnd(_parsedAmount!),
                        style: const TextStyle(
                          color: shopeeOrange,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: shopeeOrange,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập số tiền',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                          suffixText: 'đ',
                          border: const UnderlineInputBorder(),
                        ),
                      ),
                if (!_hasFixedAmount)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Mã QR này không có sẵn số tiền — vui lòng nhập số tiền cần thanh toán.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lời nhắn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Nội dung chuyển khoản (không bắt buộc)',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                    border: const UnderlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: shopeeOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _processing ? null : _confirmPayment,
              child: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Xác nhận thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPaymentSuccessScreen extends StatelessWidget {
  final int amount;
  final String merchantName;

  const _QrPaymentSuccessScreen({required this.amount, required this.merchantName});

  static const Color shopeeOrange = Color(0xFFEE4D2D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: Color(0xFFE8F8EE), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF2FAE60), size: 56),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thanh toán thành công',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Đã thanh toán ${formatVnd(amount)} tới $merchantName',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shopeeOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Về Trang chủ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
