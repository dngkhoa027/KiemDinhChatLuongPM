/// Dữ liệu 1 gian hàng (shop) do người dùng tự mở, lưu ở Firestore
/// collection `shops`, document id trùng với `shopId` (tự sinh khi tạo).
class Shop {
  final String id;
  final String ownerUid; // uid của user sở hữu shop này (users/{ownerUid})
  final String name;
  final String description;
  final String location;
  final DateTime createdAt;

  const Shop({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.location,
    required this.createdAt,
  });

  factory Shop.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    DateTime created;
    if (ts is DateTime) {
      created = ts;
    } else if (ts != null && ts.runtimeType.toString() == 'Timestamp') {
      // Tránh import trực tiếp cloud_firestore vào model để giữ model thuần
      // Dart (không phụ thuộc Firebase) -> dùng dynamic + toDate() động.
      created = (ts as dynamic).toDate() as DateTime;
    } else {
      created = DateTime.now();
    }
    return Shop(
      id: id,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'location': location,
      'createdAt': createdAt,
    };
  }
}
