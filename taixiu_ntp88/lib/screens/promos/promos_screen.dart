import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class PromosScreen extends StatelessWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    final List<Map<String, String>> promos = [
      {
        "title": "KHUYẾN MÃI NẠP ĐẦU 100%",
        "subtitle": "Tặng tới 500 COIN cho lần nạp đầu tiên",
        "description": "Đăng ký hôm nay và nhân đôi số tiền nạp đầu tiên của bạn. Chơi Tài Xỉu, Slots hay Casino với nguồn vốn cực khủng.",
        "code": "PRESTIGE100",
        "badge": "MỚI"
      },
      {
        "title": "HOÀN TRẢ HÀNG NGÀY 1.5%",
        "subtitle": "Hoàn trả không giới hạn mỗi ngày",
        "description": "Nhận lại ngay 1.5% tổng số COIN đã đặt cược vào lúc 12:00 trưa hàng ngày. Không yêu cầu doanh thu cược, rút tiền bất cứ lúc nào.",
        "code": "DAILYBACK",
        "badge": "HOT"
      },
      {
        "title": "CÂU LẠC BỘ VIP PRESTIGE",
        "subtitle": "Nâng cấp tài khoản nhận đặc quyền VIP 5+",
        "description": "Hưởng ưu đãi độc quyền, hỗ trợ viên cá nhân 24/7, hạn mức rút tiền cao hơn và quà tặng sinh nhật bằng COIN hấp dẫn.",
        "code": "VIPCLUB",
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
                "${(user?.balance ?? 0).toStringAsFixed(0)} COIN",
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Đã nhận khuyến mãi từ mã '${promo["code"]}'!"),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text("NHẬN NGAY"),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 12),
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
}
