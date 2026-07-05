/// Vai trò của tài khoản trong app.
///
/// - [buyer]: tài khoản mặc định khi đăng ký, chỉ có thể mua hàng.
/// - [seller]: tài khoản đã đăng ký kênh người bán, có thể đăng/sửa/xoá
///   sản phẩm của chính shop mình, xem đơn hàng của shop.
/// - [admin]: (dự phòng cho sau này) quản trị toàn hệ thống.
enum UserRole { buyer, seller, admin }

UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'seller':
      return UserRole.seller;
    case 'admin':
      return UserRole.admin;
    case 'buyer':
    default:
      return UserRole.buyer;
  }
}

String userRoleToString(UserRole role) => role.name;

/// Dữ liệu người dùng lấy từ Firestore collection `users`.
/// Đây là "nguồn sự thật" duy nhất về việc 1 tài khoản là buyer hay seller,
/// mọi màn hình cần kiểm tra quyền (phân quyền) đều nên dựa vào [role] ở đây
/// thay vì tự đoán/tự lưu cờ ở nơi khác.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? shopId; // null nếu chưa mở shop (chưa là seller)
  final String? gender; // "Nam" | "Nữ" | "Khác" | null (chưa cập nhật)
  final String? birthday; // lưu dạng "dd/MM/yyyy" cho đơn giản, không ép kiểu DateTime
  final String? avatarUrl; // URL ảnh (http...) HOẶC ảnh base64 (data:image/...;base64,...)
  final String? phone; // SĐT liên hệ, khác với email/SĐT dùng để đăng nhập
  final String? username; // "tên đăng nhập" / handle hiển thị, VD 23.thnhn
  final String membershipTier; // Hạng thành viên: Thành viên/Bạc/Vàng/Bạch Kim/Kim Cương

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.buyer,
    this.shopId,
    this.gender,
    this.birthday,
    this.avatarUrl,
    this.phone,
    this.username,
    this.membershipTier = 'Thành viên',
  });

  bool get isSeller => role == UserRole.seller || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: userRoleFromString(data['role'] as String?),
      shopId: data['shopId'] as String?,
      gender: data['gender'] as String?,
      birthday: data['birthday'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      phone: data['phone'] as String?,
      username: data['username'] as String?,
      membershipTier: (data['membershipTier'] as String?) ?? 'Thành viên',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': userRoleToString(role),
      if (shopId != null) 'shopId': shopId,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phone != null) 'phone': phone,
      if (username != null) 'username': username,
      'membershipTier': membershipTier,
    };
  }

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? shopId,
    String? gender,
    String? birthday,
    String? avatarUrl,
    String? phone,
    String? username,
    String? membershipTier,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      membershipTier: membershipTier ?? this.membershipTier,
    );
  }
}
