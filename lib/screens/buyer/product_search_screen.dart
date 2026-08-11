import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_api_service.dart';
import 'product_detail_screen.dart';

/// Trang tìm kiếm sản phẩm — mở khi bấm vào thanh tìm kiếm ở trang Home.
/// Gõ để lọc realtime theo tên / thương hiệu / danh mục sản phẩm; chưa gõ
/// gì thì hiện "Tìm kiếm gần đây" + gợi ý từ khoá hot, giống Shopee thật.
class ProductSearchScreen extends StatefulWidget {
  /// Từ khoá gợi ý đang hiển thị xoay vòng ở ô tìm kiếm trang Home lúc
  /// người dùng bấm vào — dùng làm hint mặc định ở đây cho liền mạch.
  final String? initialHint;

  /// Nếu được truyền, tự động điền + chạy tìm kiếm luôn khi mở màn (dùng
  /// khi mở từ kết quả quét mã QR hoặc tìm kiếm bằng hình ảnh).
  final String? initialQuery;

  const ProductSearchScreen({super.key, this.initialHint, this.initialQuery});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  static const Color orange = Color(0xFFEE4D2D);
  static const Color red = Color(0xFFF53D2D);
  static const Color pageBg = Color(0xFFF5F5F5);

  static const List<String> _trending = [
    'iPhone 17',
    'Áo thun nam',
    'Giày sneaker',
    'Nồi chiên không dầu',
    'Mỹ phẩm chính hãng',
    'Balo laptop',
    'Đồng hồ nam',
    'Son môi',
  ];

  // Kho từ khoá gợi ý kiểu Shopee thật — khi người dùng đang gõ (chưa bấm
  // Tìm), ta lọc trong danh sách này để hiện các cụm từ liên quan thay vì
  // hiện sản phẩm ngay. Danh sách càng nhiều càng gợi ý được nhiều trường
  // hợp gõ khác nhau.
  static const List<String> _suggestionPool = [
    // Thời trang nam
    'áo khoác nam', 'áo thun nam', 'áo phông nam', 'áo polo nam', 'áo sơ mi nam',
    'áo thun tay dài', 'áo tay dài', 'áo phông trắng', 'áo len nam', 'áo hoodie nam',
    'quần jean nam', 'quần tây nam', 'quần short nam', 'quần jogger nam', 'quần dài nam',
    // Thời trang nữ
    'áo kiểu nữ', 'áo khoác nữ', 'áo len nữ', 'áo dài cách tân', 'áo croptop nữ',
    'đầm nữ công sở', 'chân váy nữ', 'quần jean nữ ống rộng', 'quần short nữ',
    // Giày dép
    'giày sneaker nam', 'giày thể thao nữ', 'giày cao gót', 'dép nam', 'dép quai ngang',
    'giày da nam công sở', 'giày lười nữ',
    // Điện thoại / phụ kiện
    'iphone 17', 'iphone 15', 'samsung galaxy', 'tai nghe bluetooth', 'sạc dự phòng',
    'ốp lưng iphone', 'cáp sạc type c', 'chuột không dây', 'bàn phím cơ',
    // Đồ gia dụng
    'nồi chiên không dầu', 'máy xay sinh tố', 'bình giữ nhiệt', 'chảo chống dính',
    'nồi cơm điện', 'máy lọc không khí', 'quạt điều hòa',
    // Mỹ phẩm / làm đẹp
    'son môi', 'kem chống nắng', 'sữa rửa mặt', 'nước hoa nữ', 'mặt nạ dưỡng da',
    'serum trị mụn', 'kem dưỡng ẩm', 'phấn phủ kiềm dầu',
    // Túi / phụ kiện
    'balo laptop', 'túi xách nữ', 'ví nam da thật', 'đồng hồ nam', 'kính mát nam',
    'thắt lưng nam da',
    // Mẹ & bé, sách, khác
    'sách giáo trình', 'đồ chơi trẻ em', 'bỉm tã em bé', 'sữa bột trẻ em',
    'bàn phím laptop', 'chuột gaming', 'loa bluetooth mini',
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _recentSearches = [];

  String _query = '';
  // true khi người dùng đã bấm Enter/"Tìm" hoặc chọn 1 gợi ý — lúc đó mới
  // hiển thị sản phẩm thật; còn lại (đang gõ dở) chỉ hiện gợi ý từ khoá.
  bool _submitted = false;
  bool _loading = true;
  String? _error;
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _controller.text = widget.initialQuery!.trim();
      _query = widget.initialQuery!.trim();
      _submitted = true;
      _recentSearches.insert(0, widget.initialQuery!.trim());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ProductApiService.fetchProducts(limit: 100, skip: 0);
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải sản phẩm. Vui lòng kiểm tra kết nối mạng.';
        _loading = false;
      });
    }
  }

  List<Product> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _allProducts.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.categoryLabel.toLowerCase().contains(q) ||
          p.shopName.toLowerCase().contains(q);
    }).toList();
  }

  /// Danh sách cụm từ gợi ý khớp với những gì đang gõ — ưu tiên cụm bắt
  /// đầu bằng từ khoá trước, sau đó mới đến cụm chỉ chứa từ khoá ở giữa.
  List<String> get _suggestions {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final startsWith = <String>[];
    final contains = <String>[];
    for (final phrase in _suggestionPool) {
      final lower = phrase.toLowerCase();
      if (lower.startsWith(q)) {
        startsWith.add(phrase);
      } else if (lower.contains(q)) {
        contains.add(phrase);
      }
    }
    return [...startsWith, ...contains].take(8).toList();
  }

  void _runSearch(String value) => setState(() {
        _query = value;
        _submitted = false;
      });

  void _submitSearch(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    _focusNode.unfocus();
    setState(() {
      _query = v;
      _submitted = true;
      _recentSearches.remove(v);
      _recentSearches.insert(0, v);
      if (_recentSearches.length > 10) _recentSearches.removeLast();
    });
  }

  void _selectTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _submitSearch(term);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _query = '';
      _submitted = false;
    });
    _focusNode.requestFocus();
  }

  void _openProduct(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          seedId: p.id,
          fallbackName: p.name,
          fallbackImage: p.thumbnail,
          fallbackPrice: p.price,
          fallbackOriginalPrice: p.originalPrice,
          fallbackDiscount: p.discountPercent,
          fallbackRating: p.rating,
          fallbackSoldCount: p.soldCount,
          fallbackLocation: p.location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: orange,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 38,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
              hintText: widget.initialHint ?? 'Tìm sản phẩm, thương hiệu, shop...',
              hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
              prefixIconConstraints: const BoxConstraints(minWidth: 36),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: _clear,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
      body: _query.trim().isEmpty
          ? _suggestionsView()
          : (_submitted ? _resultsView() : _keywordSuggestionsView()),
    );
  }

  // ================= Gợi ý từ khoá khi ĐANG GÕ (chưa Enter) =================
  Widget _keywordSuggestionsView() {
    final suggestions = _suggestions;
    if (suggestions.isEmpty) {
      // Không có gợi ý khớp — vẫn cho phép tìm thẳng với đúng từ đang gõ.
      return ListView(
        children: [_suggestionRow(_query.trim())],
      );
    }
    return ListView.separated(
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, i) => _suggestionRow(suggestions[i]),
    );
  }

  Widget _suggestionRow(String phrase) {
    final q = _query.trim().toLowerCase();
    final lower = phrase.toLowerCase();
    final matchIndex = lower.indexOf(q);
    Widget label;
    if (q.isNotEmpty && matchIndex != -1) {
      label = RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          children: [
            TextSpan(text: phrase.substring(0, matchIndex)),
            TextSpan(
              text: phrase.substring(matchIndex, matchIndex + q.length),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: phrase.substring(matchIndex + q.length)),
          ],
        ),
      );
    } else {
      label = Text(phrase, style: const TextStyle(fontSize: 15, color: Colors.black87));
    }

    return InkWell(
      onTap: () => _selectTerm(phrase),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(child: label),
            Icon(Icons.north_west, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ================= Gợi ý khi chưa gõ gì =================
  Widget _suggestionsView() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tìm kiếm gần đây',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                InkWell(
                  onTap: () => setState(() => _recentSearches.clear()),
                  child: Text('Xóa tất cả', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in _recentSearches)
                  InputChip(
                    label: Text(term, style: const TextStyle(fontSize: 12.5)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: () => _selectTerm(term),
                    onDeleted: () => setState(() => _recentSearches.remove(term)),
                    deleteIconColor: Colors.grey.shade500,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 6, color: pageBg),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, size: 17, color: red),
              const SizedBox(width: 4),
              Text('Xu hướng tìm kiếm',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in _trending)
                InkWell(
                  onTap: () => _selectTerm(term),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(term, style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ================= Kết quả tìm kiếm =================
  Widget _resultsView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: orange));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _loadProducts, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

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
                'Không tìm thấy sản phẩm phù hợp với\n"${_query.trim()}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemCount: results.length,
      itemBuilder: (context, i) => _ProductResultCard(product: results[i], onTap: () => _openProduct(results[i])),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductResultCard({required this.product, required this.onTap});

  static const Color orange = Color(0xFFEE4D2D);
  static const Color red = Color(0xFFF53D2D);

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: p.thumbnail.isEmpty
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                        )
                      : Image.network(
                          p.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        ),
                ),
                if (p.discountPercent > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: const BoxDecoration(
                        color: red,
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(6)),
                      ),
                      child: Text(
                        '-${p.discountPercent}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.25, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.priceText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: orange),
                  ),
                  if (p.originalPrice > p.price) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.originalPriceText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(p.rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(width: 6),
                      Text('Đã bán ${p.soldText}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
