import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';

class PromosScreen extends StatelessWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    final List<Map<String, String>> promos = [
      {
        "title": "NHIỆM VỤ NẠP ĐẦU TẶNG 40 COIN",
        "subtitle": "Nạp từ 50 COIN nhận thêm ngay 40 COIN",
        "description": "Nhiệm vụ chào mừng thành viên mới. Thực hiện giao dịch nạp tiền lần đầu tiên từ 50 COIN trở lên để nhận thêm 40 COIN thưởng nhiệm vụ miễn phí vào ví.",
        "code": "WELCOME40",
        "badge": "MỚI"
      },
      {
        "title": "HOÀN TRẢ CƯỢC VIP KHÔNG GIỚI HẠN",
        "subtitle": "Nhận hoàn trả ngay sau mỗi lần đặt cược",
        "description": "Đặc quyền hoàn trả tức thời cho mỗi lượt đặt cược hợp lệ dựa trên cấp độ VIP của bạn: VIP 0: 0.2%, VIP 1: 0.5%, VIP 2: 1.0%, VIP 3: 1.5%, VIP 4: 2.0%, VIP 5: 2.5%, VIP 6: 3.0%. Không giới hạn hạn mức nhận.",
        "code": "VIPREBATE",
        "badge": "HOT"
      },
      {
        "title": "ĐẶC QUYỀN THĂNG CẤP VIP",
        "subtitle": "Thưởng lên tới 1,600 COIN khi đạt VIP 6",
        "description": "Mỗi khi thăng cấp VIP mới, nhận thưởng thăng cấp ngay lập tức vào ví: VIP 1 thưởng 50 COIN. Từ VIP 2 trở đi, phần thưởng nhân đôi (VIP 2: 100, VIP 3: 200, VIP 4: 400, VIP 5: 800, VIP 6: 1,600 COIN).",
        "code": "VIPREWARD",
        "badge": "VIP"
      },
      {
        "title": "GIỚI THIỆU BẠN BÈ",
        "subtitle": "Nhận ngay 50 COIN cho mỗi lượt giới thiệu",
        "description": "Chia sẻ mã giới thiệu của bạn và nhận ngay 50 COIN khi bạn bè đăng ký và hoàn thành nạp tiền tối thiểu từ 100 COIN.",
        "code": "REFCODE",
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
                            onPressed: () => _handleClaim(context, authService, user, promo["code"]!),
                            child: Row(
                              children: [
                                Text(_getClaimButtonText(user, promo["code"]!)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, size: 12),
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
    
    if (code == "WELCOME40") {
      pendingAmount = user.unclaimedFirstDepositBonus;
      statusText = pendingAmount > 0 
          ? "Đang có: ${pendingAmount.toStringAsFixed(0)} COIN chờ nhận" 
          : (user.totalDeposited > 0 ? "Nhiệm vụ đã hoàn thành hoặc không khả dụng" : "Chưa thực hiện nạp đầu");
    } else if (code == "VIPREBATE") {
      pendingAmount = user.unclaimedRebate;
      statusText = pendingAmount > 0 
          ? "Tích lũy hoàn trả: ${pendingAmount.toStringAsFixed(2)} COIN" 
          : "Chưa có hoàn trả tích lũy";
    } else if (code == "VIPREWARD") {
      pendingAmount = user.unclaimedVipLevelRewards;
      statusText = pendingAmount > 0 
          ? "Thưởng thăng cấp: ${pendingAmount.toStringAsFixed(0)} COIN chờ nhận" 
          : "Chưa có thưởng thăng cấp mới";
    }

    if (statusText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pendingAmount > 0 ? Colors.green.withOpacity(0.15) : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pendingAmount > 0 ? Colors.green : Colors.white24,
          width: 0.5,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: pendingAmount > 0 ? Colors.green : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getClaimButtonText(UserModel? user, String code) {
    if (user == null) return "NHẬN NGAY";
    
    if (code == "WELCOME40") {
      return user.unclaimedFirstDepositBonus > 0 ? "NHẬN NGAY" : "XEM THÊM";
    } else if (code == "VIPREBATE") {
      return user.unclaimedRebate > 0 ? "NHẬN NGAY" : "XEM THÊM";
    } else if (code == "VIPREWARD") {
      return user.unclaimedVipLevelRewards > 0 ? "NHẬN NGAY" : "XEM THÊM";
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

    if (code == "WELCOME40") {
      if (user.unclaimedFirstDepositBonus > 0) {
        try {
          await authService.claimFirstDepositBonus();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Nhận thưởng nạp đầu thành công +40 COIN!"),
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
            content: Text("Vui lòng nạp tiền lần đầu từ 50 COIN trở lên để đủ điều kiện nhận thưởng."),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } else if (code == "VIPREBATE") {
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
    } else if (code == "VIPREWARD") {
      if (user.unclaimedVipLevelRewards > 0) {
        try {
          final amt = user.unclaimedVipLevelRewards;
          await authService.claimVipLevelRewards();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Nhận thưởng thăng cấp VIP thành công +${amt.toStringAsFixed(0)} COIN!"),
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
            content: Text("Hãy tích lũy nạp tiền để thăng cấp VIP và nhận phần thưởng thăng hạng."),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } else {
      // GIỚI THIỆU BẠN BÈ / MÃ KHÁC
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã sao chép mã khuyến mãi '${code}'!"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
