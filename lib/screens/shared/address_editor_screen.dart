import 'package:flutter/material.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import 'location_picker_sheet.dart';

/// Form thêm mới hoặc chỉnh sửa 1 địa chỉ. Nếu [existing] != null -> chế độ
/// sửa (điền sẵn dữ liệu cũ + có nút Xoá); ngược lại là chế độ thêm mới.
///
/// Thứ tự nhập liệu đi theo đúng flow "Địa chỉ mới" của Shopee thật:
///   1. Họ và tên + Số điện thoại người nhận
///   2. Chọn Tỉnh/Thành phố -> Quận/Huyện -> Phường/Xã (bottom sheet 3 bước)
///   3. Địa chỉ cụ thể (số nhà, tên đường...)
///   4. Loại địa chỉ (Nhà riêng / Văn phòng / Khác)
///   5. Đặt làm địa chỉ mặc định
class AddressEditorScreen extends StatefulWidget {
  final String uid;
  final Address? existing;

  const AddressEditorScreen({super.key, required this.uid, this.existing});

  @override
  State<AddressEditorScreen> createState() => _AddressEditorScreenState();
}

class _AddressEditorScreenState extends State<AddressEditorScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color deepOrange = Color(0xFFFF6E40);
  static const Color bgGrey = Color(0xFFF7F7F8);
  static const Color ink = Color(0xFF1D1D1F);

  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.fullName ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  late final _detailCtrl = TextEditingController(text: widget.existing?.detail ?? '');

  String? _province;
  String? _district;
  String? _ward;
  bool _locationTouched = false; // đã bấm chọn địa chỉ chưa (để hiện lỗi validate đúng lúc)

  static const _labels = ['Nhà riêng', 'Văn phòng', 'Khác'];
  late String _label = widget.existing?.label ?? _labels.first;
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _province = widget.existing?.province;
    _district = widget.existing?.district;
    _ward = widget.existing?.ward;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await LocationPickerSheet.show(
      context,
      initialProvince: _province,
      initialDistrict: _district,
    );
    if (result == null) return;
    setState(() {
      _province = result.province;
      _district = result.district;
      _ward = result.ward;
      _locationTouched = true;
    });
  }

  Future<void> _save() async {
    setState(() => _locationTouched = true);
    final formOk = _formKey.currentState!.validate();
    final locationOk = _province != null && _district != null && _ward != null;
    if (!formOk || !locationOk) return;

    setState(() => _saving = true);
    try {
      final address = Address(
        id: widget.existing?.id ?? '',
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        detail: _detailCtrl.text.trim(),
        ward: _ward!,
        district: _district!,
        province: _province!,
        label: _label,
        isDefault: _isDefault,
      );
      if (_isEditing) {
        await AddressService.instance.updateAddress(uid: widget.uid, address: address);
      } else {
        await AddressService.instance.addAddress(
          uid: widget.uid,
          address: address,
          setAsDefault: _isDefault,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu địa chỉ: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xoá địa chỉ này?'),
        content: const Text('Bạn sẽ không thể hoàn tác sau khi xoá.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await AddressService.instance.deleteAddress(uid: widget.uid, addressId: widget.existing!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xoá: $e'), behavior: SnackBarBehavior.floating),
      );
      setState(() => _deleting = false);
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
            title: Text(
              _isEditing ? 'Sửa địa chỉ' : 'Địa chỉ mới',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
            ),
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [deepOrange, shopeeOrange]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BƯỚC 1: Người nhận (tên + SĐT) — giống Shopee luôn hỏi trước tiên
                    _buildCard(
                      title: 'NGƯỜI NHẬN',
                      children: [
                        _labeledField('Họ và tên', _nameCtrl, validator: _required('họ tên')),
                        const SizedBox(height: 14),
                        _labeledField(
                          'Số điện thoại',
                          _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                            if (!RegExp(r'^[0-9]{9,11}$').hasMatch(v.trim())) return 'Số điện thoại không hợp lệ';
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // BƯỚC 2: Chọn Tỉnh/Thành - Phường/Xã rồi mới tới địa chỉ cụ thể
                    _buildCard(
                      title: 'ĐỊA CHỈ',
                      children: [
                        _buildLocationPickerField(),
                        const SizedBox(height: 14),
                        _labeledField('Địa chỉ cụ thể (số nhà, tên đường...)', _detailCtrl, validator: _required('địa chỉ cụ thể')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // BƯỚC 3: Loại địa chỉ
                    _buildCard(
                      title: 'LOẠI ĐỊA CHỈ',
                      children: [_buildLabelPicker()],
                    ),
                    const SizedBox(height: 14),
                    // BƯỚC 4: Đặt mặc định
                    _buildDefaultSwitchCard(),
                    if (_isEditing) ...[
                      const SizedBox(height: 20),
                      _buildDeleteButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  String? Function(String?) _required(String field) {
    return (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $field' : null;
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.6)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14.5, color: ink, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: shopeeOrange, width: 1.4)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Colors.redAccent)),
          ),
        ),
      ],
    );
  }

  /// Ô chọn "Tỉnh/Thành phố, Quận/Huyện, Phường/Xã" — bấm vào mở bottom
  /// sheet 3 bước, đúng như hành vi chọn địa chỉ của Shopee thật (không gõ tay).
  Widget _buildLocationPickerField() {
    final hasValue = _province != null && _district != null && _ward != null;
    final showError = _locationTouched && !hasValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tỉnh/Thành phố, Quận/Huyện, Phường/Xã', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _pickLocation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: showError ? Colors.redAccent : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? '$_ward, $_district, $_province' : 'Chọn Tỉnh/Thành phố, Quận/Huyện, Phường/Xã',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                      color: hasValue ? ink : Colors.grey.shade400,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('Vui lòng chọn Tỉnh/Thành phố, Quận/Huyện và Phường/Xã', style: TextStyle(fontSize: 11.5, color: Colors.redAccent.shade200)),
          ),
      ],
    );
  }

  Widget _buildLabelPicker() {
    final icons = {'Nhà riêng': Icons.home_outlined, 'Văn phòng': Icons.business_outlined, 'Khác': Icons.place_outlined};
    return Row(
      children: _labels.map((l) {
        final selected = _label == l;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: l == _labels.last ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _label = l),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? shopeeOrange.withValues(alpha: 0.08) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? shopeeOrange : Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(icons[l], size: 18, color: selected ? shopeeOrange : Colors.grey.shade500),
                    const SizedBox(height: 4),
                    Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? shopeeOrange : Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDefaultSwitchCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
                Text('Áp dụng cho lần đặt hàng tiếp theo', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(value: _isDefault, activeColor: shopeeOrange, onChanged: (v) => setState(() => _isDefault = v)),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _deleting ? null : _confirmDelete,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: _deleting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
            : const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
        label: const Text('Xoá địa chỉ này', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))]),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: shopeeOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(_isEditing ? 'Cập nhật địa chỉ' : 'Hoàn thành', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
