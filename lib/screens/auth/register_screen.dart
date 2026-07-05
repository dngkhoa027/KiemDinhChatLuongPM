import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

// ─── Màu chủ đạo (dùng chung với login) ──────────────────────────────────────
const Color shopeeOrange = Color(0xFFEE4D2D);
const Color shopeeOrangeLight = Color(0xFFFF6633);
const Color shopeeRed = Color(0xFFD0011B);

// ─── Entry point (xóa nếu dùng chung main.dart) ───────────────────────────────
void main() {
  runApp(const ShopeeRegisterApp());
}

class ShopeeRegisterApp extends StatelessWidget {
  const ShopeeRegisterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopee Register',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: shopeeOrange),
        useMaterial3: true,
      ),
      home: const ShopeeRegisterPage(),
    );
  }
}

// ─── Màn hình đăng ký ─────────────────────────────────────────────────────────
class ShopeeRegisterPage extends StatefulWidget {
  const ShopeeRegisterPage({super.key});

  @override
  State<ShopeeRegisterPage> createState() => _ShopeeRegisterPageState();
}

class _ShopeeRegisterPageState extends State<ShopeeRegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  // Thanh tiến trình độ mạnh mật khẩu
  int _passwordStrength = 0; // 0: trống, 1: yếu, 2: trung bình, 3: mạnh

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Kiểm tra độ mạnh mật khẩu
  void _checkPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.isEmpty) {
      strength = 0;
    } else if (password.length < 6) {
      strength = 1;
    } else {
      strength = 1;
      if (password.length >= 8) strength++;
      if (RegExp(r'[A-Z]').hasMatch(password) &&
          RegExp(r'[0-9]').hasMatch(password)) {
        strength++;
      }
    }
    setState(() => _passwordStrength = strength);
  }

  void _handleRegister() async {

  if (!_agreedToTerms) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vui lòng đồng ý điều khoản',
        ),
      ),
    );

    return;
  }

  if (_formKey.currentState!.validate()) {

    try {

      setState(() => _isLoading = true);

      // Đăng ký qua AuthService: vừa tạo tài khoản Firebase Auth, vừa tạo
      // document `users/{uid}` với role mặc định `buyer` -> đồng bộ với hệ
      // thống phân quyền dùng chung cho toàn app (xem services/auth_service.dart).
      await AuthService.instance.register(
        name: _nameController.text.trim(),
        emailOrPhone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký thành công 🎉',
          ),
        ),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {

      debugPrint(e.code);
      debugPrint(e.message);

      setState(() => _isLoading = false);

      String message = "Đăng ký thất bại";

      if (e.code == 'email-already-in-use') {
        message = "Email đã tồn tại";
      }

      else if (e.code == 'weak-password') {
        message = "Mật khẩu quá yếu";
      }

      else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (giống login)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF6633),
                  Color(0xFFEE4D2D),
                  Color(0xFFCC3311),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Decorative circles (giống login)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: ShopeeBagPainter(),
                size: const Size(60, 60),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Tạo tài khoản',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng ký để bắt đầu mua sắm ngay!',
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ─── Form card ────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              const Text(
                'Thông tin của bạn',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Điền đầy đủ để hoàn tất đăng ký',
                style: TextStyle(fontSize: 13.5, color: Colors.grey[500]),
              ),

              const SizedBox(height: 26),

              // ── Họ và tên ──
              _buildInputField(
                controller: _nameController,
                label: 'Họ và tên',
                hint: 'Nhập họ và tên của bạn',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.name,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (v.trim().length < 2) return 'Tên quá ngắn';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Số điện thoại / Email ──
              _buildInputField(
                controller: _phoneController,
                label: 'Số điện thoại / Email',
                hint: 'Nhập số điện thoại hoặc email',
                prefixIcon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại hoặc email';
                  }
                  final isEmail = v.contains('@') && v.contains('.');
                  final isPhone = RegExp(r'^[0-9]{9,11}$').hasMatch(v.trim());
                  if (!isEmail && !isPhone) {
                    return 'Email hoặc số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Mật khẩu ──
              _buildInputField(
                controller: _passwordController,
                label: 'Mật khẩu',
                hint: 'Tối thiểu 6 ký tự',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),

              // Thanh độ mạnh mật khẩu
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildPasswordStrengthBar(),
              ],

              const SizedBox(height: 16),

              // ── Xác nhận mật khẩu ──
              _buildInputField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                hint: 'Nhập lại mật khẩu',
                prefixIcon: Icons.lock_reset_outlined,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (v != _passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Checkbox đồng ý điều khoản ──
              _buildTermsCheckbox(),

              const SizedBox(height: 24),

              // ── Nút đăng ký ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shopeeOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'ĐĂNG KÝ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Divider ──
              Row(
                children: [
                  Expanded(
                      child:
                          Divider(color: Colors.grey[200], thickness: 1.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'hoặc đăng ký với',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                      child:
                          Divider(color: Colors.grey[200], thickness: 1.5)),
                ],
              ),

              const SizedBox(height: 20),

              // ── Social buttons ──
              Row(
                children: [
                  _buildSocialButton(
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    icon: Icons.facebook_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildSocialButton(
                    label: 'Google',
                    color: const Color(0xFFDB4437),
                    icon: Icons.g_mobiledata_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildSocialButton(
                    label: 'Apple',
                    color: const Color(0xFF1A1A1A),
                    icon: Icons.apple_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Link quay lại đăng nhập ──
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    children: [
                      const TextSpan(text: 'Đã có tài khoản? '),
                      TextSpan(
                        text: 'Đăng nhập',
                        style: const TextStyle(
                          color: shopeeOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Thanh độ mạnh mật khẩu ──────────────────────────────────────────────
  Widget _buildPasswordStrengthBar() {
    final labels = ['', 'Yếu', 'Trung bình', 'Mạnh'];
    final colors = [
      Colors.transparent,
      shopeeRed,
      Colors.orange,
      const Color(0xFF00C853),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < _passwordStrength
                      ? colors[_passwordStrength]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          _passwordStrength > 0
              ? 'Độ mạnh: ${labels[_passwordStrength]}'
              : '',
          style: TextStyle(
            fontSize: 11.5,
            color: colors[_passwordStrength],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Checkbox điều khoản ─────────────────────────────────────────────────
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: shopeeOrange,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              children: [
                const TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản dịch vụ',
                  style: const TextStyle(
                    color: shopeeOrange,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: shopeeOrange,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: const TextStyle(
                    color: shopeeOrange,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: shopeeOrange,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: ' của Shopee'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Input field (giống login) ────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[350], fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[400], size: 21),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: shopeeOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFD0011B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0011B), width: 2),
        ),
      ),
    );
  }

  // ─── Social button (giống login) ─────────────────────────────────────────
  Widget _buildSocialButton({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom painter logo Shopee (dùng chung) ─────────────────────────────────
class ShopeeBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = shopeeOrange
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final bagPath = Path();
    bagPath.moveTo(w * 0.12, h * 0.36);
    bagPath.lineTo(w * 0.05, h * 0.95);
    bagPath.quadraticBezierTo(w * 0.05, h * 1.0, w * 0.12, h * 1.0);
    bagPath.lineTo(w * 0.88, h * 1.0);
    bagPath.quadraticBezierTo(w * 0.95, h * 1.0, w * 0.95, h * 0.95);
    bagPath.lineTo(w * 0.88, h * 0.36);
    bagPath.close();
    canvas.drawPath(bagPath, paint);

    final handlePaint = Paint()
      ..color = shopeeOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    final handlePath = Path();
    handlePath.moveTo(w * 0.3, h * 0.36);
    handlePath.quadraticBezierTo(w * 0.3, h * 0.1, w * 0.5, h * 0.1);
    handlePath.quadraticBezierTo(w * 0.7, h * 0.1, w * 0.7, h * 0.36);
    canvas.drawPath(handlePath, handlePaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(w * 0.3, h * 0.65);
    smilePath.quadraticBezierTo(w * 0.5, h * 0.82, w * 0.7, h * 0.65);
    canvas.drawPath(smilePath, whitePaint);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.55), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.55), w * 0.055, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
  
