import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'friend_list_screen.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/repositories/private_chat_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Biến cấu hình thông báo (State cục bộ giả lập lưu trữ cài đặt)
  bool _soundEnabled = true;
  bool _promoEnabled = true;
  bool _balanceAlertsEnabled = false;

  IconData _getAvatarIcon(String url) {
    if (url == 'dice') return Icons.casino;
    if (url == 'crown') return Icons.workspace_premium;
    if (url == 'coin') return Icons.monetization_on;
    return Icons.auto_awesome; // Rồng Vàng mặc định
  }

  String _getAvatarName(String url) {
    if (url == 'dice') return 'Xúc Xắc Phú Quý';
    if (url == 'crown') return 'Vương Miện Hoàng Gia';
    if (url == 'coin') return 'Đồng Xu May Mắn';
    return 'Linh Thú Rồng Vàng';
  }

  // 1. POPUP: Xem Hồ Sơ Chi Tiết
  void _showViewProfile(BuildContext context, UserModel user) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final displayBalance = user.balance - authService.activeBetAmount;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "THÔNG TIN VIP PRESTIGE",
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow("Tên đăng nhập:", user.username),
              _buildDetailRow("Họ và tên:", user.fullName),
              _buildDetailRow("Email liên hệ:", user.email),
              _buildDetailRow("Số điện thoại:", user.phoneNumber),
              _buildDetailRow("Mã định danh ID:", user.idCode),
              _buildDetailRow("Cấp độ VIP:", "VIP ${user.vipLevel}"),
              _buildDetailRow("Tổng nạp:", "${user.totalDeposited.toStringAsFixed(0)} COIN"),
              _buildDetailRow("Ảnh đại diện:", _getAvatarName(user.avatarUrl)),
              _buildDetailRow("Số dư tài khoản:", "${displayBalance.toStringAsFixed(0)} COIN"),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("ĐÓNG", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 2. POPUP: Chỉnh sửa hồ sơ (Họ tên & Số điện thoại)
  void _showEditProfile(BuildContext context, AuthService authService, UserModel user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text(
            "CHỈNH SỬA HỒ SƠ",
            style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Họ và Tên",
                    labelStyle: TextStyle(color: AppColors.textGrey),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Họ tên không được để trống';
                    if (val.trim().length < 2) return 'Họ tên phải từ 2 ký tự trở lên';
                    if (val.trim().length > 50) return 'Họ tên tối đa 50 ký tự';
                    final RegExp nameRegex = RegExp(r"^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂÂÊÔƠưăâêôơ\s']+$");
                    if (!nameRegex.hasMatch(val.trim())) return 'Họ tên không được chứa số hoặc ký tự đặc biệt';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    labelStyle: TextStyle(color: AppColors.textGrey),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'SĐT không được để trống';
                    final RegExp phoneRegex = RegExp(r'^0[35789][0-9]{8}$');
                    if (!phoneRegex.hasMatch(val.trim())) {
                      return 'Số điện thoại không hợp lệ (10 chữ số, đầu 03/05/07/08/09)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop();
                
                await authService.updateProfile(
                  fullName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã lưu thông tin hồ sơ thay đổi thành công!"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldAccent, foregroundColor: Colors.black),
              child: const Text("LƯU"),
            ),
          ],
        );
      },
    );
  }

  // 3. POPUP: Thay Đổi Ảnh Đại Diện (Avatar Grid)
  void _showChangeAvatar(BuildContext context, AuthService authService, UserModel user) {
    final List<Map<String, dynamic>> avatars = [
      {"id": "dragon", "name": "Rồng Vàng", "icon": Icons.auto_awesome},
      {"id": "dice", "name": "Xúc Xắc Vàng", "icon": Icons.casino},
      {"id": "crown", "name": "Vương Miện", "icon": Icons.workspace_premium},
      {"id": "coin", "name": "Đồng Xu Vàng", "icon": Icons.monetization_on},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text(
            "CHỌN ẢNH ĐẠI DIỆN",
            style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final av = avatars[index];
                final isSelected = user.avatarUrl == av["id"];

                return GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await authService.updateAvatar(av["id"]!);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đã đổi ảnh đại diện sang '${av["name"]}' thành công!"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.goldAccent.withOpacity(0.1) : Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.goldAccent : AppColors.borderGrey,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          av["icon"] as IconData,
                          color: isSelected ? AppColors.goldAccent : Colors.white70,
                          size: 38,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          av["name"] as String,
                          style: TextStyle(
                            color: isSelected ? AppColors.goldAccent : AppColors.textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 4. POPUP: Đổi Mật Khẩu
  void _showChangePassword(BuildContext context, AuthService authService) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text(
                "ĐỔI MẬT KHẨU",
                style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Mật khẩu mới (tối thiểu 6 ký tự)",
                        labelStyle: TextStyle(color: AppColors.textGrey),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Mật khẩu không được để trống';
                        if (val.length < 6) return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                        if (val.length > 32) return 'Mật khẩu tối đa 32 ký tự';
                        if (val.contains(' ')) return 'Mật khẩu không được chứa khoảng trắng';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Xác nhận mật khẩu mới",
                        labelStyle: TextStyle(color: AppColors.textGrey),
                      ),
                      validator: (val) {
                        if (val != passwordController.text) return 'Mật khẩu xác nhận không trùng khớp';
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(color: AppColors.goldAccent),
                    ]
                  ],
                ),
              ),
              actions: [
                if (!isLoading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      setStateDialog(() {
                        isLoading = true;
                      });

                      try {
                        await authService.changePassword(passwordController.text);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Đổi mật khẩu thành công!"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setStateDialog(() {
                          isLoading = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Lỗi: ${e.toString().replaceAll('Exception: ', '')}"),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("ĐỒI"),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  // 5. POPUP: Cài Đặt Thông Báo
  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text(
                "CÀI ĐẶT THÔNG BÁO",
                style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Hiệu ứng âm thanh lắc", style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text("Kích hoạt âm thanh khi mở bát lắc xí ngầu", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                    activeColor: AppColors.goldAccent,
                    value: _soundEnabled,
                    onChanged: (val) {
                      setStateDialog(() {
                        _soundEnabled = val;
                      });
                      setState(() {
                        _soundEnabled = val;
                      });
                    },
                  ),
                  const Divider(color: AppColors.borderGrey),
                  SwitchListTile(
                    title: const Text("Nhận ưu đãi & Giftcode", style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text("Nhận tin nhắn khuyến mãi 100% nạp thẻ mới", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                    activeColor: AppColors.goldAccent,
                    value: _promoEnabled,
                    onChanged: (val) {
                      setStateDialog(() {
                        _promoEnabled = val;
                      });
                      setState(() {
                        _promoEnabled = val;
                      });
                    },
                  ),
                  const Divider(color: AppColors.borderGrey),
                  SwitchListTile(
                    title: const Text("Nhận báo số dư", style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text("Thông báo khi nạp rút hoặc cược thắng/thua", style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                    activeColor: AppColors.goldAccent,
                    value: _balanceAlertsEnabled,
                    onChanged: (val) {
                      setStateDialog(() {
                        _balanceAlertsEnabled = val;
                      });
                      setState(() {
                        _balanceAlertsEnabled = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Đã lưu cấu hình cài đặt thông báo!"),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("ĐỒNG Ý"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    void handleLogout() async {
      await authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: const Text(
          "MACAU PRESTIGE",
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "${((user?.balance ?? 0) - authService.activeBetAmount).toStringAsFixed(0)} COIN",
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header Card (Emblem & VIP info)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderGrey),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Golden circle and dynamic icon representation
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                          child: Center(
                            child: Icon(
                              _getAvatarIcon(user?.avatarUrl ?? ''),
                              color: AppColors.goldAccent,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                      
                      // VIP tag overlayed on bottom
                      Transform.translate(
                        offset: const Offset(0, 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.goldHighlight, width: 1.5),
                          ),
                          child: Text(
                            "VIP ${user?.vipLevel ?? 0}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Username
                  Text(
                    user?.username ?? "toanlk04",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // ID code
                  Text(
                    "ID: ${user?.idCode ?? '621099131'}",
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Total deposited coins
                  Text(
                    "Tổng nạp: ${user?.totalDeposited.toStringAsFixed(0) ?? '0'} COIN",
                    style: const TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings Options List
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: "Xem hồ sơ",
                    onTap: () {
                      if (user != null) _showViewProfile(context, user);
                    },
                  ),
                  const Divider(color: AppColors.borderGrey, height: 1),
                  _buildProfileOption(
                    icon: Icons.edit_outlined,
                    title: "Chỉnh sửa hồ sơ",
                    onTap: () {
                      if (user != null) _showEditProfile(context, authService, user);
                    },
                  ),
                  const Divider(color: AppColors.borderGrey, height: 1),
                  _buildProfileOption(
                    icon: Icons.camera_alt_outlined,
                    title: "Thay đổi ảnh đại diện",
                    onTap: () {
                      if (user != null) _showChangeAvatar(context, authService, user);
                    },
                  ),
                  const Divider(color: AppColors.borderGrey, height: 1),
                  _buildProfileOption(
                    icon: Icons.lock_open_outlined,
                    title: "Đổi mật khẩu",
                    onTap: () => _showChangePassword(context, authService),
                  ),
                  const Divider(color: AppColors.borderGrey, height: 1),
                  _buildProfileOption(
                    icon: Icons.notifications_none_outlined,
                    title: "Cài đặt thông báo",
                    onTap: () => _showNotificationSettings(context),
                  ),
                  const Divider(color: AppColors.borderGrey, height: 1),
                  StreamBuilder<bool>(
                    stream: FriendRepository().streamHasIncomingRequests(user?.uid ?? ''),
                    builder: (context, reqSnapshot) {
                      final hasRequest = reqSnapshot.data ?? false;
                      return StreamBuilder<bool>(
                        stream: PrivateChatRepository().streamHasUnreadMessages(user?.uid ?? ''),
                        builder: (context, chatSnapshot) {
                          final hasChat = chatSnapshot.data ?? false;
                          return _buildProfileOption(
                            icon: Icons.people_outline,
                            title: "Danh sách bạn bè",
                            showBadge: hasRequest || hasChat,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FriendListScreen()),
                              );
                            },
                          );
                        }
                      );
                    }
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Logout Button
            OutlinedButton.icon(
              onPressed: handleLogout,
              icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
              label: const Text(
                "ĐĂNG XUẤT",
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.cardDark,
                side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.goldAccent, size: 22),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textGrey,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}
