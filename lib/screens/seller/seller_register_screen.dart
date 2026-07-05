import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'seller_dashboard_screen.dart';

/// Màn hình "Đăng ký kênh người bán": buyer điền thông tin shop, bấm
/// Đăng ký -> tài khoản được nâng cấp thành seller (xem
/// [AuthService.registerAsSeller]) rồi chuyển thẳng sang trang quản lý shop.
class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: 'TP. Hồ Chí Minh');

  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final shopId = await AuthService.instance.registerAsSeller(
        shopName: _shopNameController.text,
        description: _descriptionController.text,
        location: _locationController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mở shop thành công! Chào mừng bạn đến với Kênh Người Bán 🎉')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SellerDashboardScreen(shopId: shopId)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: shopeeOrange,
        foregroundColor: Colors.white,
        title: const Text('Đăng Ký Kênh Người Bán'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: shopeeOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront, color: shopeeOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mở shop miễn phí để bắt đầu đăng bán sản phẩm của riêng bạn.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Tên Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  hintText: 'VD: Breezy Living',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên shop' : null,
              ),
              const SizedBox(height: 16),
              const Text('Mô Tả Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Giới thiệu ngắn về shop của bạn...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mô tả shop' : null,
              ),
              const SizedBox(height: 16),
              const Text('Địa Chỉ Gửi Hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shopeeOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng Ký Bán Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
