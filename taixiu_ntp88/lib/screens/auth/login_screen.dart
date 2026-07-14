import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      String friendlyError = 'Đăng nhập thất bại. Vui lòng thử lại.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-credential':
          case 'user-not-found':
          case 'wrong-password':
            friendlyError = 'Tài khoản hoặc mật khẩu không chính xác.';
            break;
          case 'invalid-email':
            friendlyError = 'Địa chỉ email không hợp lệ.';
            break;
          case 'user-disabled':
            friendlyError = 'Tài khoản của bạn đã bị khóa.';
            break;
          case 'too-many-requests':
            friendlyError = 'Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau.';
            break;
          case 'network-request-failed':
            friendlyError = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại internet.';
            break;
          default:
            friendlyError = e.message ?? e.toString();
        }
      } else {
        friendlyError = e.toString().replaceAll('Exception: ', '');
      }
      setState(() {
        _errorMessage = friendlyError;
      });
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset, color: AppColors.goldAccent, size: 28),
                const SizedBox(width: 8),
                const Text(
                  "KHÔI PHỤC MẬT KHẨU",
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nhập địa chỉ email đăng ký tài khoản của bạn. Chúng tôi sẽ gửi một liên kết đổi mật khẩu của Google đến email này.",
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailController,
                    labelText: "Email đăng ký",
                    hintText: "Nhập email của bạn...",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(val)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isProcessing ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  setDialogState(() => isProcessing = true);
                  final email = emailController.text.trim();
                  
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.sendPasswordResetEmail(email);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Liên kết đặt lại mật khẩu đã gửi đến email $email!"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isProcessing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Lỗi gửi email: ${e.toString().replaceAll('Exception: ', '')}"),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
                child: isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("GỬI YÊU CẦU", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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
                    "NTP88",
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
                              _showForgotPasswordDialog();
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
