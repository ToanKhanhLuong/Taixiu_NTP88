import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../game/taixiu_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/history_screen.dart';
import '../promos/promos_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  void setTabIndex(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  final List<Widget> _tabs = [
    const LobbyTab(),
    const TaiXiuScreen(),
    const WalletScreen(),
    const HistoryScreen(),
    const PromosScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          top: BorderSide(color: AppColors.borderGrey.withOpacity(0.8), width: 1),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(index: 0, icon: Icons.home_filled, label: "Trang chủ"),
          _buildNavBarItem(index: 1, icon: Icons.casino, label: "Trò chơi"),
          _buildNavBarItem(index: 2, icon: Icons.account_balance_wallet, label: "Ví tiền"),
          _buildNavBarItem(index: 3, icon: Icons.restore, label: "Lịch sử"),
          _buildNavBarItem(index: 4, icon: Icons.card_giftcard, label: "Ưu đãi"),
          _buildNavBarItem(index: 5, icon: Icons.person, label: "Cá nhân"),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : AppColors.textGrey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textGrey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Lobby Tab Widget ---

class LobbyTab extends StatelessWidget {
  const LobbyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: Row(
          children: [
            // Gold Dice mini icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.casino, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "MACAU PRESTIGE",
              style: TextStyle(
                color: AppColors.goldAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Không có thông báo mới")),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.darkCardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chào mừng trở lại,",
                    style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? "Khách hàng Prestige",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.goldAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "${(user?.balance ?? 0.0).toStringAsFixed(0)} COIN",
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Categories Title
            const Text(
              "DANH MỤC TRÒ CHƠI",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            
            // Quick game launch section
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildGameCard(
                  context,
                  title: "TÀI XỈU VIP",
                  subtitle: "Lắc Xúc Xắc",
                  icon: Icons.casino,
                  activeColor: AppColors.goldAccent,
                  isLive: true,
                  onTap: () {
                    // Navigate to the Games tab (index 1)
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.setTabIndex(1);
                  },
                ),
                _buildGameCard(
                  context,
                  title: "SLOTS MACAU",
                  subtitle: "Quay Hũ Jackpot",
                  icon: Icons.videogame_asset,
                  activeColor: Colors.purpleAccent,
                  isLive: false,
                  onTap: () => _showComingSoon(context, "Slots Macau"),
                ),
                _buildGameCard(
                  context,
                  title: "BACCARAT LIVE",
                  subtitle: "Sòng Bài Trực Tuyến",
                  icon: Icons.style,
                  activeColor: Colors.blueAccent,
                  isLive: false,
                  onTap: () => _showComingSoon(context, "Baccarat Live"),
                ),
                _buildGameCard(
                  context,
                  title: "ROULETTE WHEEL",
                  subtitle: "Vòng Quay May Mắn",
                  icon: Icons.album_outlined,
                  activeColor: AppColors.success,
                  isLive: false,
                  onTap: () => _showComingSoon(context, "Roulette Wheel"),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Promotions highlight banner
            GestureDetector(
              onTap: () {
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?.setTabIndex(4);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF996515), Color(0xFFD4AF37)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.black, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NHẬN KHUYẾN MÃI 500 COIN",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Nhấn để xem các chương trình ưu đãi và giftcode",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'$game' hiện đang bảo trì nâng cấp. Hãy chơi 'Tài Xỉu VIP'!"),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool isLive,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: activeColor, size: 32),
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "TRỰC TIẾP",
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    )
                  ]
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
