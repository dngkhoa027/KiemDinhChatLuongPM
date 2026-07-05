import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../services/auth_service.dart';
import '../../services/shop_service.dart';
import 'add_edit_product_screen.dart';

/// Trang chính "Kênh Người Bán": hiển thị thông tin shop + danh sách sản
/// phẩm đã đăng, có nút "Đăng sản phẩm" để thêm mới.
class SellerDashboardScreen extends StatefulWidget {
  final String shopId;
  const SellerDashboardScreen({super.key, required this.shopId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);

  Shop? _shop;
  List<MapEntry<String, Product>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final shop = await ShopService.instance.fetchShop(widget.shopId);
    final products = await ShopService.instance.fetchShopProducts(widget.shopId);
    if (!mounted) return;
    setState(() {
      _shop = shop;
      _products = products;
      _loading = false;
    });
  }

  Future<void> _openAddProduct() async {
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(sellerId: uid, shopId: widget.shopId, shopName: _shop?.name ?? ''),
      ),
    );
    if (created == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: shopeeOrange,
        foregroundColor: Colors.white,
        title: const Text('Kênh Người Bán'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        backgroundColor: shopeeOrange,
        icon: const Icon(Icons.add),
        label: const Text('Đăng sản phẩm'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: shopeeOrange))
          : RefreshIndicator(
              color: shopeeOrange,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildShopHeader(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Sản phẩm của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Text('${_products.length} sản phẩm', style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text('Bạn chưa đăng sản phẩm nào.', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  else
                    ..._products.map((entry) => _buildProductTile(entry.key, entry.value)),
                ],
              ),
            ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: shopeeOrange.withOpacity(0.1),
            child: const Icon(Icons.storefront, color: shopeeOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_shop?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Text(_shop?.location ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(String docId, Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 56,
              child: p.thumbnail.isEmpty
                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                  : Image.network(
                      p.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(p.priceText, style: const TextStyle(color: shopeeOrange, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await ShopService.instance.deleteProduct(docId);
                _loadData();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Xoá sản phẩm')),
            ],
          ),
        ],
      ),
    );
  }
}
