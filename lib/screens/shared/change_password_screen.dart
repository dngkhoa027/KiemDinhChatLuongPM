import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

/// ============================================================
/// ĐỔI MẬT KHẨU
/// ------------------------------------------------------------
/// Yêu cầu nhập đúng mật khẩu hiện tại (Firebase bắt buộc re-auth trước
/// khi update password), rồi mật khẩu mới + xác nhận. Có thước đo độ
/// mạnh mật khẩu trực quan để cảm giác chuyên nghiệp hơn 1 form thô.
/// ============================================================
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color shopeeOrange = Color(0xFFEE4D2D);
  static const Color deepOrange = Color(0xFFFF6E40);
  static const Color bgGrey = Color(0xFFF7F7F8);
  static const Color ink = Color(0xFF1D1D1F);

  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---- Đánh giá độ mạnh mật khẩu (0-4) chỉ để hiển thị UI, không chặn submit ----
  int get _strength {
    final v = _newCtrl.text;
    if (v.isEmpty) return 0;
    int score = 0;
    if (v.length >= 6) score++;
    if (v.length >= 10) score++;
    if (RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[a-zA-Z]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score++;
    return score.clamp(0, 4);
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1:
        return 'Yếu';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Khá mạnh';
      default:
        return 'Mạnh';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1:
        return const Color(0xFFE64545);
      case 2:
        return const Color(0xFFF5A623);
      case 3:
        return const Color(0xFF3FA9F5);
      default:
        return const Color(0xFF2E9E5B);
    }
  }

  bool get _hasMinLength => _newCtrl.text.length >= 6;
  bool get _hasLetterAndNumber =>
      RegExp(r'[0-9]').hasMatch(_newCtrl.text) && RegExp(r'[a-zA-Z]').hasMatch(_newCtrl.text);
  bool get _isDifferentFromCurrent =>
      _newCtrl.text.isNotEmpty && _newCtrl.text != _currentCtrl.text;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      _showResultDialog(
        success: true,
        message: 'Mật khẩu của bạn đã được cập nhật thành công.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showResultDialog(success: false, message: _mapFirebaseError(e));
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(success: false, message: 'Có lỗi xảy ra, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu hiện tại không đúng.';
      case 'weak-password':
        return 'Mật khẩu mới quá yếu, vui lòng chọn mật khẩu khác.';
      case 'requires-recent-login':
        return 'Phiên đăng nhập đã cũ, vui lòng đăng xuất rồi đăng nhập lại trước khi đổi mật khẩu.';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần, vui lòng thử lại sau ít phút.';
      default:
        return 'Không thể đổi mật khẩu (${e.code}).';
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: (success ? const Color(0xFF2E9E5B) : Colors.redAccent).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            success ? Icons.check_rounded : Icons.error_outline_rounded,
            color: success ? const Color(0xFF2E9E5B) : Colors.redAccent,
            size: 30,
          ),
        ),
        title: Text(
          success ? 'Thành công' : 'Không thành công',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: shopeeOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (success) Navigator.pop(context);
              },
              child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
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
            title: const Text(
              'Đổi mật khẩu',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
            ),
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [deepOrange, shopeeOrange],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroIcon(),
                    const SizedBox(height: 20),
                    _buildFieldCard(),
                    const SizedBox(height: 16),
                    _buildRequirementsCard(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [deepOrange, shopeeOrange]),
              boxShadow: [BoxShadow(color: shopeeOrange.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bảo vệ tài khoản của bạn',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Nên đặt mật khẩu mà bạn chưa từng dùng ở nơi khác',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Mật khẩu hiện tại'),
          _passwordField(
            controller: _currentCtrl,
            obscure: !_showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 18),
          _fieldLabel('Mật khẩu mới'),
          _passwordField(
            controller: _newCtrl,
            obscure: !_showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
              if (v.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự';
              if (v == _currentCtrl.text) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
              return null;
            },
          ),
          if (_newCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildStrengthMeter(),
          ],
          const SizedBox(height: 18),
          _fieldLabel('Xác nhận mật khẩu mới'),
          _passwordField(
            controller: _confirmCtrl,
            obscure: !_showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập lại mật khẩu mới';
              if (v != _newCtrl.text) return 'Mật khẩu xác nhận không khớp';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthMeter() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              final filled = i < _strength;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? _strengthColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _strengthLabel,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _strengthColor),
        ),
      ],
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YÊU CẦU MẬT KHẨU',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          _requirementRow('Tối thiểu 6 ký tự', _hasMinLength),
          const SizedBox(height: 8),
          _requirementRow('Kết hợp chữ và số', _hasLetterAndNumber),
          const SizedBox(height: 8),
          _requirementRow('Khác với mật khẩu hiện tại', _isDifferentFromCurrent),
        ],
      ),
    );
  }

  Widget _requirementRow(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: met ? const Color(0xFF2E9E5B) : Colors.grey.shade300,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12.5, color: met ? ink : Colors.grey.shade500, fontWeight: met ? FontWeight.w600 : FontWeight.normal),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w500),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: Colors.grey),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: shopeeOrange, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      );

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: shopeeOrange,
          disabledBackgroundColor: shopeeOrange.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _saving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : const Text('Cập nhật mật khẩu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
