import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import 'address_editor_screen.dart';

/// ============================================================
/// SỔ ĐỊA CHỈ
/// ------------------------------------------------------------
/// Danh sách địa chỉ giao hàng của user (Firestore
/// `users/{uid}/addresses`), có thể thêm/sửa/xoá và chọn địa chỉ mặc định.
/// ============================================================
class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color deepOrange = Color(0xFFFF6E40);
  static const Color bgGrey = Color(0xFFF7F7F8);
  static const Color ink = Color(0xFF1D1D1F);

  String? _uid;
  List<Address> _addresses = [];
  bool _loading = true;
  String? _busyId; // id địa chỉ đang xử lý (đặt mặc định) để show loading riêng dòng đó

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _load();
  }

  Future<void> _load() async {
    if (_uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final list = await AddressService.instance.fetchAddresses(_uid!);
    if (!mounted) return;
    setState(() {
      _addresses = list;
      _loading = false;
    });
  }

  Future<void> _openEditor({Address? existing}) async {
    if (_uid == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddressEditorScreen(uid: _uid!, existing: existing)),
    );
    if (changed == true) _load();
  }

  Future<void> _setDefault(Address address) async {
    if (_uid == null || address.isDefault) return;
    setState(() => _busyId = address.id);
    try {
      await AddressService.instance.setDefaultAddress(uid: _uid!, addressId: address.id);
      await _load();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: shopeeOrange,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            title: const Text('Địa chỉ của tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [deepOrange, shopeeOrange]),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: shopeeOrange)))
          else if (_addresses.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAddressCard(_addresses[index]),
                  ),
                  childCount: _addresses.length,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: (_loading) ? null : _buildAddBar(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: shopeeOrange.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.location_off_outlined, size: 44, color: shopeeOrange),
          ),
          const SizedBox(height: 18),
          const Text('Chưa có địa chỉ nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink)),
          const SizedBox(height: 6),
          Text(
            'Thêm địa chỉ nhận hàng để đặt mua nhanh hơn ở những lần sau',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    final busy = _busyId == address.id;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: address.isDefault ? shopeeOrange.withValues(alpha: 0.4) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: shopeeOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
                child: Icon(_labelIcon(address.label), size: 16, color: shopeeOrange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('|', style: TextStyle(color: Colors.grey.shade300)),
                        const SizedBox(width: 8),
                        Text(address.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(address.label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 19, color: Colors.grey.shade500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (v) {
                  if (v == 'edit') _openEditor(existing: address);
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa địa chỉ')),
                ],
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.shade100),
          Row(
            children: [
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: shopeeOrange),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Mặc định', style: TextStyle(fontSize: 11, color: shopeeOrange, fontWeight: FontWeight.w700)),
                )
              else
                InkWell(
                  onTap: busy ? null : () => _setDefault(address),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      busy
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(strokeWidth: 2, color: shopeeOrange),
                            )
                          : Icon(Icons.radio_button_unchecked, size: 15, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text('Đặt làm mặc định', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Spacer(),
              InkWell(
                onTap: () => _openEditor(existing: address),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text('Sửa', style: TextStyle(fontSize: 12.5, color: shopeeOrange, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _labelIcon(String label) {
    switch (label) {
      case 'Văn phòng':
        return Icons.business_outlined;
      case 'Khác':
        return Icons.place_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  Widget _buildAddBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))]),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _openEditor(),
            style: ElevatedButton.styleFrom(
              backgroundColor: shopeeOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Thêm địa chỉ mới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
