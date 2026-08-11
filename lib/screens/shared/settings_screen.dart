import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../auth/auth_gate.dart';
import 'personal_info_screen.dart';
import 'change_password_screen.dart';
import 'address_book_screen.dart';

class ShopeeSettingsPage extends StatefulWidget {
  const ShopeeSettingsPage({super.key});

  @override
  State<ShopeeSettingsPage> createState() => _ShopeeSettingsPageState();
}

class _ShopeeSettingsPageState extends State<ShopeeSettingsPage> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color shopeeRed = Color(0xFFF53D2D);
  static const Color bgGrey = Color(0xFFF2F3F5);

  // Các switch bật/tắt của trang Cài đặt
  bool _pushNotification = true;
  bool _emailNotification = false;
  bool _soundVibration = true;
  bool _faceIdLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionCard(
                    title: "Tài khoản",
                    children: [
                      ...MockData.settingsAccountItems.map(
                        (item) => _buildSimpleRow(
                          icon: item["icon"] as IconData,
                          label: item["label"] as String,
                          trailingValue: item["trailingValue"] as String?,
                          onTap: () => _handleAccountItemTap(item["label"] as String),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSectionCard(
                    title: "Đăng nhập & Bảo mật",
                    children: [
                      _buildSwitchRow(
                        icon: Icons.face_retouching_natural_outlined,
                        label: "Đăng nhập bằng Face ID / Vân tay",
                        value: _faceIdLogin,
                        onChanged: (v) => setState(() => _faceIdLogin = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSectionCard(
                    title: "Trung tâm thông báo",
                    children: [
                      _buildSwitchRow(
                        icon: Icons.notifications_none,
                        label: "Thông báo đẩy",
                        value: _pushNotification,
                        onChanged: (v) => setState(() => _pushNotification = v),
                      ),
                      _buildSwitchRow(
                        icon: Icons.mail_outline,
                        label: "Thông báo qua Email",
                        value: _emailNotification,
                        onChanged: (v) => setState(() => _emailNotification = v),
                      ),
                      _buildSwitchRow(
                        icon: Icons.volume_up_outlined,
                        label: "Âm thanh & Rung",
                        value: _soundVibration,
                        onChanged: (v) => setState(() => _soundVibration = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSectionCard(
                    title: "Quyền riêng tư & Bảo mật",
                    children: [
                      ...MockData.settingsPrivacyItems.map(
                        (item) => _buildSimpleRow(
                          icon: item["icon"] as IconData,
                          label: item["label"] as String,
                          danger: item["label"] == "Xoá tài khoản",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSectionCard(
                    title: "Thông tin thêm",
                    children: [
                      ...MockData.settingsMoreItems.map(
                        (item) => _buildSimpleRow(
                          icon: item["icon"] as IconData,
                          label: item["label"] as String,
                        ),
                      ),
                      _buildSimpleRow(
                        icon: Icons.system_update_alt_outlined,
                        label: "Phiên bản",
                        trailingValue: "3.14.2",
                        showChevron: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLogoutButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ĐIỀU HƯỚNG NHÓM "TÀI KHOẢN" =================
  void _handleAccountItemTap(String label) {
    switch (label) {
      case 'Thông tin cá nhân':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
        break;
      case 'Đổi mật khẩu':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
        break;
      case 'Địa chỉ':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
        break;
      default:
        // Các mục còn lại (Ngân hàng & Thẻ, Ngôn ngữ...) chưa làm, giữ hành vi cũ.
        break;
    }
  }

  // ================= TOP BAR =================
  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          const Text(
            "Cài đặt",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ================= SECTION CARD =================
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ================= HÀNG THÔNG THƯỜNG (điều hướng) =================
  Widget _buildSimpleRow({
    required IconData icon,
    required String label,
    String? trailingValue,
    bool showChevron = true,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 21, color: danger ? shopeeRed : Colors.black54),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: danger ? shopeeRed : Colors.black87,
                ),
              ),
            ),
            if (trailingValue != null) ...[
              Text(
                trailingValue,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 4),
            ],
            if (showChevron) const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= HÀNG CÓ SWITCH BẬT/TẮT =================
  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 21, color: Colors.black54),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          Switch(
            value: value,
            activeColor: shopeeOrange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ================= NÚT ĐĂNG XUẤT =================
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () => _confirmLogout(context),
          child: const Text(
            "Đăng Xuất",
            style: TextStyle(color: shopeeRed, fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Huỷ", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Xoá phiên đăng nhập đã lưu trên máy (Firebase Auth) — nếu
              // không gọi bước này, lần mở app sau AuthGate vẫn thấy còn
              // phiên cũ và tự động đăng nhập lại dù đã bấm "Đăng xuất".
              await AuthService.instance.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            child: const Text("Đăng xuất", style: TextStyle(color: shopeeRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
