import 'dart:async';
import 'dart:math' as math_random;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/bet_model.dart';
import '../../services/auth_service.dart';

class TaiXiuScreen extends StatefulWidget {
  const TaiXiuScreen({super.key});

  @override
  State<TaiXiuScreen> createState() => _TaiXiuScreenState();
}

class _TaiXiuScreenState extends State<TaiXiuScreen> with TickerProviderStateMixin {
  // Game session & states (đồng bộ toàn cầu qua giờ UTC)
  int _sessionId = 934042;
  int _timerSeconds = 15;
  Timer? _gameTimer;
  String _gameState = "BETTING"; // "BETTING", "ROLLING", "RESULT"
  
  List<int> _diceResult = [1, 2, 3];
  
  // Bead History (Lịch sử cầu): true = Tài (Đen/Xám), false = Xỉu (Trắng)
  final List<bool> _beadHistory = [];

  // Chip & Bet System
  int _selectedChip = 10;
  
  // Số tiền cược đã chốt thực tế
  double _myBetOnTai = 0;
  double _myBetOnXiu = 0;
  
  // Số tiền cược tạm tính (staged)
  double _stagedBetOnTai = 0;
  double _stagedBetOnXiu = 0;

  // Cửa cược đang chọn nháp để All-In
  String _activeBetSide = ""; // "TAI", "XIU" hoặc ""

  // Running pools (đồng bộ theo thuật toán thời gian)
  int _taiPool = 741648000;
  int _xiuPool = 741648000;
  int _taiPlayers = 2093;
  int _xiuPlayers = 1805;

  // Interactive Bowl Cover ("Mở Bát" system)
  bool _isBowlCovered = false;
  int _bowlRevealSeconds = 5;
  bool _userManuallyRevealed = false;
  bool _hasEvaluatedRoundBets = false; // Tránh tính cược trùng nhiều lần trong 1 vòng
  bool _isSqueezeMode = true; // Chế độ "Nặn" (mặc định Bật)

  // Drag offsets for the golden cover
  double _bowlDragX = 0.0;
  double _bowlDragY = 0.0;

  String _lastResultText = "";

  // Animation controller for dice shaking
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Shaking Animation Setup
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: -10.0, end: 10.0).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);

    _startGlobalClockSync();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // Khởi chạy vòng lặp đồng bộ thời gian thực dựa trên UTC Clock
  void _startGlobalClockSync() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncWithGlobalClock();
    });
    _syncWithGlobalClock(); // Chạy ngay lập tức khi vào màn hình
  }

  void _syncWithGlobalClock() {
    // Lấy số giây của Unix epoch UTC hiện tại
    final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Mỗi phiên game kéo dài cố định 30 giây
    final int cyclePosition = nowSeconds % 30;
    final int currentSessionId = nowSeconds ~/ 30;
    
    String calculatedState;
    int remainingSeconds;

    if (cyclePosition < 15) {
      // Giây 0 - 14: Giai đoạn đặt cược (15s đếm ngược)
      calculatedState = "BETTING";
      remainingSeconds = 15 - cyclePosition;
    } else if (cyclePosition < 17) {
      // Giây 15 - 16: Giai đoạn lắc đĩa (2s)
      calculatedState = "ROLLING";
      remainingSeconds = 0;
    } else {
      // Giây 17 - 29: Giai đoạn công bố kết quả (13s)
      calculatedState = "RESULT";
      remainingSeconds = 30 - cyclePosition;
    }

    // Xử lý chuyển đổi trạng thái phiên trước khi thực hiện các phép tính của chu kỳ mới
    if (_gameState != calculatedState) {
      if (calculatedState == "RESULT") {
        _userManuallyRevealed = false;
        _hasEvaluatedRoundBets = false; // Reset cờ tính cược cho phiên mới
        _bowlDragX = 0.0;
        _bowlDragY = 0.0;
      }
      
      if (calculatedState == "BETTING") {
        // Làm sạch cược khi bắt đầu phiên mới
        _myBetOnTai = 0;
        _myBetOnXiu = 0;
        _stagedBetOnTai = 0;
        _stagedBetOnXiu = 0;
        _activeBetSide = "";

        // Gọi hiển thị cảnh báo nếu tài khoản hết tiền cược
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndShowZeroBalanceDialog();
        });
      }
      
      _gameState = calculatedState; // Đồng bộ hóa cục bộ ngay lập tức
    }

    // Tính toán shouldCoverBowl sử dụng biến _userManuallyRevealed đã được reset đúng đắn
    bool shouldCoverBowl = false;
    if (calculatedState == "RESULT") {
      // Nếu chế độ Nặn (Squeeze) Bật, che bát trong 5 giây đầu (giây 17 đến 21 trong chu kỳ)
      if (_isSqueezeMode && !_userManuallyRevealed) {
        shouldCoverBowl = cyclePosition < 22;
      }
    }

    // Sinh xúc xắc ngẫu nhiên hạt giống (Seeded Random theo ID phiên đấu)
    final math_random.Random seededRandom = math_random.Random(currentSessionId);
    final int d1 = seededRandom.nextInt(6) + 1;
    final int d2 = seededRandom.nextInt(6) + 1;
    final int d3 = seededRandom.nextInt(6) + 1;
    final List<int> currentDiceResult = [d1, d2, d3];
    final int total = d1 + d2 + d3;
    final bool isTai = total >= 11 && total <= 17;
    final String resultLabel = isTai ? "TÀI" : "XỈU";
    final String currentResultText = "$resultLabel ($d1, $d2, $d3) = $total";

    // Sinh số liệu cược (Pool) đồng bộ dựa trên ID phiên và giây trong chu kỳ
    final math_random.Random poolRandom = math_random.Random(currentSessionId);
    int baseTaiPool = 741648000 + poolRandom.nextInt(500000);
    int baseXiuPool = 741648000 + poolRandom.nextInt(500000);
    int baseTaiPlayers = 1800 + poolRandom.nextInt(400);
    int baseXiuPlayers = 1600 + poolRandom.nextInt(450);

    if (calculatedState == "BETTING") {
      baseTaiPool += cyclePosition * 12340;
      baseXiuPool += cyclePosition * 11580;
      baseTaiPlayers += (cyclePosition * 1.5).toInt();
      baseXiuPlayers += (cyclePosition * 1.2).toInt();
    } else {
      baseTaiPool += 15 * 12340;
      baseXiuPool += 15 * 11580;
      baseTaiPlayers += 22;
      baseXiuPlayers += 18;
    }

    // Sinh lịch sử cầu (Bead History) 15 ván trước đồng bộ từ ID phiên cũ
    _beadHistory.clear();
    for (int i = 15; i >= 1; i--) {
      final int pastSession = currentSessionId - i;
      final math_random.Random r = math_random.Random(pastSession);
      final int pd1 = r.nextInt(6) + 1;
      final int pd2 = r.nextInt(6) + 1;
      final int pd3 = r.nextInt(6) + 1;
      _beadHistory.add((pd1 + pd2 + pd3) >= 11);
    }

    // Chỉ tự động đánh giá thắng/thua khi đĩa KHÔNG bị che
    if (calculatedState == "RESULT" && !shouldCoverBowl) {
      if (!_hasEvaluatedRoundBets) {
        _hasEvaluatedRoundBets = true;
        _evaluateBets(total, isTai);
      }
    }

    // Quản lý animation rung đĩa lắc
    if (calculatedState == "ROLLING" && !_shakeController.isAnimating) {
      _shakeController.repeat(reverse: true);
    } else if (calculatedState != "ROLLING" && _shakeController.isAnimating) {
      _shakeController.stop();
    }

    setState(() {
      _sessionId = currentSessionId;
      _gameState = calculatedState;
      _timerSeconds = remainingSeconds;
      _diceResult = currentDiceResult;
      _lastResultText = currentResultText;
      _isBowlCovered = shouldCoverBowl;
      _bowlRevealSeconds = shouldCoverBowl ? (22 - cyclePosition) : 0;
      _taiPool = baseTaiPool;
      _xiuPool = baseXiuPool;
      _taiPlayers = baseTaiPlayers;
      _xiuPlayers = baseXiuPlayers;
    });
  }

  // Cảnh báo hết tiền cược và hướng dẫn nạp thêm tiền
  void _checkAndShowZeroBalanceDialog() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final balance = authService.currentUser?.balance ?? 0;
    
    // Nếu số dư dưới 10 COIN (không đủ mức cược tối thiểu)
    if (balance < 10) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Text(
              "TÀI KHOẢN HẾT SỐ DƯ",
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: const Text(
              "Số dư COIN của bạn đã hết hoặc không đủ hạn mức tối thiểu (10 COIN) để cược. Vui lòng nạp thêm tiền để tiếp tục tham gia cược trò chơi.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("ĐÓNG", style: TextStyle(color: AppColors.textGrey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng truy cập Tab 'Ví tiền' ở thanh menu chân trang để thực hiện nạp thêm COIN."),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text("NẠP COIN"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _revealBowl() async {
    if (!mounted || !_isBowlCovered) return;
    setState(() {
      _isBowlCovered = false;
      _userManuallyRevealed = true;
    });

    // Chỉ thực hiện tính thưởng ngay khi đĩa được mở ra thủ công
    if (!_hasEvaluatedRoundBets) {
      _hasEvaluatedRoundBets = true;
      final int total = _diceResult.reduce((a, b) => a + b);
      final bool isTai = total >= 11 && total <= 17;
      try {
        await _evaluateBets(total, isTai);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi lưu cược: ${e.toString().replaceAll('Exception: ', '')}"),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _evaluateBets(int total, bool isTai) async {
    double totalBet = _myBetOnTai + _myBetOnXiu;
    if (totalBet == 0) return;

    // Sao lưu lượng cược thực tế và reset ngay lập tức để đồng bộ hiển thị số dư tức thời
    final double betTaiSaved = _myBetOnTai;
    final double betXiuSaved = _myBetOnXiu;

    setState(() {
      _myBetOnTai = 0;
      _myBetOnXiu = 0;
    });

    double winAmount = 0;
    String status = "loss";
    String choice = "";

    if (betTaiSaved > 0) {
      choice = "Tài";
      if (isTai) {
        winAmount = betTaiSaved * 2;
        status = "win";
      }
    } else if (betXiuSaved > 0) {
      choice = "Xỉu";
      if (!isTai) {
        winAmount = betXiuSaved * 2;
        status = "win";
      }
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      final bet = BetModel(
        id: '',
        userId: user.uid,
        gameType: 'Tai Xiu',
        detail: 'Tài Xỉu VIP - Phòng 1',
        choice: choice,
        amount: totalBet,
        winAmount: winAmount,
        status: status,
        resultString: _lastResultText,
        timestamp: DateTime.now(),
      );

      try {
        await authService.placeBet(bet);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi lưu cược: ${e.toString().replaceAll('Exception: ', '')}"),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: status == "win" ? AppColors.success : AppColors.danger,
          duration: const Duration(seconds: 3),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == "win" ? Icons.emoji_events_outlined : Icons.sentiment_very_dissatisfied,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                status == "win" 
                    ? "CHIẾN THẮNG! Nhận +${winAmount.toStringAsFixed(0)} COIN" 
                    : "THẤT BẠI! Mất -${totalBet.toStringAsFixed(0)} COIN",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Thay đổi số tiền cược nháp (staged) khi bấm vào chip
  void _stageChipBet(bool onTai) {
    if (_gameState != "BETTING") {
      _showClosedMessage();
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final balance = authService.currentUser?.balance ?? 0;

    // Chặn đặt cược khi số dư ví không đủ 10 COIN
    if (balance < 10) {
      _checkAndShowZeroBalanceDialog();
      return;
    }

    final totalStaged = _stagedBetOnTai + _stagedBetOnXiu + _selectedChip;

    if (balance < totalStaged) {
      _showInsufficientBalance();
      return;
    }

    setState(() {
      if (onTai) {
        _stagedBetOnTai += _selectedChip;
        _stagedBetOnXiu = 0; // Không cược 2 cửa cùng lúc
        _activeBetSide = "TAI";
      } else {
        _stagedBetOnXiu += _selectedChip;
        _stagedBetOnTai = 0;
        _activeBetSide = "XIU";
      }
    });
  }

  // Nhập tiền cược tự do tùy thích
  void _showCustomBetDialog(bool isTai) {
    if (_gameState != "BETTING") {
      _showClosedMessage();
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final balance = authService.currentUser?.balance ?? 0;

    // Chặn cược khi hết số dư
    if (balance < 10) {
      _checkAndShowZeroBalanceDialog();
      return;
    }

    final controller = TextEditingController(
      text: (isTai ? _stagedBetOnTai : _stagedBetOnXiu).toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            isTai ? "NHẬP TIỀN CƯỢC TÀI" : "NHẬP TIỀN CƯỢC XỈU",
            style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nhập số lượng COIN bạn muốn cược vào cửa ${isTai ? 'TÀI' : 'XỈU'} (Tối đa: ${balance.toStringAsFixed(0)} COIN)",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Số tiền cược (COIN)",
                    prefixIcon: Icon(Icons.monetization_on, color: AppColors.goldAccent),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Vui lòng nhập số tiền";
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) return "Số tiền cược không hợp lệ";
                    if (parsed > balance) return "Số dư không đủ";
                    return null;
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final amount = double.parse(controller.text.trim());
                Navigator.of(context).pop();
                setState(() {
                  if (isTai) {
                    _stagedBetOnTai = amount;
                    _stagedBetOnXiu = 0;
                    _activeBetSide = "TAI";
                  } else {
                    _stagedBetOnXiu = amount;
                    _stagedBetOnTai = 0;
                    _activeBetSide = "XIU";
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text("XÁC NHẬN"),
            )
          ],
        );
      },
    );
  }

  // Hủy cược nháp
  void _cancelStagedBets() {
    if (_gameState != "BETTING") return;
    setState(() {
      _stagedBetOnTai = _myBetOnTai;
      _stagedBetOnXiu = _myBetOnXiu;
      _activeBetSide = _myBetOnTai > 0 ? "TAI" : (_myBetOnXiu > 0 ? "XIU" : "");
    });
  }

  // All-In cược
  void _performAllIn() {
    if (_gameState != "BETTING") return;
    if (_activeBetSide == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn cửa cược (Tài hoặc Xỉu) trước khi All-In!"),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final balance = authService.currentUser?.balance ?? 0;

    if (balance < 10) {
      _checkAndShowZeroBalanceDialog();
      return;
    }

    setState(() {
      if (_activeBetSide == "TAI") {
        _stagedBetOnTai = balance;
        _stagedBetOnXiu = 0;
      } else {
        _stagedBetOnXiu = balance;
        _stagedBetOnTai = 0;
      }
    });
  }

  // Đặt cược chốt
  void _confirmBets() {
    if (_gameState != "BETTING") return;
    
    double stagedTotal = _stagedBetOnTai + _stagedBetOnXiu;
    if (stagedTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng cược trước khi xác nhận!"),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _myBetOnTai = _stagedBetOnTai;
      _myBetOnXiu = _stagedBetOnXiu;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đặt cược ${stagedTotal.toStringAsFixed(0)} COIN thành công!"),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showClosedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã đóng cược! Vui lòng chờ ván tiếp theo."),
        backgroundColor: AppColors.danger,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showInsufficientBalance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Số dư không đủ! Vui lòng nạp thêm COIN."),
        backgroundColor: AppColors.danger,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildDiceIcon(int value) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C), // Màu đỏ theo hình mẫu
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Center(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(6),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final Map<int, List<int>> dotMapping = {
              1: [4],
              2: [0, 8],
              3: [0, 4, 8],
              4: [0, 2, 6, 8],
              5: [0, 2, 4, 6, 8],
              6: [0, 2, 3, 5, 6, 8],
            };
            
            bool showDot = dotMapping[value]?.contains(index) ?? false;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showDot ? Colors.white : Colors.transparent, // Nút tròn trắng
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget hiển thị nút Nặn (Squeeze Mode) hình bàn tay (bật: vàng kim, tắt: xám + gạch chéo đỏ)
  Widget _buildSqueezeModeButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSqueezeMode = !_isSqueezeMode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isSqueezeMode ? AppColors.goldAccent : AppColors.borderGrey,
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.pan_tool_outlined,
              color: _isSqueezeMode ? AppColors.goldAccent : AppColors.textGrey,
              size: 20,
            ),
            if (!_isSqueezeMode)
              Transform.rotate(
                angle: -0.8,
                child: Container(
                  width: 24,
                  height: 2.5,
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final double displayBalance = (user?.balance ?? 0) - (_myBetOnTai + _myBetOnXiu);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.goldLight),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: AppColors.goldLight, size: 20),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            const Text(
              "TÀI XỈU",
              style: TextStyle(
                color: AppColors.goldAccent,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.goldLight, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.goldLight, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Ví tiền của người chơi
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.goldAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.goldAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "${displayBalance.toStringAsFixed(0)} COIN",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // BẢNG CƯỢC TÀI XỈU (NÂU ĐẬM, VIỀN VÀNG KÉP)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF231A11),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.goldAccent,
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.show_chart, color: AppColors.goldLight),
                        onPressed: () {},
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "#$_sessionId",
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Tích hợp nút Nặn (Squeeze Mode) hình bàn tay
                      _buildSqueezeModeButton(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    _gameState == "ROLLING" ? "..." : "$_timerSeconds",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: _timerSeconds <= 5 ? AppColors.danger : AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột TÀI (Vàng)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _stageChipBet(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _activeBetSide == "TAI"
                                    ? [const Color(0xFF5E491A), const Color(0xFF382A0F)]
                                    : [const Color(0xFF2A1F16), const Color(0xFF1E1610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _activeBetSide == "TAI" ? AppColors.goldAccent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_outline, color: AppColors.goldLight, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$_taiPlayers",
                                      style: const TextStyle(color: AppColors.goldLight, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "TÀI",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.goldAccent,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _taiPool.toString().replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                                  style: const TextStyle(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Divider(color: Colors.black26, height: 16),
                                Text(
                                  "Đặt: ${_myBetOnTai.toStringAsFixed(0)}",
                                  style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                // Nhấn ô số tiền để tự cược tùy ý
                                GestureDetector(
                                  onTap: () => _showCustomBetDialog(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _stagedBetOnTai.toStringAsFixed(0),
                                      style: const TextStyle(
                                        color: AppColors.goldAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Hộp đĩa giữa lắc xí ngầu (MỞ BÁT)
                      Container(
                        width: 120, // Tăng lên 120 để chứa đĩa cước lớn hơn
                        height: 180,
                        alignment: Alignment.center,
                        child: _gameState == "BETTING"
                            ? const Icon(Icons.hourglass_empty, color: AppColors.goldAccent, size: 36)
                            : _gameState == "ROLLING"
                                ? AnimatedBuilder(
                                    animation: _shakeAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(_shakeAnimation.value, 0),
                                        child: child,
                                      );
                                    },
                                    child: const Icon(Icons.cached, color: AppColors.goldAccent, size: 36),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Hiển thị kết quả xúc xắc nằm dưới đĩa
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildDiceIcon(_diceResult[0]),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildDiceIcon(_diceResult[1]),
                                              const SizedBox(width: 4),
                                              _buildDiceIcon(_diceResult[2]),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      // Kéo thả mở đĩa mọi hướng (Đĩa tăng lên 120 để che phủ hoàn toàn xúc xắc)
                                      if (_isBowlCovered)
                                        GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              _bowlDragX += details.delta.dx;
                                              _bowlDragY += details.delta.dy;
                                            });
                                          },
                                          onPanEnd: (details) {
                                            final double distanceSq = _bowlDragX * _bowlDragX + _bowlDragY * _bowlDragY;
                                            if (distanceSq > 2500) { // Vuốt xa >50px -> Mở bát
                                              _revealBowl();
                                            } else {
                                              setState(() {
                                                _bowlDragX = 0.0;
                                                _bowlDragY = 0.0;
                                              });
                                            }
                                          },
                                          child: Transform.translate(
                                            offset: Offset(_bowlDragX, _bowlDragY),
                                            child: Container(
                                              width: 120, // Tăng kích thước từ 90 thành 120
                                              height: 120, // Tăng kích thước từ 90 thành 120
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFE5A93B), Color(0xFF915905)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.black, width: 2.5),
                                                boxShadow: const [
                                                  BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(3, 3)),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.touch_app, color: Colors.black, size: 28),
                                                  const Text(
                                                    "VUỐT MỞ",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  Text(
                                                    "(${_bowlRevealSeconds}s)",
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                      ),

                      // Cột XỈU (Bạc)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _stageChipBet(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _activeBetSide == "XIU"
                                    ? [const Color(0xFF5E491A), const Color(0xFF382A0F)]
                                    : [const Color(0xFF2A1F16), const Color(0xFF1E1610)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _activeBetSide == "XIU" ? AppColors.goldAccent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_outline, color: Colors.white70, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$_xiuPlayers",
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "XỈU",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _xiuPool.toString().replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Divider(color: Colors.black26, height: 16),
                                Text(
                                  "Đặt: ${_myBetOnXiu.toStringAsFixed(0)}",
                                  style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                // Nhấn để tự gõ cược
                                GestureDetector(
                                  onTap: () => _showCustomBetDialog(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.borderGrey.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _stagedBetOnXiu.toStringAsFixed(0),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Lịch sử cầu
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _beadHistory.map((isTai) {
                        return Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTai ? const Color(0xFF424242) : Colors.white,
                            border: Border.all(
                              color: isTai ? Colors.white24 : Colors.grey,
                              width: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Các chip cược hình vuông viền vàng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [10, 50, 100, 500, 1000, 5000].map((amount) {
                final bool isSelected = _selectedChip == amount;
                final String chipText = amount >= 1000 ? "${(amount / 1000).toStringAsFixed(0)}K" : "$amount";

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChip = amount;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF281E15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.goldAccent : const Color(0xFF5E491A),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: AppColors.goldAccent.withOpacity(0.3), blurRadius: 6),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        chipText,
                        style: TextStyle(
                          color: isSelected ? AppColors.goldAccent : AppColors.goldLight.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Nút All-in, Đặt cược, Hủy cược
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _performAllIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3483),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: const Text(
                      "ALL-IN",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5A93B), Color(0xFF915905)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _confirmBets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        "ĐẶT CƯỢC",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelStagedBets,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: const Text(
                      "HỦY",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
