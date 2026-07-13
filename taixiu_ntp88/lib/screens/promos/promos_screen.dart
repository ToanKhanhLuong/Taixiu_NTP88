import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';

class PromosScreen extends StatefulWidget {
  const PromosScreen({super.key});

  @override
  State<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<PromosScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every 10 seconds to update check-in countdown
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getCheckInCountdown(UserModel user) {
    if (user.lastCheckInTime == null) return "";
    final now = DateTime.now();
    final nextCheckIn = user.lastCheckInTime!.add(const Duration(hours: 5));
    if (now.isAfter(nextCheckIn)) {
      return "";
    }
    final diff = nextCheckIn.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    if (hours > 0) {
      return "Điểm danh tiếp theo sau: $hours giờ $minutes phút";
    } else if (minutes > 0) {
      return "Điểm danh tiếp theo sau: $minutes phút $seconds giây";
    } else {
      return "Điểm danh tiếp theo sau: $seconds giây";
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    final List<Map<String, String>> promos = [
      {
        "title": "HOÀN TRẢ CƯỢC VIP KHÔNG GIỚI HẠN",
        "subtitle": "Nhận hoàn trả ngay sau mỗi lần đặt cược",
        "description": "Đặc quyền hoàn trả tức thời cho mỗi lượt đặt cược hợp lệ dựa trên cấp độ VIP của bạn: VIP 0: 0.2%, VIP 1: 0.5%, VIP 2: 1.0%, VIP 3: 1.5%, VIP 4: 2.0%, VIP 5: 2.5%, VIP 6: 3.0%. Không giới hạn hạn mức nhận.",
        "code": "VIPREBATE",
        "badge": "HOT"
      },
      {
        "title": "NHIỆM VỤ ĐIỂM DANH HÀNG GIỜ",
        "subtitle": "Nhận ngay 5,000 COIN miễn phí mỗi 5 giờ",
        "description": "Nhiệm vụ điểm danh định kỳ. Mỗi tài khoản sẽ được điểm danh một lần sau mỗi 5 giờ và nhận ngay 5,000 COIN thưởng miễn phí vào ví.",
        "code": "CHECKIN",
        "badge": "QUÀ"
      }
    ];

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          return Card(
            color: AppColors.cardDark,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header of promo card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderGrey.withOpacity(0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        promo["title"]!,
                        style: const TextStyle(
                          color: AppColors.goldAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          promo["badge"]!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
                // Body content of promo card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo["subtitle"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo["description"]!,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      
                      // Status and pending reward indicators
                      if (user != null) ...[
                        const SizedBox(height: 12),
                        _buildClaimStatus(user, promo["code"]!),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderGrey),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.vpn_key_outlined, color: AppColors.goldAccent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  "MÃ: ${promo["code"]}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: (promo["code"] == "CHECKIN" && user != null && _getCheckInCountdown(user).isNotEmpty)
                                ? null
                                : () => _handleClaim(context, authService, user, promo["code"]!),
                            style: TextButton.styleFrom(
                              foregroundColor: (promo["code"] == "CHECKIN" && user != null && _getCheckInCountdown(user).isNotEmpty)
                                  ? Colors.white30
                                  : AppColors.goldAccent,
                            ),
                            child: Row(
                              children: [
                                Text(_getClaimButtonText(user, promo["code"]!)),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: (promo["code"] == "CHECKIN" && user != null && _getCheckInCountdown(user).isNotEmpty)
                                      ? Colors.white30
                                      : AppColors.goldAccent,
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimStatus(UserModel user, String code) {
    double pendingAmount = 0.0;
    String statusText = "";
    bool isReady = false;
    
    if (code == "VIPREBATE") {
      pendingAmount = user.unclaimedRebate;
      statusText = pendingAmount > 0 
          ? "Tích lũy hoàn trả: ${pendingAmount.toStringAsFixed(2)} COIN" 
          : "Chưa có hoàn trả tích lũy";
      isReady = pendingAmount > 0;
    } else if (code == "CHECKIN") {
      final countdown = _getCheckInCountdown(user);
      if (countdown.isEmpty) {
        statusText = "Sẵn sàng điểm danh nhận 5,000 COIN!";
        isReady = true;
      } else {
        statusText = countdown;
        isReady = false;
      }
    }

    if (statusText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.withOpacity(0.15) : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReady ? Colors.green : Colors.white24,
          width: 0.5,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: isReady ? Colors.green : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getClaimButtonText(UserModel? user, String code) {
    if (user == null) return "NHẬN NGAY";
    
    if (code == "VIPREBATE") {
      return user.unclaimedRebate > 0 ? "NHẬN NGAY" : "XEM THÊM";
    } else if (code == "CHECKIN") {
      final countdown = _getCheckInCountdown(user);
      return countdown.isEmpty ? "ĐIỂM DANH" : "CHỜ 5H";
    }
    return "NHẬN NGAY";
  }

  Future<void> _handleClaim(BuildContext context, AuthService authService, UserModel? user, String code) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng đăng nhập để thực hiện nhận thưởng."),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (code == "VIPREBATE") {
      if (user.unclaimedRebate > 0) {
        try {
          final amt = user.unclaimedRebate;
          await authService.claimRebate();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Nhận hoàn trả cược VIP thành công +${amt.toStringAsFixed(2)} COIN!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: $e"), backgroundColor: AppColors.danger),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hãy tham gia đặt cược để tích lũy và nhận hoàn trả cược tức thời!"),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } else if (code == "CHECKIN") {
      final countdown = _getCheckInCountdown(user);
      if (countdown.isEmpty) {
        try {
          await authService.claimCheckIn();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Điểm danh thành công +5,000 COIN!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: $e"), backgroundColor: AppColors.danger),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Chưa đến giờ điểm danh! $countdown"),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }
}
