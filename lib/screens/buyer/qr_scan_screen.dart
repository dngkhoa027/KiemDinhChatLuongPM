import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'product_search_screen.dart';
import 'qr_payment_result_screen.dart';

/// Màn hình "Camera" mở từ icon máy ảnh cạnh ô tìm kiếm (Trang chủ, Mall...).
/// Gồm 2 chế độ, chuyển bằng tab ở dưới cùng, giống Shopee thật:
///   • Quét mã QR — dùng camera quét trực tiếp. Tự nhận diện:
///       - Mã QR thanh toán (chuẩn EMVCo/VietQR) -> mở màn xác nhận thanh toán.
///       - Mã QR khác (link, chữ...) -> hiện bảng kết quả để copy/tìm kiếm.
///   • Tìm theo hình ảnh — chọn/chụp ảnh sản phẩm rồi tìm sản phẩm liên quan.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

enum _ScanMode { qr, image }

class _QrScanScreenState extends State<QrScanScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  _ScanMode _mode = _ScanMode.qr;
  final MobileScannerController _scannerController = MobileScannerController();

  // Chặn xử lý trùng khi camera bắn nhiều frame liên tiếp cho cùng 1 mã,
  // và chặn không cho gọi start()/stop() chồng chéo nhau (đây chính là
  // nguyên nhân gây lỗi "hiện thông báo lỗi liên tục" trước đây).
  bool _isSheetOpen = false;
  bool _isLeavingScreen = false;

  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _searchingImage = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ================= QR: xử lý khi quét được mã =================
  void _onDetect(BarcodeCapture capture) {
    if (_isSheetOpen || _isLeavingScreen) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _isSheetOpen = true;
    _scannerController.stop();

    if (_looksLikeEmvPaymentQr(raw)) {
      _openPaymentResult(raw);
    } else {
      _showScanResultSheet(raw);
    }
  }

  /// Sau khi xử lý xong 1 lượt quét (đóng bảng kết quả, đóng màn thanh
  /// toán...), quay lại trạng thái quét tiếp — trừ khi đang rời khỏi hẳn
  /// màn hình quét (ví dụ đã điều hướng sang màn tìm kiếm/thanh toán).
  void _resumeScanningIfStillHere() {
    _isSheetOpen = false;
    if (_isLeavingScreen || !mounted) return;
    _scannerController.start();
  }

  // ---- Nhận diện mã QR thanh toán chuẩn EMVCo (VietQR / QR ngân hàng) ----
  bool _looksLikeEmvPaymentQr(String raw) {
    return raw.length > 20 && raw.startsWith('000201');
  }

  /// Parse cấu trúc TLV (Tag-Length-Value) chuẩn EMVCo: mỗi trường gồm
  /// 2 ký tự mã trường + 2 ký tự độ dài + nội dung. VietQR và hầu hết QR
  /// thanh toán ngân hàng tại Việt Nam đều theo đúng chuẩn này.
  Map<String, String> _parseEmvFields(String raw) {
    final map = <String, String>{};
    int i = 0;
    while (i + 4 <= raw.length) {
      final tag = raw.substring(i, i + 2);
      final lenStr = raw.substring(i + 2, i + 4);
      final len = int.tryParse(lenStr);
      if (len == null) break;
      final start = i + 4;
      final end = start + len;
      if (end > raw.length) break;
      map[tag] = raw.substring(start, end);
      i = end;
    }
    // Trường 62 (Additional Data) có thể chứa nested TLV, trong đó tag 08
    // thường là "nội dung/mục đích chuyển khoản" -> tách ra để gợi ý sẵn
    // vào ô "Lời nhắn" cho người dùng.
    final additional = map['62'];
    if (additional != null) {
      final nested = <String, String>{};
      int j = 0;
      while (j + 4 <= additional.length) {
        final tag = additional.substring(j, j + 2);
        final lenStr = additional.substring(j + 2, j + 4);
        final len = int.tryParse(lenStr);
        if (len == null) break;
        final start = j + 4;
        final end = start + len;
        if (end > additional.length) break;
        nested[tag] = additional.substring(start, end);
        j = end;
      }
      if (nested['08'] != null) map['62_parsed'] = nested['08']!;
    }
    return map;
  }

  void _openPaymentResult(String raw) {
    final fields = _parseEmvFields(raw);
    _isLeavingScreen = true;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => QrPaymentResultScreen(rawValue: raw, fields: fields),
      ),
    )
        .then((_) {
      // Người dùng bấm Back từ màn thanh toán quay lại đây -> cho quét tiếp.
      _isLeavingScreen = false;
      _resumeScanningIfStillHere();
    });
  }

  void _showScanResultSheet(String value) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: shopeeOrange, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Đã quét được mã',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(value, style: const TextStyle(fontSize: 13.5)),
                ),
                const SizedBox(height: 16),
                if (_looksLikeUrl(value))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx, 'copy'),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Sao chép liên kết'),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shopeeOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, 'search'),
                    icon: const Icon(Icons.search, size: 19),
                    label: const Text('Tìm kiếm nội dung này'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Quét mã khác', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((action) {
      // Đúng 1 điểm xử lý duy nhất sau khi bảng kết quả đóng lại, dù đóng
      // bằng cách nào (bấm nút hay vuốt xuống) — tránh gọi start()/điều
      // hướng chồng chéo nhau.
      if (action == 'copy') {
        Clipboard.setData(ClipboardData(text: value));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã sao chép liên kết')),
          );
        }
        _resumeScanningIfStillHere();
      } else if (action == 'search') {
        _isLeavingScreen = true;
        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.pop(); // đóng luôn màn quét, quay lại màn trước
        navigator.push(
          MaterialPageRoute(builder: (_) => ProductSearchScreen(initialQuery: value)),
        );
      } else {
        // null: bấm "Quét mã khác" hoặc vuốt tắt bảng kết quả.
        _resumeScanningIfStillHere();
      }
    });
  }

  bool _looksLikeUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  // ================= Tìm theo hình ảnh =================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _pickedImage = File(file.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ảnh, vui lòng thử lại.')),
      );
    }
  }

  /// Demo tìm sản phẩm theo hình ảnh: app này chưa có backend AI nhận diện
  /// ảnh thật, nên để trải nghiệm vẫn liền mạch, ta mở thẳng kết quả tìm
  /// kiếm sản phẩm (ProductSearchScreen) — giữ đúng luồng UX (chọn ảnh ->
  /// ra sản phẩm liên quan) dù chưa gắn AI nhận diện ảnh thật.
  Future<void> _searchByPickedImage() async {
    if (_pickedImage == null) return;
    setState(() => _searchingImage = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _searchingImage = false);
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProductSearchScreen(
          initialHint: 'Kết quả tìm theo hình ảnh',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_mode == _ScanMode.qr ? 'Quét mã QR' : 'Tìm theo hình ảnh'),
        actions: [
          if (_mode == _ScanMode.qr)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () {
                try {
                  _scannerController.toggleTorch();
                } catch (_) {
                  // Một số thiết bị/giả lập không có đèn flash — bỏ qua lỗi.
                }
              },
            ),
        ],
      ),
      body: _mode == _ScanMode.qr ? _buildQrView() : _buildImageSearchView(),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _modeButton(
                icon: Icons.qr_code_scanner,
                label: 'Quét mã QR',
                selected: _mode == _ScanMode.qr,
                onTap: () => setState(() => _mode = _ScanMode.qr),
              ),
              _modeButton(
                icon: Icons.image_search,
                label: 'Tìm theo hình ảnh',
                selected: _mode == _ScanMode.image,
                onTap: () => setState(() => _mode = _ScanMode.image),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? shopeeOrange : Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ================= UI: chế độ quét QR =================
  Widget _buildQrView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off, color: Colors.grey.shade500, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Không thể mở camera.\nVui lòng cấp quyền camera cho ứng dụng trong Cài đặt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
        // Lớp phủ tối + khung quét ở giữa, giống Shopee/Zalo.
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: shopeeOrange, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Text(
            'Đưa mã QR vào giữa khung để quét\n(hỗ trợ cả mã QR thanh toán VietQR)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ================= UI: chế độ tìm theo hình ảnh =================
  Widget _buildImageSearchView() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _pickedImage == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_search, size: 72, color: Colors.grey.shade600),
                        const SizedBox(height: 12),
                        Text(
                          'Chọn hoặc chụp ảnh sản phẩm\nđể tìm các sản phẩm tương tự',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5, height: 1.4),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_pickedImage!, fit: BoxFit.contain),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_pickedImage != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: shopeeOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _searchingImage ? null : _searchByPickedImage,
                icon: _searchingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search, size: 19),
                label: Text(_searchingImage ? 'Đang tìm kiếm...' : 'Tìm sản phẩm tương tự'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Chụp ảnh'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Thư viện ảnh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
