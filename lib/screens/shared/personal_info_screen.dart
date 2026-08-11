import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/avatar_utils.dart';

/// ============================================================
/// THÔNG TIN CÁ NHÂN
/// ------------------------------------------------------------
/// Xem & chỉnh sửa hồ sơ: họ tên, tên đăng nhập, SĐT, giới tính, ngày sinh,
/// hạng thành viên, ảnh đại diện (URL hoặc chọn/chụp ảnh từ thiết bị).
/// Dữ liệu đọc/ghi trực tiếp document `users/{uid}` qua AuthService — cùng
/// nguồn dữ liệu với tên hiển thị ở trang Profile.
///
/// LƯU Ý VỀ ẢNH ĐẠI DIỆN:
/// Ảnh chọn từ thiết bị được nén nhỏ (tối đa 480px, chất lượng 70%) rồi
/// mã hoá base64 lưu thẳng vào field `avatarUrl` (dạng
/// "data:image/jpeg;base64,..."), thay vì upload lên Firebase Storage.
/// Cách này giúp không cần thêm cấu hình Storage cho project, phù hợp
/// cho ảnh đại diện nhỏ. Nếu dán URL ảnh có sẵn (http/https) thì lưu
/// thẳng URL đó và hiển thị qua Image.network như bình thường.
/// ============================================================
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color deepOrange = Color(0xFFFF6E40);
  static const Color bgGrey = Color(0xFFF7F7F8);
  static const Color ink = Color(0xFF1D1D1F);

  static const List<Map<String, dynamic>> _tiers = [
    {'name': 'Thành viên', 'color': Color(0xFF8E8E93), 'icon': Icons.card_membership_outlined},
    {'name': 'Bạc', 'color': Color(0xFF7E8C9A), 'icon': Icons.workspace_premium_outlined},
    {'name': 'Vàng', 'color': Color(0xFFDBA400), 'icon': Icons.workspace_premium},
    {'name': 'Bạch Kim', 'color': Color(0xFF2CA0A4), 'icon': Icons.diamond_outlined},
    {'name': 'Kim Cương', 'color': Color(0xFF7B5EEA), 'icon': Icons.diamond},
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  AppUser? _user;
  String? _gender;
  String? _birthday;
  String? _avatarUrl;
  late String _membershipTier = _tiers.first['name'] as String;

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _uploadingAvatar = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.instance.fetchCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameController.text = user?.name ?? '';
      _usernameController.text = user?.username ?? '';
      _phoneController.text = user?.phone ?? '';
      _gender = user?.gender;
      _birthday = user?.birthday;
      _avatarUrl = user?.avatarUrl;
      _membershipTier = user?.membershipTier ?? _tiers.first['name'] as String;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  // ================= NGÀY SINH =================
  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_birthday != null) {
      final parts = _birthday!.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) initial = DateTime(y, m, d);
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: shopeeOrange)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthday =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      _markDirty();
    }
  }

  // ================= ẢNH ĐẠI DIỆN =================
  ImageProvider? get _avatarImageProvider => resolveAvatarImage(_avatarUrl);

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Đổi ảnh đại diện', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: ink)),
              ),
              const SizedBox(height: 14),
              _avatarOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Chọn ảnh từ thư viện',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _avatarOptionTile(
                icon: Icons.photo_camera_outlined,
                label: 'Chụp ảnh mới',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              _avatarOptionTile(
                icon: Icons.link_rounded,
                label: 'Dùng liên kết ảnh (URL)',
                onTap: () {
                  Navigator.pop(ctx);
                  _promptAvatarUrl();
                },
              ),
              if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                _avatarOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Gỡ ảnh đại diện',
                  danger: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _avatarUrl = null);
                    _markDirty();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? Colors.redAccent : ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? Colors.redAccent : Colors.grey.shade600),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 70,
      );
      if (file == null) return; // người dùng huỷ chọn ảnh
      setState(() => _uploadingAvatar = true);
      final Uint8List bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      if (!mounted) return;
      setState(() {
        _avatarUrl = 'data:image/jpeg;base64,$base64Str';
        _uploadingAvatar = false;
      });
      _markDirty();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lấy ảnh: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _promptAvatarUrl() async {
    final ctrl = TextEditingController(text: (_avatarUrl?.startsWith('http') == true) ? _avatarUrl : '');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Liên kết ảnh đại diện', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: shopeeOrange, foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Dùng ảnh này'),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liên kết ảnh không hợp lệ, cần bắt đầu bằng http:// hoặc https://'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _avatarUrl = url);
    _markDirty();
  }

  // ================= LƯU =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      setState(() => _usernameError = null);
      final available = await AuthService.instance.isUsernameAvailable(username);
      if (!available) {
        setState(() => _usernameError = 'Tên đăng nhập này đã có người dùng');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        gender: _gender,
        birthday: _birthday,
        avatarUrl: _avatarUrl ?? '',
        phone: _phoneController.text.trim(),
        username: username,
        membershipTier: _membershipTier,
      );
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thông tin cá nhân'),
          backgroundColor: Color(0xFF2E9E5B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: shopeeOrange))
          : Form(
              key: _formKey,
              onChanged: _markDirty,
              child: CustomScrollView(
                slivers: [
                  _buildHeaderBar(context),
                  SliverToBoxAdapter(child: _buildAvatarSection()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildMembershipCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _buildFormCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _buildAccountMetaCard(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
      bottomNavigationBar: _loading ? null : _buildSaveBar(),
    );
  }

  // ================= HEADER (gradient cam, bo góc dưới) =================
  Widget _buildHeaderBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 78,
      backgroundColor: shopeeOrange,
      automaticallyImplyLeading: false,
      flexibleSpace: const FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [deepOrange, shopeeOrange]),
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: const Text(
        'Thông tin cá nhân',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
      ),
      centerTitle: false,
    );
  }

  // ================= AVATAR =================
  Widget _buildAvatarSection() {
    final imageProvider = _avatarImageProvider;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 22, bottom: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shopeeOrange, Color(0xFFF7F7F8)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _showAvatarOptions,
            child: Stack(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: CircleAvatar(
                    radius: 43,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: imageProvider,
                    child: (imageProvider == null)
                        ? Text(
                            _initials(_nameController.text.isEmpty ? 'S' : _nameController.text),
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: shopeeOrange),
                          )
                        : null,
                  ),
                ),
                if (_uploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: shopeeOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _user?.email.isNotEmpty == true ? _user!.email : '—',
            style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  // ================= HẠNG THÀNH VIÊN =================
  Widget _buildMembershipCard() {
    final current = _tiers.firstWhere((t) => t['name'] == _membershipTier, orElse: () => _tiers.first);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('HẠNG THÀNH VIÊN'),
              const Spacer(),
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hạng được tính theo điểm tích luỹ — bản demo cho phép bạn tự chọn để xem giao diện từng hạng.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (current['color'] as Color).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (current['color'] as Color).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(current['icon'] as IconData, size: 20, color: current['color'] as Color),
                const SizedBox(width: 10),
                Text(
                  'Hạng ${current['name']}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: current['color'] as Color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tiers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final tier = _tiers[index];
                final selected = tier['name'] == _membershipTier;
                final color = tier['color'] as Color;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _membershipTier = tier['name'] as String);
                    _markDirty();
                  },
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? color : Colors.grey.shade200, width: selected ? 1.4 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tier['icon'] as IconData, size: 20, color: selected ? color : Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text(
                          tier['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? color : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= FORM CARD =================
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('HỒ SƠ'),
          const SizedBox(height: 14),
          _fieldLabel('Họ và tên'),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'Nhập họ và tên'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 18),
          _fieldLabel('Tên đăng nhập'),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'vd: 23.thnhn').copyWith(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 6),
                child: Icon(Icons.alternate_email_rounded, size: 18, color: Colors.grey),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              errorText: _usernameError,
            ),
            onChanged: (_) {
              if (_usernameError != null) setState(() => _usernameError = null);
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // cho phép để trống
              final value = v.trim();
              if (value.length < 4 || value.length > 20) return 'Tên đăng nhập cần 4-20 ký tự';
              if (!RegExp(r'^[a-z0-9._]+$').hasMatch(value)) {
                return 'Chỉ dùng chữ thường, số, dấu chấm và gạch dưới';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Dùng để hiển thị công khai, chỉ gồm chữ thường, số, "." hoặc "_"',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 18),
          _fieldLabel('Số điện thoại'),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w500),
            decoration: _inputDecoration(hint: 'Nhập số điện thoại liên hệ'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // cho phép để trống
              if (!RegExp(r'^[0-9]{9,11}$').hasMatch(v.trim())) return 'Số điện thoại không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _fieldLabel('Giới tính'),
          _buildGenderPicker(),
          const SizedBox(height: 18),
          _fieldLabel('Ngày sinh'),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _pickBirthday,
            child: InputDecorator(
              decoration: _inputDecoration(hint: 'dd/mm/yyyy').copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
              ),
              child: Text(
                _birthday ?? 'Chưa cập nhật',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _birthday == null ? Colors.grey.shade400 : ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildGenderPicker() {
    final options = const ['Nam', 'Nữ', 'Khác'];
    return Row(
      children: options.map((g) {
        final selected = _gender == g;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: g == options.last ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() => _gender = g);
                _markDirty();
              },
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? shopeeOrange.withValues(alpha: 0.08) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? shopeeOrange : Colors.grey.shade300),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? shopeeOrange : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= META CARD (email, vai trò) =================
  Widget _buildAccountMetaCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TÀI KHOẢN'),
          const SizedBox(height: 12),
          _metaRow(Icons.alternate_email_rounded, 'Email / SĐT đăng nhập', _user?.email ?? '—'),
          Divider(height: 22, color: Colors.grey.shade100),
          _metaRow(
            Icons.verified_user_outlined,
            'Loại tài khoản',
            _user?.isSeller == true ? 'Người bán' : 'Người mua',
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: ink),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 0.6,
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      );

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: shopeeOrange, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  // ================= SAVE BAR (sticky đáy) =================
  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_dirty && !_saving) ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: shopeeOrange,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Lưu thay đổi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
