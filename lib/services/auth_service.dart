import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

/// ============================================================
/// AUTH SERVICE
/// ------------------------------------------------------------
/// Gom toàn bộ logic đăng nhập / đăng ký / đọc-ghi thông tin quyền
/// (buyer hay seller) vào MỘT chỗ duy nhất, thay vì để rải rác trong
/// từng màn hình (login_screen, register_screen...). Nhờ vậy:
///   • Muốn đổi cách xác định quyền (VD: thêm role "admin", thêm
///     điều kiện duyệt shop...) chỉ cần sửa ở đây.
///   • Mọi màn hình chỉ cần gọi `AuthService.instance.xxx()`, không
///     cần biết chi tiết Firebase bên dưới.
/// ============================================================
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _usersRef => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _shopsRef => _db.collection('shops');

  /// Chuẩn hoá input đăng nhập/đăng ký: cho phép người dùng nhập số điện
  /// thoại thay vì email (giữ nguyên hành vi cũ của app).
  String normalizeEmailInput(String input) {
    final trimmed = input.trim();
    return trimmed.contains('@') ? trimmed : '$trimmed@app.com';
  }

  Future<UserCredential> login({required String emailOrPhone, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: normalizeEmailInput(emailOrPhone),
      password: password,
    );
  }

  /// Đăng ký tài khoản MỚI. Mặc định vai trò là [UserRole.buyer] — người
  /// dùng chỉ trở thành seller khi chủ động "Đăng ký kênh người bán" sau đó
  /// (xem [registerAsSeller]), KHÔNG phải ai đăng ký cũng tự động bán được.
  Future<UserCredential> register({
    required String name,
    required String emailOrPhone,
    required String password,
  }) async {
    final email = normalizeEmailInput(emailOrPhone);
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final appUser = AppUser(uid: uid, name: name, email: emailOrPhone.trim(), role: UserRole.buyer);
    await _usersRef.doc(uid).set(appUser.toMap());
    return credential;
  }

  Future<void> logout() => _auth.signOut();

  /// Lấy thông tin quyền hiện tại của user đang đăng nhập.
  /// Trả về `null` nếu chưa đăng nhập hoặc chưa có document (dữ liệu cũ
  /// tạo trước khi có hệ thống phân quyền) -> nơi gọi nên coi như buyer.
  Future<AppUser?> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _usersRef.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  /// Nâng cấp tài khoản buyer hiện tại lên seller: tạo document trong
  /// collection `shops` rồi cập nhật `role: seller` + `shopId` cho user.
  /// Trả về [Shop] vừa tạo? -> trả về `shopId` để màn hình điều hướng tiếp.
  Future<String> registerAsSeller({
    required String shopName,
    required String description,
    required String location,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Phải đăng nhập trước khi đăng ký kênh người bán.');
    }
    final shopDoc = _shopsRef.doc(); // tự sinh id
    await shopDoc.set({
      'ownerUid': uid,
      'name': shopName.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _usersRef.doc(uid).set({
      'role': userRoleToString(UserRole.seller),
      'shopId': shopDoc.id,
    }, SetOptions(merge: true));
    return shopDoc.id;
  }

  /// Cập nhật thông tin cá nhân (Thông tin cá nhân trong Cài đặt).
  /// Chỉ ghi những field được truyền vào (merge), không đụng tới các field
  /// khác như role/shopId đang được quản lý ở nơi khác.
  Future<void> updateProfile({
    String? name,
    String? gender,
    String? birthday,
    String? avatarUrl,
    String? phone,
    String? username,
    String? membershipTier,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Phải đăng nhập trước khi cập nhật thông tin cá nhân.');
    }
    await _usersRef.doc(uid).set({
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phone != null) 'phone': phone,
      if (username != null) 'username': username,
      if (membershipTier != null) 'membershipTier': membershipTier,
    }, SetOptions(merge: true));
    // Đồng bộ luôn tên hiển thị ở Firebase Auth (dùng cho các nơi khác nếu cần).
    if (name != null) {
      await _auth.currentUser?.updateDisplayName(name);
    }
  }

  /// Kiểm tra tên đăng nhập [username] đã có ai dùng chưa (trừ chính mình).
  /// Trả về true nếu còn trống (có thể dùng được).
  ///
  /// Nếu Firestore chặn quyền đọc (rule chưa publish, cấu hình sai...),
  /// hàm sẽ coi như "còn trống" thay vì làm hỏng cả thao tác Lưu — đây chỉ
  /// là 1 bước kiểm tra tiện ích, không nên vì nó lỗi mà chặn luôn việc
  /// lưu các thông tin khác (tên, SĐT, avatar...).
  Future<bool> isUsernameAvailable(String username) async {
    final uid = _auth.currentUser?.uid;
    try {
      final query = await _usersRef.where('username', isEqualTo: username).limit(2).get();
      if (query.docs.isEmpty) return true;
      // Còn trống nếu tài liệu duy nhất trùng chính là của mình.
      return query.docs.length == 1 && query.docs.first.id == uid;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return true;
      rethrow;
    }
  }

  /// Đổi mật khẩu: Firebase yêu cầu xác thực lại (re-authenticate) bằng
  /// mật khẩu hiện tại trước khi cho phép đổi, vì lý do bảo mật (tránh
  /// trường hợp phiên đăng nhập cũ bị lợi dụng để đổi mật khẩu).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Phải đăng nhập trước khi đổi mật khẩu.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
