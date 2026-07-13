import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/bet_model.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database/firebase_service.dart';

class SpinSector {
  final double value;
  final String label;
  final Color color;
  final Color textColor;

  const SpinSector({
    required this.value,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });
}

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Sectors configuration
  final List<SpinSector> _sectors = const [
    SpinSector(value: 30, label: "30 COIN", color: Color(0xFF2C2C2E)),
    SpinSector(value: 150, label: "150 COIN", color: Color(0xFFD4AF37), textColor: Colors.black),
    SpinSector(value: 2000, label: "2000 COIN", color: Color(0xFF8E44AD)),
    SpinSector(value: 0, label: "MAY MẮN", color: Color(0xFF34495E)),
    SpinSector(value: 250, label: "250 COIN", color: Color(0xFFD35400)),
    SpinSector(value: 1000, label: "1000 COIN", color: Color(0xFF2980B9)),
    SpinSector(value: 50, label: "50 COIN", color: Color(0xFF1C1C1E)),
    SpinSector(value: 9999, label: "JACKPOT", color: Color(0xFFC0392B)),
    SpinSector(value: 2500, label: "2500 COIN", color: Color(0xFF27AE60)),
  ];

  // Weighted random distribution
  // Total weight: 1000
  // 30 COIN: 250 (25%)
  // Chúc bạn may mắn: 200 (20%)
  // 50 COIN: 200 (20%)
  // 150 COIN: 150 (15%)
  // 250 COIN: 110 (11%)
  // 1000 COIN: 45 (4.5%)
  // 2000 COIN: 25 (2.5%)
  // 2500 COIN: 15 (1.5%)
  // JACKPOT (9999 COIN): 5 (0.5%)
  final List<int> _weights = [250, 150, 25, 200, 110, 45, 200, 5, 15];

  bool _isSpinning = false;
  double _currentRotation = 0.0;
  int _activeTab = 0; // 0: Lịch sử quay, 1: Bảng vinh danh
  SpinSector? _lastResult;
  double _displayedBalanceOffset = 0.0;
  BetModel? _pendingBet;

  double _getDisplayedBalance(UserModel? user, double activeBetAmount) {
    if (user == null) return 0.0;
    return user.balance - activeBetAmount + _displayedBalanceOffset;
  }

  String? _currentSpinBetId;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  int _pickWeightedSector() {
    int totalWeight = _weights.reduce((a, b) => a + b);
    int randomValue = _random.nextInt(totalWeight);
    int cumulativeWeight = 0;
    
    for (int i = 0; i < _sectors.length; i++) {
      cumulativeWeight += _weights[i];
      if (randomValue < cumulativeWeight) {
        return i;
      }
    }
    return 0;
  }

  Future<void> _startSpin() async {
    if (_isSpinning) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để thực hiện quay thưởng.")),
      );
      return;
    }

    final double effectiveBalance = user.balance - authService.activeBetAmount;
    if (effectiveBalance < 800.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Số dư không đủ! Cần 800 COIN mỗi lượt quay."),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // 1. Pick result index and prepare pending bet
    int targetIndex = _pickWeightedSector();
    final targetSector = _sectors[targetIndex];
    
    final bool isWin = targetSector.value > 0;
    final betId = 'spin_${DateTime.now().millisecondsSinceEpoch}';
    final bet = BetModel(
      id: betId,
      userId: user.uid,
      gameType: 'Lucky Spin',
      detail: 'Vòng Quay May Mắn',
      choice: 'Quay thưởng',
      amount: 800.0,
      winAmount: targetSector.value,
      status: isWin ? 'win' : 'loss',
      resultString: isWin ? 'Nhận +${targetSector.value.toStringAsFixed(0)} COIN' : 'Chúc bạn may mắn lần sau',
      timestamp: DateTime.now(),
    );

    setState(() {
      _isSpinning = true;
      _displayedBalanceOffset = -800.0;
      _pendingBet = bet;
      _lastResult = null;
    });

    // 2. Calculate target rotation angle
    double sectorAngle = 360.0 / _sectors.length;
    double halfSector = sectorAngle / 2.0;
    double minOffset = sectorAngle * 0.15;
    double maxOffset = sectorAngle * 0.85;
    double randomOffset = minOffset + _random.nextDouble() * (maxOffset - minOffset);
    
    double targetRotationDegrees = (halfSector - (targetIndex * sectorAngle) - randomOffset) % 360.0;
    
    double finalAngleRadians = (10 * math.pi) + (targetRotationDegrees * (math.pi / 180.0));

    _rotationController.reset();
    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: finalAngleRadians,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic,
    ));

    double lastTickAngle = _currentRotation;
    double tickGap = (2 * math.pi) / _sectors.length;
    _rotationAnimation.addListener(() {
      double diff = _rotationAnimation.value - lastTickAngle;
      if (diff.abs() >= tickGap) {
        lastTickAngle = _rotationAnimation.value;
      }
    });

    try {
      // 3. Play animation only (completely offline, zero DB notifyListener updates to ensure maximum 60fps smoothness)
      await _rotationController.forward();
      
      // 4. Update final rotation value
      _currentRotation = _rotationAnimation.value % (2 * math.pi);

      if (!mounted) return;

      setState(() {
        _lastResult = targetSector;
        _isSpinning = false;
        _displayedBalanceOffset = targetSector.value - 800.0;
      });

      // Show congratulations dialog
      _showResultDialog(targetSector);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
        _displayedBalanceOffset = 0.0;
        _pendingBet = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xảy ra: $e")),
      );
    }
  }

  void _showResultDialog(SpinSector sector) {
    bool isWin = sector.value > 0;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWin 
                  ? [const Color(0xFF1E1C15), const Color(0xFF352F1B)] 
                  : [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isWin ? AppColors.goldAccent : AppColors.borderGrey,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isWin ? AppColors.goldAccent : Colors.black).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isWin ? AppColors.goldAccent : AppColors.textGrey).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWin ? Icons.stars : Icons.sentiment_dissatisfied,
                    color: isWin ? AppColors.goldAccent : AppColors.textGrey,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  isWin ? "XIN CHÚC MỪNG!" : "MAY MẮN LẦN SAU",
                  style: TextStyle(
                    color: isWin ? AppColors.goldLight : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Message Detail
                Text(
                  isWin 
                    ? "Bạn đã quay trúng phần thưởng trị giá:" 
                    : "Lần này chưa trúng rồi, hãy tiếp tục thử vận may nhé!",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (isWin) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: AppColors.goldLight, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "${sector.value.toStringAsFixed(0)} COIN",
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWin ? AppColors.goldAccent : AppColors.cardDarkLight,
                    foregroundColor: isWin ? Colors.black : Colors.white,
                    side: isWin ? null : const BorderSide(color: AppColors.borderGrey),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("XÁC NHẬN"),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) async {
      // This is triggered when dialog is closed (by pressing "XÁC NHẬN" or tapping outside)
      final bet = _pendingBet;
      if (bet != null && mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        try {
          // Write bet and update user balance in Firestore/Mock
          await authService.placeBet(bet);
          
          // Log to Firestore leaderboard if it's a big win
          if (FirebaseService.isInitialized && bet.winAmount >= 2500.0 && user != null) {
            FirebaseFirestore.instance.collection('lucky_spin_leaderboard').add({
              'username': user.username.isNotEmpty ? user.username : user.fullName,
              'winAmount': bet.winAmount,
              'timestamp': FieldValue.serverTimestamp(),
              'isJackpot': bet.winAmount == 9999.0,
            }).catchError((e) {
              debugPrint("Failed to write to leaderboard: $e");
            });
          }
        } catch (e) {
          debugPrint("Error saving spin result: $e");
        } finally {
          if (mounted) {
            setState(() {
              _displayedBalanceOffset = 0.0;
              _pendingBet = null;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VÒNG QUAY TỶ PHÚ",
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.goldAccent.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppColors.goldAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  "${_getDisplayedBalance(user, authService.activeBetAmount).toStringAsFixed(0)} COIN",
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Spin Wheel Section
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.scaffoldBackground],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "CHI PHÍ: 800 COIN / LƯỢT",
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Wheel Container with Pointer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Wheel Outer Ring Glow
                      Container(
                        width: 312,
                        height: 312,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldAccent.withOpacity(0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(color: AppColors.borderGrey, width: 2),
                        ),
                      ),
                      
                      // Animated Spin Wheel
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          double angle = _isSpinning
                              ? _rotationAnimation.value
                              : _currentRotation;
                          return Transform.rotate(
                            angle: angle,
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: CustomPaint(
                                painter: LuckyWheelPainter(
                                  sectors: _sectors,
                                  rotationValue: angle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Center SPIN Button
                      GestureDetector(
                        onTap: _isSpinning ? null : _startSpin,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF2B2), Color(0xFFD4AF37), Color(0xFF996515)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: AppColors.goldLight.withOpacity(_isSpinning ? 0.2 : 0.5),
                                blurRadius: 20,
                                spreadRadius: _isSpinning ? 0 : 3,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFFFF0A5),
                              width: 3,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E1E1E),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isSpinning ? "QUAY" : "SPIN",
                                    style: const TextStyle(
                                      color: AppColors.goldAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (!_isSpinning)
                                    const Text(
                                      "800 C",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Pointer Indicator at top center
                      Positioned(
                        top: -12,
                        child: CustomPaint(
                          size: const Size(28, 32),
                          painter: WheelPointerPainter(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Latest Spin Result Ticker
                  if (_lastResult != null)
                    AnimatedOpacity(
                      opacity: _lastResult != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_lastResult!.value > 0 ? AppColors.success : AppColors.textGrey).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (_lastResult!.value > 0 ? AppColors.success : AppColors.textGrey).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          _lastResult!.value > 0 
                              ? "Kết quả: +${_lastResult!.value.toStringAsFixed(0)} COIN!"
                              : "Kết quả: Chúc bạn may mắn lần sau!",
                          style: TextStyle(
                            color: _lastResult!.value > 0 ? AppColors.success : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 38),
                ],
              ),
            ),
          ),

          // Bottom Tabs (History & Leaderboard)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Tab selection header
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                    child: Row(
                      children: [
                        _buildTabButton(0, "LỊCH SỬ QUAY"),
                        const SizedBox(width: 16),
                        _buildTabButton(1, "TOP NHẬN THƯỞNG"),
                      ],
                    ),
                  ),
                  
                  const Divider(color: AppColors.borderGrey, height: 24),
                  
                  // Tab Content Area
                  Expanded(
                    child: IndexedStack(
                      index: _activeTab,
                      children: [
                        _buildUserSpinHistory(authService, user?.uid),
                        _buildLeaderboardTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    bool isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.goldAccent : AppColors.cardDarkLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.goldAccent : AppColors.borderGrey,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSpinHistory(AuthService authService, String? userId) {
    if (userId == null) {
      return const Center(
        child: Text(
          "Vui lòng đăng nhập để xem lịch sử.",
          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
      );
    }

    // Filter bet list for gameType = 'Lucky Spin' and exclude current active spin until user confirms it
    final spinBets = authService.bets
        .where((bet) => bet.gameType == 'Lucky Spin' && bet.id != _pendingBet?.id)
        .toList();

    if (spinBets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, color: AppColors.textGrey.withOpacity(0.3), size: 48),
            const SizedBox(height: 8),
            const Text(
              "Chưa có lịch sử quay thưởng.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: spinBets.length,
      itemBuilder: (context, index) {
        final bet = spinBets[index];
        final bool isWin = bet.winAmount > 0;
        final timeStr = "${bet.timestamp.hour.toString().padLeft(2, '0')}:${bet.timestamp.minute.toString().padLeft(2, '0')} - ${bet.timestamp.day}/${bet.timestamp.month}";

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDarkLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWin ? "TRÚNG PHẦN THƯỞNG" : "CHÚC MAY MẮN",
                    style: TextStyle(
                      color: isWin ? AppColors.goldLight : AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "Cược: 800",
                    style: TextStyle(color: AppColors.textGrey.withOpacity(0.6), fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isWin ? "+${bet.winAmount.toStringAsFixed(0)} COIN" : "0 COIN",
                    style: TextStyle(
                      color: isWin ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    // If Firebase is active, we query real-time leaderboard list from Firestore
    if (FirebaseService.isInitialized) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lucky_spin_leaderboard')
            .where('winAmount', isGreaterThanOrEqualTo: 2500.0)
            .orderBy('winAmount', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            );
          }

          List<Map<String, dynamic>> listWins = [];
          if (snapshot.hasData && snapshot.data != null) {
            listWins = snapshot.data!.docs.map((doc) {
              final data = doc.data();
              Timestamp? ts = data['timestamp'] as Timestamp?;
              String timeVal = "Vừa xong";
              if (ts != null) {
                final diff = DateTime.now().difference(ts.toDate());
                if (diff.inMinutes < 60) {
                  timeVal = "${diff.inMinutes} phút trước";
                } else {
                  timeVal = "${diff.inHours} giờ trước";
                }
              }
              return {
                "username": data['username'] ?? "Khách Prestige",
                "winAmount": (data['winAmount'] as num?)?.toDouble() ?? 0.0,
                "time": timeVal,
                "isJackpot": data['isJackpot'] ?? false,
              };
            }).toList();
          }

          if (listWins.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Chưa có vinh danh trúng thưởng nào lớn.",
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ),
            );
          }

          return _buildLeaderboardList(listWins);
        },
      );
    } else {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Kết nối máy chủ để xem bảng vinh danh.",
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ),
      );
    }
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> winners) {
    // Sort descending by winAmount just to be safe
    winners.sort((a, b) => (b['winAmount'] as num).compareTo(a['winAmount'] as num));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: winners.length,
      itemBuilder: (context, index) {
        final winner = winners[index];
        final double winAmt = (winner['winAmount'] as num).toDouble();
        final String name = winner['username'];
        final String time = winner['time'];
        final bool isJackpot = winner['isJackpot'] ?? (winAmt == 9999.0);

        Widget rankBadge;
        if (index == 0) {
          rankBadge = const Icon(Icons.emoji_events, color: Colors.amber, size: 24);
        } else if (index == 1) {
          rankBadge = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 22);
        } else if (index == 2) {
          rankBadge = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20);
        } else {
          rankBadge = CircleAvatar(
            radius: 10,
            backgroundColor: Colors.transparent,
            child: Text(
              "${index + 1}",
              style: const TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isJackpot ? const Color(0xFF2C1E1E) : AppColors.cardDarkLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isJackpot ? Colors.redAccent.withOpacity(0.3) : AppColors.borderGrey,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Center(child: rankBadge)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        if (isJackpot) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "JACKPOT",
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.goldLight, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "+${winAmt.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: isJackpot ? Colors.redAccent : AppColors.goldLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painter to draw the premium Roulette wheel
class LuckyWheelPainter extends CustomPainter {
  final List<SpinSector> sectors;
  final double rotationValue;

  LuckyWheelPainter({required this.sectors, required this.rotationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);

    final double sweepAngle = (2 * math.pi) / sectors.length;

    // Draw wedges
    for (int i = 0; i < sectors.length; i++) {
      final sector = sectors[i];
      final double startAngle = -math.pi / 2 - sweepAngle / 2 + (i * sweepAngle);

      // Wedge background
      final paint = Paint()
        ..color = sector.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Add a subtle radial gradient highlight overlay to each wedge
      // to make it look 3D (shiny glass or gloss effect)
      final highlightPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.08), Colors.transparent],
          stops: const [0.0, 0.85],
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, highlightPaint);

      // Draw separators (fine gold line)
      final linePaint = Paint()
        ..color = AppColors.goldAccent.withOpacity(0.3)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweepAngle, true, linePaint);
    }

    // Draw decorations (e.g. golden dots/stars near the rim)
    for (int i = 0; i < sectors.length; i++) {
      final double startAngle = -math.pi / 2 - sweepAngle / 2 + (i * sweepAngle);
      final double middleAngle = startAngle + sweepAngle / 2;
      
      // Paint a little gold diamond at radius * 0.85
      final double decorationDist = radius * 0.85;
      final double decX = centerX + math.cos(middleAngle) * decorationDist;
      final double decY = centerY + math.sin(middleAngle) * decorationDist;
      
      final decPaint = Paint()
        ..color = AppColors.goldLight.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(decX, decY), 2.0, decPaint);
    }

    // Draw radial labels (Labels oriented outwards)
    for (int i = 0; i < sectors.length; i++) {
      final sector = sectors[i];
      final double startAngle = -math.pi / 2 - sweepAngle / 2 + (i * sweepAngle);
      final double middleAngle = startAngle + sweepAngle / 2;

      canvas.save();

      // Translate origin to middle of wedge text position
      // Distance is ~ 65% of radius
      final double textDist = radius * 0.65;
      final double textX = centerX + math.cos(middleAngle) * textDist;
      final double textY = centerY + math.sin(middleAngle) * textDist;

      canvas.translate(textX, textY);

      // Rotate text to align with the wedge line
      canvas.rotate(middleAngle + math.pi / 2);

      // Setup TextPainter
      final textStyle = TextStyle(
        color: sector.textColor,
        fontSize: sector.value == 9999 ? 11 : 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      );

      final textSpan = TextSpan(
        text: sector.label,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Draw Outer Rim Backing (Dark Luxury Bevel)
    final outerBevelPaint = Paint()
      ..color = const Color(0xFF1E1E24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;
    canvas.drawCircle(Offset(centerX, centerY), radius - 8, outerBevelPaint);

    // Draw Outer Gold Rim Border (Thick shiny ring)
    final rimPaint = Paint()
      ..shader = AppColors.goldGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(Offset(centerX, centerY), radius - 2, rimPaint);

    // Inner gold rim
    final innerRimBorderPaint = Paint()
      ..shader = AppColors.goldGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(centerX, centerY), radius - 16, innerRimBorderPaint);

    // Draw Inner Center Rim backing
    final innerRimPaint = Paint()
      ..color = const Color(0xFF0F0F11)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.28, innerRimPaint);

    // Shiny gold center gradient
    final innerGoldPaint = Paint()
      ..shader = AppColors.goldGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.28, innerGoldPaint);

    // Draw Small glowing LED lights around the rim (flashing effect look)
    final ledPaint = Paint()
      ..style = PaintingStyle.fill;

    const int ledCount = 24; // More LEDs for high-fidelity look
    final int lightOffset = (rotationValue * 8).floor();

    for (int i = 0; i < ledCount; i++) {
      double angle = (2 * math.pi / ledCount) * i;
      double ledRadius = radius - 8.0;
      double ledX = centerX + math.cos(angle) * ledRadius;
      double ledY = centerY + math.sin(angle) * ledRadius;
      
      bool isLit = (i + lightOffset) % 3 == 0;
      
      if (isLit) {
        ledPaint.color = AppColors.goldLight;
        canvas.drawCircle(Offset(ledX, ledY), 4.5, Paint()..color = AppColors.goldLight.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
        canvas.drawCircle(Offset(ledX, ledY), 3.0, ledPaint);
      } else {
        ledPaint.color = Colors.white30;
        canvas.drawCircle(Offset(ledX, ledY), 2.5, ledPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LuckyWheelPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue;
  }
}

// Indicator Pin pointer painter at the top
class WheelPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.goldLight
      ..style = PaintingStyle.fill;

    // Draw a more beautiful 3D diamond pointer
    final path = Path()
      ..moveTo(size.width / 2, size.height) // Pointing down
      ..lineTo(0, size.height * 0.2)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.2)
      ..close();

    // Draw pointer shadow
    canvas.drawShadow(path.shift(const Offset(0, 3)), Colors.black87, 5.0, true);
    
    // Gradient fill for 3D look
    final gradient = LinearGradient(
      colors: [const Color(0xFFFFF2B2), AppColors.goldDark],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Bevel highlights
    final borderPaint = Paint()
      ..color = const Color(0xFFFFF0A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);

    // Red gem in the center
    final gemPaint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.35), 4.5, gemPaint);
    
    final gemHighlight = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2 - 1.5, size.height * 0.35 - 1.5), 1.2, gemHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
