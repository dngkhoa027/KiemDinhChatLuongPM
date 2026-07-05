/// Dữ liệu 1 địa chỉ nhận hàng của người dùng, lưu ở Firestore
/// subcollection `users/{uid}/addresses/{addressId}`.
///
/// Dùng cấu trúc hành chính 3 cấp trước sáp nhập:
///   Tỉnh/Thành phố -> Quận/Huyện -> Phường/Xã
class Address {
  final String id;
  final String fullName;
  final String phone;
  final String detail; // số nhà, tên đường...
  final String ward; // Phường/Xã
  final String district; // Quận/Huyện
  final String province; // Tỉnh/Thành phố
  final String label; // "Nhà riêng" | "Văn phòng" | ...
  final bool isDefault;

  const Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.detail,
    required this.ward,
    required this.district,
    required this.province,
    this.label = 'Nhà riêng',
    this.isDefault = false,
  });

  /// Địa chỉ đầy đủ dùng để hiển thị (VD ở giỏ hàng, chi tiết đơn hàng...).
  String get fullAddress => [detail, ward, district, province]
      .where((e) => e.trim().isNotEmpty)
      .join(', ');

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      fullName: (data['fullName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      detail: (data['detail'] as String?) ?? '',
      ward: (data['ward'] as String?) ?? '',
      district: (data['district'] as String?) ?? '',
      province: (data['province'] as String?) ?? '',
      label: (data['label'] as String?) ?? 'Nhà riêng',
      isDefault: (data['isDefault'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'detail': detail,
      'ward': ward,
      'district': district,
      'province': province,
      'label': label,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? fullName,
    String? phone,
    String? detail,
    String? ward,
    String? district,
    String? province,
    String? label,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      detail: detail ?? this.detail,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      province: province ?? this.province,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
