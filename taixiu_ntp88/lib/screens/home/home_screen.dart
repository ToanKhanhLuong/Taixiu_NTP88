import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../game/taixiu_screen.dart';
import '../game/luckyspin_screen.dart';
import '../wallet/wallet_screen.dart';
import '../history/history_screen.dart';
import '../promos/promos_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/friend_list_screen.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/repositories/private_chat_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FriendRepository _friendRepo = FriendRepository();
  final PrivateChatRepository _privateChatRepo = PrivateChatRepository();
  int _currentTabIndex = 0;

  void setTabIndex(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  late final List<Widget> _tabs = [
    LobbyTab(onNavigate: setTabIndex),
    const TaiXiuScreen(),
    const WalletScreen(),
    const HistoryScreen(),
    const PromosScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        body: IndexedStack(
          index: _currentTabIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildCustomBottomNavigationBar(user, false),
      );
    }

    return StreamBuilder<bool>(
      stream: _friendRepo.streamHasIncomingRequests(user.uid),
      builder: (context, reqSnapshot) {
        final hasRequest = reqSnapshot.data ?? false;
        return StreamBuilder<bool>(
          stream: _privateChatRepo.streamHasUnreadMessages(user.uid),
          builder: (context, chatSnapshot) {
            final hasChat = chatSnapshot.data ?? false;
            final showProfileBadge = hasRequest || hasChat;
            return Scaffold(
              body: IndexedStack(
                index: _currentTabIndex,
                children: _tabs,
              ),
              bottomNavigationBar: _buildCustomBottomNavigationBar(user, showProfileBadge),
            );
          }
        );
      }
    );
  }

  Widget _buildCustomBottomNavigationBar(UserModel? user, bool showProfileBadge) {
    bool hasUnclaimed = false;
    if (user != null) {
      hasUnclaimed = user.unclaimedFirstDepositBonus > 0 || 
                     user.unclaimedVipLevelRewards > 0 || 
                     user.unclaimedRebate > 0;
    }

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
          _buildNavBarItem(index: 4, icon: Icons.card_giftcard, label: "Ưu đãi", showBadge: hasUnclaimed),
          _buildNavBarItem(index: 5, icon: Icons.person, label: "Cá nhân", showBadge: showProfileBadge),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData icon,
    required String label,
    bool showBadge = false,
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
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
            if (showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
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
  final Function(int) onNavigate;
  const LobbyTab({super.key, required this.onNavigate});

  void _showNotificationSheet(
    BuildContext context,
    UserModel? user,
    List<Map<String, dynamic>> notifications,
    Function(int) onNavigate,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "THÔNG BÁO MỚI",
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardDark, thickness: 1.5, height: 16),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      "Bạn không có thông báo nào mới",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      IconData iconData = Icons.notifications;
                      Color iconColor = AppColors.goldAccent;
                      
                      if (notif['type'] == 'friend_request') {
                        iconData = Icons.person_add_alt_1;
                        iconColor = AppColors.success;
                      } else if (notif['type'] == 'private_chat') {
                        iconData = Icons.chat_bubble;
                        iconColor = AppColors.goldAccent;
                      } else if (notif['type'] == 'reward') {
                        iconData = Icons.card_giftcard;
                        iconColor = const Color(0xFFFFD700);
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[850]!, width: 1),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context); // Close bottom sheet
                            if (notif['type'] == 'reward') {
                              onNavigate(4); // Switch to PromosTab (index 4)
                            } else if (notif['type'] == 'friend_request') {
                              onNavigate(5); // Switch to ProfileTab (index 5)
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FriendListScreen()),
                              );
                            } else if (notif['type'] == 'private_chat') {
                              onNavigate(5); // Switch to ProfileTab (index 5)
                              final friendUid = notif['payload'] as String;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendListScreen(openChatWithFriendUid: friendUid),
                                ),
                              );
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: iconColor, size: 20),
                          ),
                          title: Text(
                            notif['title'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            notif['body'],
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 14),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
              "NTP88",
              style: TextStyle(
                color: AppColors.goldAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: PrivateChatRepository().streamAllNotifications(user?.uid ?? '', user),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final hasUnread = notifications.isNotEmpty;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      hasUnread ? Icons.notifications_active : Icons.notifications_none,
                      color: hasUnread ? AppColors.goldAccent : Colors.white,
                    ),
                    onPressed: () => _showNotificationSheet(context, user, notifications, onNavigate),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            }
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
                        "${((user?.balance ?? 0.0) - authService.activeBetAmount).toStringAsFixed(0)} COIN",
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
                  backgroundImage: "assets/images/AnhTaixiu.png",
                  onTap: () {
                    // Navigate to the Games tab (index 1)
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?.setTabIndex(1);
                  },
                ),
                _buildGameCard(
                  context,
                  title: "VÒNG QUAY TỶ PHÚ",
                  subtitle: "Vòng Quay May Mắn",
                  icon: Icons.album_outlined,
                  activeColor: AppColors.success,
                  isLive: true,
                  backgroundImage: "assets/images/Vongquaymayman.jpg",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LuckySpinScreen()),
                    );
                  },
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

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool isLive,
    required VoidCallback onTap,
    String? backgroundImage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(140),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }
}
