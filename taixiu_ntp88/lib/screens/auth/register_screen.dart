import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gold_dice_logo.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Bạn phải đồng ý với Điều khoản & Điều kiện để tiếp tục';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final success = await authService.register(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      String friendlyError = 'Đăng ký thất bại. Vui lòng thử lại.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            friendlyError = 'Địa chỉ email này đã được đăng ký cho tài khoản khác.';
            break;
          case 'invalid-email':
            friendlyError = 'Địa chỉ email không hợp lệ.';
            break;
          case 'operation-not-allowed':
            friendlyError = 'Đăng ký tài khoản hiện đang tạm khóa.';
            break;
          case 'weak-password':
            friendlyError = 'Mật khẩu quá yếu. Vui lòng sử dụng tối thiểu 6 ký tự.';
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
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Login / Register Tabs Switcher
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, anim1, anim2) => const LoginScreen(),
                                transitionsBuilder: (context, anim, anim2, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 200),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              const Text(
                                "ĐĂNG NHẬP",
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () {}, // Already on register
                          child: Column(
                            children: [
                              const Text(
                                "ĐĂNG KÝ",
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

                  // Full Name Input
                  CustomTextField(
                    controller: _fullNameController,
                    labelText: "Họ và Tên",
                    hintText: "Nhập họ và tên của bạn",
                    prefixIcon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      if (val.trim().length < 2) return 'Họ tên phải từ 2 ký tự trở lên';
                      if (val.trim().length > 50) return 'Họ tên tối đa 50 ký tự';
                      final RegExp nameRegex = RegExp(r"^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂÂÊÔƠưăâêôơ\s']+$");
                      if (!nameRegex.hasMatch(val.trim())) return 'Họ tên không được chứa số hoặc ký tự đặc biệt';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Username Input
                  CustomTextField(
                    controller: _usernameController,
                    labelText: "Tên đăng nhập",
                    hintText: "Chọn tên đăng nhập duy nhất",
                    prefixIcon: Icons.alternate_email_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      if (val.trim().length < 4) {
                        return 'Tên đăng nhập phải dài ít nhất 4 ký tự';
                      }
                      if (val.trim().length > 20) {
                        return 'Tên đăng nhập tối đa 20 ký tự';
                      }
                      final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');
                      if (!usernameRegex.hasMatch(val.trim())) {
                        return 'Chỉ chấp nhận chữ cái, số, dấu chấm (.) và gạch dưới (_)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Email Input
                  CustomTextField(
                    controller: _emailController,
                    labelText: "Email",
                    hintText: "Nhập địa chỉ email của bạn",
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return 'Vui lòng nhập địa chỉ email hợp lệ';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Phone Number Input
                  CustomTextField(
                    controller: _phoneController,
                    labelText: "Số điện thoại",
                    hintText: "Nhập số điện thoại của bạn",
                    prefixIcon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      final RegExp phoneRegex = RegExp(r'^0[35789][0-9]{8}$');
                      if (!phoneRegex.hasMatch(val.trim())) {
                        return 'Số điện thoại không hợp lệ (10 chữ số, đầu 03/05/07/08/09)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Input
                  CustomTextField(
                    controller: _passwordController,
                    labelText: "Mật khẩu",
                    hintText: "Tạo mật khẩu đăng nhập",
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
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
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (val.length < 6) {
                        return 'Mật khẩu phải dài ít nhất 6 ký tự';
                      }
                      if (val.length > 32) return 'Mật khẩu tối đa 32 ký tự';
                      if (val.contains(' ')) return 'Mật khẩu không được chứa khoảng trắng';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Confirm Password Input
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: "Xác nhận mật khẩu",
                    hintText: "Nhập lại mật khẩu của bạn",
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (val != _passwordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // Terms & Conditions Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          activeColor: AppColors.goldAccent,
                          checkColor: Colors.black,
                          side: const BorderSide(color: AppColors.textGrey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _agreeToTerms = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Tôi đã đọc và đồng ý với Điều khoản & Điều kiện và Chính sách bảo mật.",
                          style: TextStyle(
                            color: AppColors.textGreyLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Button
                  CustomButton(
                    text: "ĐĂNG KÝ NGAY",
                    isLoading: authService.isLoading,
                    onPressed: _handleRegister,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Already have account Link
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Đã có tài khoản? ",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Đăng nhập",
                            style: TextStyle(
                              color: AppColors.goldAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
