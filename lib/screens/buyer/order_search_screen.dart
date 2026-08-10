import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'my_orders_screen.dart';

/// Trang tìm kiếm trong "Đơn mua" — mở từ icon kính lúp ở [MyOrdersScreen].
/// Cho phép gõ để lọc realtime theo tên sản phẩm, tên shop hoặc mã đơn
/// hàng, dùng lại đúng [OrderCard] để kết quả tìm kiếm giống hệt giao diện
/// danh sách đơn hàng gốc.
class OrderSearchScreen extends StatefulWidget {
  const OrderSearchScreen({super.key});

  @override
  State<OrderSearchScreen> createState() => _OrderSearchScreenState();
}

class _OrderSearchScreenState extends State<OrderSearchScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color pageBg = Color(0xFFF5F5F5);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  // Vài gợi ý tìm kiếm gần đây — demo dùng dữ liệu tĩnh, có thể thay bằng
  // lưu trữ thật (SharedPreferences) sau này mà không cần đổi UI.
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Order> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return OrderService.instance.orders.where((o) {
      if (o.id.toLowerCase().contains(q)) return true;
      for (final item in o.items) {
        if (item.name.toLowerCase().contains(q)) return true;
        if (item.shopName.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  void _runSearch(String value) {
    setState(() => _query = value);
  }

  void _submitSearch(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    setState(() {
      _query = v;
      _recentSearches.remove(v);
      _recentSearches.insert(0, v);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    });
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: pageBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _runSearch,
            onSubmitted: _submitSearch,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Tìm theo tên sản phẩm, shop, mã đơn',
              hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
              prefixIconConstraints: const BoxConstraints(minWidth: 36),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: _clear,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: pageBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.black87, fontSize: 14)),
          ),
        ],
      ),
      body: _query.trim().isEmpty ? _suggestionsView() : _resultsView(),
    );
  }

  Widget _suggestionsView() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Tìm đơn hàng theo tên sản phẩm,\ntên shop hoặc mã đơn hàng',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tìm kiếm gần đây',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              InkWell(
                onTap: () => setState(() => _recentSearches.clear()),
                child: Text('Xóa tất cả', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
              ),
            ],
          ),
        ),
        for (final term in _recentSearches)
          ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 20, color: Colors.grey),
            title: Text(term, style: const TextStyle(fontSize: 13.5)),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: () => setState(() => _recentSearches.remove(term)),
            ),
            onTap: () {
              _controller.text = term;
              _controller.selection = TextSelection.collapsed(offset: term.length);
              _submitSearch(term);
            },
          ),
      ],
    );
  }

  Widget _resultsView() {
    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy đơn hàng phù hợp với\n"${_query.trim()}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
      itemCount: results.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OrderCard(order: results[i]),
      ),
    );
  }
}
