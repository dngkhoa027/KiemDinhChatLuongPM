import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/shop_service.dart';

/// Form đăng (hoặc sửa) 1 sản phẩm cho shop của seller.
/// Chỉ dùng các trường cơ bản để dễ mở rộng thêm sau (nhiều ảnh, phân loại,
/// vận chuyển...) mà không phá vỡ [Product] hiện có.
class AddEditProductScreen extends StatefulWidget {
  final String sellerId;
  final String shopId;
  final String shopName;

  const AddEditProductScreen({
    super.key,
    required this.sellerId,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '100');
  final _imageUrlController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final price = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final product = Product(
      id: 0, // sẽ không dùng, ShopService tự sinh id cục bộ khi đọc lại
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      originalPrice: price,
      discountPercent: 0,
      rating: 5.0,
      ratingCount: 0,
      soldCount: 0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      category: 'seller',
      categoryLabel: 'Sản phẩm của Shop',
      brand: widget.shopName,
      shopName: widget.shopName,
      location: 'TP. Hồ Chí Minh',
      images: _imageUrlController.text.trim().isEmpty ? const [] : [_imageUrlController.text.trim()],
      sellerId: widget.sellerId,
      shopId: widget.shopId,
      isUserListed: true,
    );

    try {
      await ShopService.instance.addProduct(sellerId: widget.sellerId, shopId: widget.shopId, product: product);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng sản phẩm thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: shopeeOrange,
        foregroundColor: Colors.white,
        title: const Text('Đăng Sản Phẩm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Tên Sản Phẩm'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
              ),
              const SizedBox(height: 14),
              _label('Mô Tả'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 14),
              _label('Giá Bán (VNĐ)'),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'VD: 150000'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
                  return (n == null || n <= 0) ? 'Vui lòng nhập giá hợp lệ' : null;
                },
              ),
              const SizedBox(height: 14),
              _label('Tồn Kho'),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              _label('Link Ảnh Sản Phẩm (URL)'),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'https://...'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(backgroundColor: shopeeOrange, foregroundColor: Colors.white),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng Bán', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );
}
