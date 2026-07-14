import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../data/models/bet_model.dart';
import '../../data/repositories/bet_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = "Tất cả";
  final List<String> _filters = ["Tất cả", "Tai Xiu", "Football Bets", "Casino"];
  final BetRepository _betRepo = BetRepository();

  String _displayFilterName(String filter) {
    switch (filter) {
      case 'Tất cả': return 'TẤT CẢ';
      case 'Tai Xiu': return 'TÀI XỈU';
      case 'Football Bets': return 'BÓNG ĐÁ';
      case 'Casino': return 'CASINO';
      default: return filter.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(
          child: Text(
            "Vui lòng đăng nhập để xem lịch sử cược.",
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: const Text(
          "NTP88",
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
                "${(user.balance - authService.activeBetAmount).toStringAsFixed(0)} COIN",
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
      body: Column(
        children: [
          // Bộ lọc nhanh loại game (Tài Xỉu/Bóng đá/Baccarat/...)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final bool isSelected = _activeFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(
                      _displayFilterName(filter),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _activeFilter = filter;
                        });
                      }
                    },
                    selectedColor: AppColors.goldAccent,
                    backgroundColor: AppColors.cardDark,
                    side: BorderSide(
                      color: isSelected ? AppColors.goldAccent : AppColors.borderGrey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),

          // StreamBuilder lắng nghe lịch sử cược theo thời gian thực (real-time stream)
          Expanded(
            child: StreamBuilder<List<BetModel>>(
              stream: authService.isFirebaseActive 
                  ? _betRepo.streamBetHistory(user.uid) 
                  : Stream.value(authService.bets),
              builder: (context, snapshot) {
                List<BetModel> allBets = [];
                if (snapshot.hasData && snapshot.data != null) {
                  allBets = List<BetModel>.from(snapshot.data!);
                }

                // Fallback: Nếu không tải được hoặc danh sách cược rỗng, tự động tái cấu trúc từ danh sách giao dịch cược (bet_win, bet_loss)
                if (allBets.isEmpty) {
                  final betTransactions = authService.transactions
                      .where((tx) => tx.type == 'bet_win' || tx.type == 'bet_loss')
                      .toList();
                  if (betTransactions.isNotEmpty) {
                    allBets = betTransactions.map((tx) {
                      final bool isWin = tx.type == 'bet_win';
                      return BetModel(
                        id: tx.id,
                        userId: tx.userId,
                        gameType: 'Tai Xiu',
                        detail: isWin ? 'Tài Xỉu VIP - Thắng' : 'Tài Xỉu VIP - Thua',
                        choice: isWin ? 'Thắng cược' : 'Thua cược',
                        amount: isWin ? tx.amount / 2 : tx.amount,
                        winAmount: isWin ? tx.amount : 0.0,
                        status: isWin ? 'win' : 'loss',
                        resultString: isWin ? 'Thắng cược' : 'Thua cược',
                        timestamp: tx.timestamp,
                      );
                    }).toList();
                  }
                }

                if (allBets.isEmpty) {
                  if (snapshot.hasError) {
                    debugPrint("Firestore bet history error: ${snapshot.error}");
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.goldAccent,
                      ),
                    );
                  }
                }
                
                // Sắp xếp lại lịch sử cược theo thời gian mới nhất (đảm bảo hiển thị đúng thứ tự)
                allBets.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                // Lọc dữ liệu cược theo tab đã chọn và giới hạn hiển thị tối đa 25 cược mới nhất
                final filteredBets = allBets.where((bet) {
                  if (_activeFilter == "Tất cả") return true;
                  final String typeLower = bet.gameType.toLowerCase();
                  if (_activeFilter == "Tai Xiu") return typeLower.contains("tai xiu") || typeLower.contains("tài xỉu");
                  if (_activeFilter == "Football Bets") return typeLower.contains("football") || typeLower.contains("bóng đá");
                  if (_activeFilter == "Casino") return typeLower.contains("casino") || typeLower.contains("lucky spin") || typeLower.contains("vòng quay");
                  return true;
                }).take(25).toList();

                if (filteredBets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_chart_outlined,
                          color: AppColors.textGrey.withOpacity(0.4),
                          size: 54,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Không tìm thấy lịch sử cược cho '${_displayFilterName(_activeFilter)}'.",
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredBets.length,
                  itemBuilder: (context, index) {
                    final BetModel bet = filteredBets[index];
                    final bool isWin = bet.status == 'win';
                    
                    return Card(
                      color: AppColors.cardDark,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderGrey),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dòng 1: Tên chi tiết game & Trạng thái THẮNG/THUA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bet.detail.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isWin ? AppColors.success : AppColors.danger).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isWin ? "THẮNG" : "THUA",
                                    style: TextStyle(
                                      color: isWin ? AppColors.success : AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // Dòng 2: Cửa đặt cược & Kết quả xí ngầu
                            Row(
                              children: [
                                const Text(
                                  "Cửa đặt: ",
                                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                                ),
                                Text(
                                  bet.choice,
                                  style: const TextStyle(
                                    color: AppColors.goldLight, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 12
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  bet.resultString,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            
                            const Divider(color: AppColors.borderGrey, height: 20),

                            // Dòng 3: Thời gian cược, Số tiền đặt và Số tiền nhận lại
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${bet.timestamp.day}/${bet.timestamp.month}/${bet.timestamp.year} ${bet.timestamp.hour.toString().padLeft(2, '0')}:${bet.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Cược: ${bet.amount.toStringAsFixed(0)} C",
                                      style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isWin 
                                          ? "Thắng: +${bet.winAmount.toStringAsFixed(0)} COIN"
                                          : "Thua: -${bet.amount.toStringAsFixed(0)} COIN",
                                      style: TextStyle(
                                        color: isWin ? AppColors.success : AppColors.danger,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
