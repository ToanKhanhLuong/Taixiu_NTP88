import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/repositories/private_chat_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class FriendListScreen extends StatefulWidget {
  final String? openChatWithFriendUid;
  const FriendListScreen({super.key, this.openChatWithFriendUid});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FriendRepository _friendRepo = FriendRepository();
  final PrivateChatRepository _privateChatRepo = PrivateChatRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  UserModel? _searchResult;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    if (widget.openChatWithFriendUid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final currentUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
        if (currentUid == null) return;
        
        final friend = await _friendRepo.findFriendByUid(currentUid, widget.openChatWithFriendUid!);
        if (friend != null && mounted) {
          _privateChatRepo.markAsRead(currentUid, friend.uid);
          _showPrivateChatDialog(context, Provider.of<AuthService>(context, listen: false).currentUser!, friend);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Display a custom floating SnackBar for feedback
  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Search User by ID Code
  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final user = await _friendRepo.findUserByIdCode(query);
      if (user == null) {
        setState(() {
          _searchError = "Không tìm thấy người chơi có mã ID này!";
        });
      } else {
        setState(() {
          _searchResult = user;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = "Lỗi khi tìm kiếm người chơi: $e";
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Render a golden VIP Level badge
  Widget _buildVipBadge(int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF996515), Color(0xFFD4AF37), Color(0xFFFFD700)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "VIP $level",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 9,
        ),
      ),
    );
  }

  IconData _getAvatarIcon(String url) {
    if (url == 'dice') return Icons.casino;
    if (url == 'crown') return Icons.workspace_premium;
    if (url == 'coin') return Icons.monetization_on;
    return Icons.auto_awesome; // Linh Thú Rồng Vàng mặc định
  }

  Widget _buildAvatarWidget(String avatarUrl, {double radius = 20}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(2),
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
            _getAvatarIcon(avatarUrl),
            color: AppColors.goldAccent,
            size: radius * 1.1,
          ),
        ),
      ),
    );
  }

  // Transfer Coin Dialog
  void _showTransferCoinDialog(BuildContext context, UserModel currentUser, UserModel friend) {
    final amountController = TextEditingController();
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
                const Icon(Icons.monetization_on, color: AppColors.goldAccent, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "CHUYỂN COIN",
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipient info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[850]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        _buildAvatarWidget(friend.avatarUrl, radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.fullName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "ID: ${friend.idCode}",
                                style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Balance display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Số dư hiện tại",
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Text(
                          "${currentUser.balance.toStringAsFixed(0)} COIN",
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount input
                  const Text(
                    "Số coin muốn chuyển",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Nhập số coin...",
                      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.toll, color: AppColors.goldAccent),
                      suffixText: "COIN",
                      suffixStyle: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quick amount buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [50, 100, 200, 500].map((amt) {
                      return ActionChip(
                        backgroundColor: AppColors.cardDark,
                        side: BorderSide(color: Colors.grey[800]!),
                        label: Text(
                          "$amt",
                          style: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          amountController.text = amt.toString();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                onPressed: isProcessing ? null : () async {
                  final text = amountController.text.trim();
                  if (text.isEmpty) {
                    _showFeedback("Vui lòng nhập số coin!", AppColors.danger);
                    return;
                  }
                  final amount = double.tryParse(text);
                  if (amount == null || amount <= 0) {
                    _showFeedback("Số coin không hợp lệ!", AppColors.danger);
                    return;
                  }
                  if (amount > currentUser.balance) {
                    _showFeedback("Số dư không đủ để chuyển!", AppColors.danger);
                    return;
                  }

                  setDialogState(() => isProcessing = true);

                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final success = await authService.transferCoin(friend.uid, friend.fullName, amount);
                    if (mounted) Navigator.pop(context);
                    if (success) {
                      _showFeedback("Đã chuyển ${amount.toStringAsFixed(0)} coin cho ${friend.fullName}!", AppColors.success);
                    } else {
                      _showFeedback("Chuyển coin thất bại. Vui lòng thử lại!", AppColors.danger);
                    }
                  } catch (e) {
                    if (mounted) Navigator.pop(context);
                    _showFeedback("Lỗi: ${e.toString()}", AppColors.danger);
                  }
                },
                child: isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("CHUYỂN COIN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Private Live Chat dialog window
  void _showPrivateChatDialog(BuildContext context, UserModel currentUser, UserModel friend) {
    final messageController = TextEditingController();
    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    _buildAvatarWidget(friend.avatarUrl, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'ID: ${friend.idCode}',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppColors.cardDark, thickness: 1.5, height: 24),

                // Real-time Chat Messages list
                Expanded(
                  child: StreamBuilder<List<PrivateChatMessage>>(
                    stream: _privateChatRepo.streamMessages(currentUser.uid, friend.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.goldAccent));
                      }
                      final messages = snapshot.data ?? [];
                      
                      // Auto scroll to bottom when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (scrollController.hasClients) {
                          scrollController.jumpTo(scrollController.position.maxScrollExtent);
                        }
                      });

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            "Hãy gửi tin nhắn để bắt đầu cuộc trò chuyện!",
                            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == currentUser.uid;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMe 
                                    ? AppColors.goldAccent.withOpacity(0.15) 
                                    : AppColors.cardDark,
                                border: Border.all(
                                  color: isMe 
                                      ? AppColors.goldAccent.withOpacity(0.4) 
                                      : Colors.grey[800]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                msg.message,
                                style: TextStyle(
                                  color: isMe ? AppColors.goldAccent : Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(color: AppColors.cardDark, thickness: 1.5, height: 24),

                // Message input field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final text = messageController.text.trim();
                        if (text.isEmpty) return;

                        messageController.clear();
                        await _privateChatRepo.sendMessage(
                          currentUid: currentUser.uid,
                          friendUid: friend.uid,
                          senderName: currentUser.fullName,
                          message: text,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.goldAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.black, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(child: Text("Vui lòng đăng nhập để sử dụng tính năng này", style: TextStyle(color: Colors.white))),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          backgroundColor: AppColors.cardDark,
          elevation: 0,
          title: const Text(
            "DANH SÁCH BẠN BÈ",
            style: TextStyle(
              color: AppColors.goldAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: StreamBuilder<bool>(
              stream: _friendRepo.streamHasIncomingRequests(currentUser.uid),
              builder: (context, snapshot) {
                final hasIncoming = snapshot.data ?? false;
                return TabBar(
                  indicatorColor: AppColors.goldAccent,
                  labelColor: AppColors.goldAccent,
                  unselectedLabelColor: AppColors.textGrey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    const Tab(text: "Bạn bè"),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Lời mời"),
                          if (hasIncoming) ...[
                            const SizedBox(width: 6),
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
                    ),
                    const Tab(text: "Tìm kiếm"),
                  ],
                );
              }
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Friends List
            KeepAliveWrapper(
              child: StreamBuilder<List<UserModel>>(
                stream: _friendRepo.streamFriends(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.goldAccent));
                  }
                  final friends = snapshot.data ?? [];
                  if (friends.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.people_outline,
                      title: "Chưa có bạn bè nào",
                      subtitle: "Tìm kiếm mã ID người chơi khác để kết bạn nhé!",
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return _buildFriendCard(context, currentUser, friend);
                    },
                  );
                },
              ),
            ),

            // TAB 2: Friend Requests
            KeepAliveWrapper(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _friendRepo.streamFriendRequests(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.goldAccent));
                  }
                  final allRequests = snapshot.data ?? [];
                  final received = allRequests.where((r) => r['type'] == 'received').toList();
                  final sent = allRequests.where((r) => r['type'] == 'sent').toList();

                  if (received.isEmpty && sent.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.mail_outline,
                      title: "Không có lời mời kết bạn",
                      subtitle: "Danh sách lời mời kết bạn của bạn hiện đang trống.",
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (received.isNotEmpty) ...[
                        const Text(
                          "LỜI MỜI NHẬN ĐƯỢC",
                          style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ...received.map((req) => _buildRequestCard(context, currentUser, req, isIncoming: true)),
                        const SizedBox(height: 24),
                      ],
                      if (sent.isNotEmpty) ...[
                        const Text(
                          "LỜI MỜI ĐÃ GỬI",
                          style: TextStyle(color: AppColors.textGreyLight, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ...sent.map((req) => _buildRequestCard(context, currentUser, req, isIncoming: false)),
                      ],
                    ],
                  );
                },
              ),
            ),

            // TAB 3: Search and Add Friend
            KeepAliveWrapper(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TÌM KIẾM THEO MÃ ID",
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _searchController,
                            hintText: "Nhập mã ID của người cần kết bạn",
                            prefixIcon: Icons.search_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _handleSearch,
                          child: Container(
                            height: 52,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isSearching
                                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
                                : const Center(
                                    child: Text(
                                      "TÌM",
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_searchError != null)
                      Center(
                        child: Text(
                          _searchError!,
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (_searchResult != null)
                      _buildSearchResultCard(currentUser, _searchResult!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display when a list is empty
  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Active friend row card
  Widget _buildFriendCard(BuildContext context, UserModel currentUser, UserModel friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!, width: 1.5),
      ),
      child: Row(
        children: [
          _buildAvatarWidget(friend.avatarUrl, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        friend.fullName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildVipBadge(friend.vipLevel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${friend.idCode}",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          // Chat Button
          StreamBuilder<bool>(
            stream: _privateChatRepo.streamFriendHasUnread(currentUser.uid, friend.uid),
            builder: (context, snapshot) {
              final hasUnread = snapshot.data ?? false;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.goldAccent, size: 20),
                    onPressed: () {
                      _privateChatRepo.markAsRead(currentUser.uid, friend.uid);
                      _showPrivateChatDialog(context, currentUser, friend);
                    },
                  ),
                  if (hasUnread)
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
              );
            }
          ),
          const SizedBox(width: 4),
          // Transfer Coin Button
          IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.monetization_on_outlined, color: AppColors.success, size: 20),
            tooltip: 'Chuyển coin',
            onPressed: () => _showTransferCoinDialog(context, currentUser, friend),
          ),
          const SizedBox(width: 4),
          // Unfriend Button
          IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.person_remove_outlined, color: AppColors.danger, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardDark,
                  title: const Text("HỦY KẾT BẠN", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                  content: Text("Bạn thực sự muốn hủy kết bạn với ${friend.fullName}?", style: const TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _friendRepo.unfriend(currentUser.uid, friend.uid);
                        _showFeedback("Đã hủy kết bạn với ${friend.fullName}", AppColors.info);
                      },
                      child: const Text("HỦY BẠN BÈ"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Row card for pending requests
  Widget _buildRequestCard(BuildContext context, UserModel currentUser, Map<String, dynamic> req, {required bool isIncoming}) {
    final String targetUid = req['uid'];
    final String fullName = req['fullName'];
    final String idCode = req['idCode'];
    final String avatarUrl = req['avatarUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!, width: 1.5),
      ),
      child: Row(
        children: [
          _buildAvatarWidget(avatarUrl, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  "ID: $idCode",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isIncoming) ...[
            // Decline Button
            IconButton(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: AppColors.danger, size: 22),
              onPressed: () async {
                await _friendRepo.declineFriendRequest(currentUser.uid, targetUid);
                _showFeedback("Đã từ chối lời mời kết bạn từ $fullName", AppColors.info);
              },
            ),
            const SizedBox(width: 4),
            // Accept Button
            IconButton(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.check, color: AppColors.success, size: 22),
              onPressed: () async {
                final targetUser = UserModel(
                  uid: targetUid,
                  fullName: fullName,
                  username: req['username'],
                  email: '',
                  phoneNumber: '',
                  idCode: idCode,
                  avatarUrl: avatarUrl,
                  vipLevel: req['vipLevel'] ?? 0,
                );
                await _friendRepo.acceptFriendRequest(currentUser, targetUser);
                _showFeedback("Bạn và $fullName đã trở thành bạn bè!", AppColors.success);
              },
            ),
          ] else ...[
            // Outgoing request cancellation button
            TextButton(
              onPressed: () async {
                await _friendRepo.declineFriendRequest(currentUser.uid, targetUid);
                _showFeedback("Đã thu hồi lời mời kết bạn", AppColors.info);
              },
              child: const Text(
                "THU HỒI",
                style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          ]
        ],
      ),
    );
  }

  // Card displaying results of ID search
  Widget _buildSearchResultCard(UserModel currentUser, UserModel result) {
    if (result.uid == currentUser.uid) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            "Đây là mã ID của chính bạn!",
            style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return StreamBuilder<List<UserModel>>(
      stream: _friendRepo.streamFriends(currentUser.uid),
      builder: (context, friendsSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _friendRepo.streamFriendRequests(currentUser.uid),
          builder: (context, requestsSnapshot) {
            final friends = friendsSnapshot.data ?? [];
            final requests = requestsSnapshot.data ?? [];

            final isAlreadyFriend = friends.any((f) => f.uid == result.uid);
            final pendingRequest = requests.firstWhere(
              (r) => r['uid'] == result.uid,
              orElse: () => {},
            );

            Widget actionButton;

            if (isAlreadyFriend) {
              actionButton = Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.goldAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  "ĐÃ LÀ BẠN BÈ",
                  style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              );
            } else if (pendingRequest.isNotEmpty) {
              final type = pendingRequest['type'];
              if (type == 'received') {
                actionButton = ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () async {
                    await _friendRepo.acceptFriendRequest(currentUser, result);
                    _showFeedback("Bạn và ${result.fullName} đã trở thành bạn bè!", AppColors.success);
                  },
                  child: const Text("CHẤP NHẬN"),
                );
              } else {
                actionButton = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    border: Border.all(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    "ĐÃ GỬI YÊU CẦU",
                    style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              }
            } else {
              actionButton = CustomButton(
                text: "GỬI KẾT BẠN",
                height: 40,
                width: 140,
                onPressed: () async {
                  await _friendRepo.sendFriendRequest(currentUser, result);
                  _showFeedback("Đã gửi lời mời kết bạn tới ${result.fullName}!", AppColors.success);
                },
              );
            }

            return Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.goldAccent.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  _buildAvatarWidget(result.avatarUrl, radius: 36),
                  const SizedBox(height: 12),
                  Text(
                    result.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "@${result.username}",
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      _buildVipBadge(result.vipLevel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mã ID: ${result.idCode}",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  actionButton,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

