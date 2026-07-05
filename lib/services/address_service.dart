import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

/// ============================================================
/// ADDRESS SERVICE
/// ------------------------------------------------------------
/// Quản lý sổ địa chỉ của MỘT user, lưu ở subcollection
/// `users/{uid}/addresses/{addressId}`. Gom riêng ra 1 service (thay vì
/// nhét vào AuthService) vì đây là dữ liệu nghiệp vụ "địa chỉ giao hàng",
/// không phải dữ liệu định danh/phân quyền tài khoản.
/// ============================================================
class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _addressesRef(String uid) =>
      _db.collection('users').doc(uid).collection('addresses');

  Future<List<Address>> fetchAddresses(String uid) async {
    final snap = await _addressesRef(uid).get();
    final list = snap.docs.map((d) => Address.fromMap(d.id, d.data())).toList();
    // Địa chỉ mặc định hiển thị lên đầu.
    list.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
    return list;
  }

  /// Thêm địa chỉ mới. Nếu đây là địa chỉ đầu tiên hoặc [setAsDefault]
  /// được yêu cầu, nó sẽ tự động thành địa chỉ mặc định (và bỏ mặc định
  /// khỏi các địa chỉ còn lại).
  Future<void> addAddress({
    required String uid,
    required Address address,
    bool setAsDefault = false,
  }) async {
    final ref = _addressesRef(uid);
    final existing = await ref.get();
    final shouldBeDefault = setAsDefault || existing.docs.isEmpty;
    if (shouldBeDefault) {
      await _clearDefault(uid, existing.docs);
    }
    await ref.add(address.copyWith(isDefault: shouldBeDefault).toMap());
  }

  Future<void> updateAddress({
    required String uid,
    required Address address,
  }) async {
    if (address.isDefault) {
      final existing = await _addressesRef(uid).get();
      await _clearDefault(uid, existing.docs, exceptId: address.id);
    }
    await _addressesRef(uid).doc(address.id).set(address.toMap());
  }

  Future<void> deleteAddress({required String uid, required String addressId}) {
    return _addressesRef(uid).doc(addressId).delete();
  }

  /// Đặt [addressId] làm địa chỉ mặc định, bỏ mặc định khỏi các địa chỉ khác.
  Future<void> setDefaultAddress({required String uid, required String addressId}) async {
    final ref = _addressesRef(uid);
    final existing = await ref.get();
    await _clearDefault(uid, existing.docs, exceptId: addressId);
    await ref.doc(addressId).update({'isDefault': true});
  }

  Future<void> _clearDefault(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    String? exceptId,
  }) async {
    final batch = _db.batch();
    for (final doc in docs) {
      if (doc.id == exceptId) continue;
      if ((doc.data()['isDefault'] as bool?) == true) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }
}
