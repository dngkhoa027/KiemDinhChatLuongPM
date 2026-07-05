import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

/// ============================================================
/// SHOP SERVICE
/// ------------------------------------------------------------
/// Quản lý dữ liệu của riêng NGƯỜI BÁN: thông tin shop + sản phẩm do
/// seller tự đăng (Firestore collection `products`). Sản phẩm demo lấy
/// từ DummyJSON (ProductApiService) KHÔNG đi qua service này.
///
/// Vì [Product.id] hiện tại là `int` (để tương thích với ProductDetailScreen
/// / ProductApiService đang seed theo id số), mỗi sản phẩm seller đăng sẽ
/// được gán 1 id số cục bộ dựa trên hash id document Firestore — id THẬT để
/// đọc/sửa/xoá vẫn là `docId` (String) của Firestore, lưu riêng.
/// ============================================================
class ShopService {
  ShopService._();
  static final ShopService instance = ShopService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shopsRef => _db.collection('shops');
  CollectionReference<Map<String, dynamic>> get _productsRef => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _usersRef => _db.collection('users');

  Future<Shop?> fetchShop(String shopId) async {
    final snap = await _shopsRef.doc(shopId).get();
    if (!snap.exists) return null;
    return Shop.fromMap(snap.id, snap.data()!);
  }

  /// Đăng 1 sản phẩm mới lên shop của seller.
  Future<String> addProduct({
    required String sellerId,
    required String shopId,
    required Product product,
  }) async {
    final doc = _productsRef.doc();
    await doc.set({
      ...product.toSellerMap(),
      'sellerId': sellerId,
      'shopId': shopId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateProduct(String docId, Product product) {
    return _productsRef.doc(docId).update(product.toSellerMap());
  }

  Future<void> deleteProduct(String docId) {
    return _productsRef.doc(docId).delete();
  }

  /// Lấy danh sách sản phẩm hiện có của 1 shop (dùng cho màn hình
  /// "Kênh Người Bán" -> tab "Sản phẩm của tôi").
  /// Trả về kèm [docId] (id Firestore thật) vì [Product.id] chỉ là id số
  /// cục bộ dùng để mở ProductDetailScreen, không dùng để sửa/xoá.
  Future<List<MapEntry<String, Product>>> fetchShopProducts(String shopId) async {
    final snap = await _productsRef.where('shopId', isEqualTo: shopId).get();
    return snap.docs.map((d) {
      final localId = d.id.hashCode & 0x7fffffff;
      return MapEntry(d.id, Product.fromSellerMap(localId, d.data()));
    }).toList();
  }

  // =========================================================
  // THEO DÕI SHOP (follow / unfollow)
  // ---------------------------------------------------------
  // Lưu danh sách id các shop mà 1 user đang theo dõi ngay trong
  // document users/{uid}, ở field mảng `followingShopIds`. Nhờ đó:
  //   • Số "Đang theo dõi" ở trang Profile = độ dài mảng này, LUÔN
  //     phản ánh đúng số shop user đã thực sự bấm theo dõi (không còn
  //     là số cố định hard-code).
  //   • Muốn biết đang theo dõi shop nào chỉ cần đọc field này, không
  //     cần query thêm collection nào khác.
  // =========================================================

  /// Danh sách id các shop mà [uid] đang theo dõi.
  Future<List<String>> fetchFollowingShopIds(String uid) async {
    final snap = await _usersRef.doc(uid).get();
    final raw = snap.data()?['followingShopIds'] as List<dynamic>?;
    return raw?.map((e) => e.toString()).toList() ?? const [];
  }

  /// Số lượng shop [uid] đang theo dõi -> dùng cho "Đang theo dõi" ở Profile.
  Future<int> fetchFollowingCount(String uid) async {
    final ids = await fetchFollowingShopIds(uid);
    return ids.length;
  }

  Future<bool> isFollowingShop({required String uid, required String shopId}) async {
    final ids = await fetchFollowingShopIds(uid);
    return ids.contains(shopId);
  }

  /// Bấm "+ Theo dõi": thêm [shopId] vào danh sách theo dõi của [uid].
  Future<void> followShop({required String uid, required String shopId}) {
    return _usersRef.doc(uid).set({
      'followingShopIds': FieldValue.arrayUnion([shopId]),
    }, SetOptions(merge: true));
  }

  /// Bấm lại "Đang theo dõi" để bỏ theo dõi.
  Future<void> unfollowShop({required String uid, required String shopId}) {
    return _usersRef.doc(uid).set({
      'followingShopIds': FieldValue.arrayRemove([shopId]),
    }, SetOptions(merge: true));
  }
}
