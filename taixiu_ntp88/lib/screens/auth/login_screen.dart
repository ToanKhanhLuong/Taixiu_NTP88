import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gold_dice_logo.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showSocialLoginMock(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardDark,
        content: Text(
          'Đang kết nối với $platform...',
          style: const TextStyle(color: AppColors.goldAccent),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  
                  // Dice Logo
                  const GoldDiceLogo(size: 70),
                  const SizedBox(height: 20),
                  
                  // Brand Title
                  const Text(
                    "MACAU PRESTIGE",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.goldAccent,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4.0,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Login / Register Tabs Switcher
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {}, // Already on login
                          child: Column(
                            children: [
                              const Text(
                                "ĐĂNG NHẬP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldAccent,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, anim1, anim2) => const RegisterScreen(),
                                transitionsBuilder: (context, anim, anim2, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 200),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              const Text(
                                "ĐĂNG KÝ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 3,
                                color: Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username / Email Input
                  CustomTextField(
                    controller: _usernameController,
                    labelText: "Tên đăng nhập hoặc Email",
                    hintText: "Nhập tên đăng nhập của bạn",
                    prefixIcon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập hoặc email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Mật khẩu",
                            style: TextStyle(
                              color: AppColors.textGreyLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showSocialLoginMock('Khôi phục mật khẩu');
                            },
                            child: const Text(
                              "Quên mật khẩu?",
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: "Nhập mật khẩu của bạn",
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Enter Button
                  CustomButton(
                    text: "VÀO SÒNG BÀI",
                    isLoading: authService.isLoading,
                    onPressed: _handleLogin,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.borderGrey, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "HOẶC TIẾP TỤC VỚI",
                          style: TextStyle(
                            color: AppColors.textGrey.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.borderGrey, thickness: 1)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Social Login Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSocialLoginMock('Facebook'),
                          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                          label: const Text(
                            "Facebook",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.cardDark,
                            side: const BorderSide(color: AppColors.borderGrey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSocialLoginMock('Google'),
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                            height: 18,
                            errorBuilder: (context, _, __) => const Icon(Icons.g_mobiledata, color: Colors.red),
                          ),
                          label: const Text(
                            "Google",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.cardDark,
                            side: const BorderSide(color: AppColors.borderGrey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (!authService.isFirebaseActive) ...[
                    const Text(
                      "Chế độ dùng thử",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
