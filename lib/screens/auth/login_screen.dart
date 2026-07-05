import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../buyer/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ShopeeLoginPage extends StatefulWidget {
  const ShopeeLoginPage({super.key});

  @override
  State<ShopeeLoginPage> createState() => _ShopeeLoginPageState();
}

class _ShopeeLoginPageState extends State<ShopeeLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color shopeeOrange = Color(0xFFEE4D2D);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 void _handleLogin() async {

  if (_formKey.currentState!.validate()) {

    try {

      setState(() => _isLoading = true);

      // Đăng nhập qua AuthService (dùng chung logic chuẩn hoá email/số điện
      // thoại với màn hình đăng ký) thay vì gọi FirebaseAuth trực tiếp ở đây.
      await AuthService.instance.login(
        emailOrPhone: _phoneController.text,
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ShopeeHomePage(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      setState(() => _isLoading = false);

      String message = "Đăng nhập thất bại";

      if (e.code == 'user-not-found') {
        message = "Tài khoản không tồn tại";
      }

      else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu";
      }

      else if (e.code == 'invalid-credential') {
        message = "Sai tài khoản hoặc mật khẩu";
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
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF6633),
                  Color(0xFFEE4D2D),
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      // Logo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: shopeeOrange,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Shopee",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Form
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(25),

                          child: Form(
                            key: _formKey,

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 25),

                                // Email
                                TextFormField(
                                  controller: _phoneController,

                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty) {
                                      return "Vui lòng nhập tài khoản";
                                    }
                                    return null;
                                  },

                                  decoration: InputDecoration(
                                    hintText:
                                        "Số điện thoại hoặc Email",

                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),

                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,

                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty) {
                                      return "Vui lòng nhập mật khẩu";
                                    }
                                    return null;
                                  },

                                  decoration: InputDecoration(
                                    hintText: "Mật khẩu",

                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                    ),

                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),

                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                                    ),

                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                  ),
                                ),

                                Align(
                                  alignment:
                                      Alignment.centerRight,

                                  child: TextButton(
                                    onPressed: () {},

                                    child: const Text(
                                      "Quên mật khẩu?",
                                      style: TextStyle(
                                        color: shopeeOrange,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,

                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleLogin,

                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          shopeeOrange,

                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                15),
                                      ),
                                    ),

                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color:
                                                Colors.white,
                                          )
                                        : const Text(
                                            "ĐĂNG NHẬP",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color:
                                            Colors.grey[300],
                                      ),
                                    ),

                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(
                                              horizontal:
                                                  10),

                                      child: Text("Hoặc"),
                                    ),

                                    Expanded(
                                      child: Divider(
                                        color:
                                            Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 25),

                                // Social Buttons
                                Row(
                                  children: [
                                    socialButton(
                                      label: "Facebook",
                                      color: const Color(
                                          0xFF1877F2),
                                      icon: Icons
                                          .facebook_rounded,
                                    ),

                                    const SizedBox(width: 12),

                                    socialButton(
                                      label: "Google",
                                      color: const Color(
                                          0xFFDB4437),
                                      icon: Icons
                                          .g_mobiledata_rounded,
                                    ),

                                    const SizedBox(width: 12),

                                    socialButton(
                                      label: "Apple",
                                      color: const Color(
                                          0xFF1A1A1A),
                                      icon:
                                          Icons.apple_rounded,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,

                                  children: [
                                    const Text(
                                      "Chưa có tài khoản?",
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ShopeeRegisterPage(),
                                          ),
                                        );
                                      },

                                      child: const Text(
                                        "Đăng ký ngay",

                                        style: TextStyle(
                                          color: shopeeOrange,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  // Social Button
  Widget socialButton({
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

            border: Border.all(
              color: const Color(0xFFEEEEEE),
              width: 1.5,
            ),

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
              Icon(
                icon,
                color: color,
                size: 22,
              ),

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