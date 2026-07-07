import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/bet_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/bet_repository.dart';
import 'database/firebase_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Khai báo các Repositories cho Clean Architecture
  final UserRepository _userRepo = UserRepository();
  final BetRepository _betRepo = BetRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  
  // Danh sách lưu trữ real-time phục vụ giao diện
  List<TransactionModel> _transactions = [];
  List<BetModel> _bets = [];

  // Quản lý các StreamSubscription để tránh rò rỉ bộ nhớ (memory leaks)
  StreamSubscription<UserModel?>? _userSub;
  StreamSubscription<List<BetModel>>? _betsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _txsSub;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  List<TransactionModel> get transactions => _transactions;
  List<BetModel> get bets => _bets;
  bool get isFirebaseActive => FirebaseService.isInitialized;

  // Dữ liệu giả lập (Preview Mode) khi Firebase chưa kết nối
  final Map<String, UserModel> _mockUsers = {};
  final List<TransactionModel> _mockTransactions = [];
  final List<BetModel> _mockBets = [];

  AuthService() {
    _initAuthListener();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  void _cancelSubscriptions() {
    _userSub?.cancel();
    _betsSub?.cancel();
    _txsSub?.cancel();
  }

  void _initAuthListener() {
    if (isFirebaseActive) {
      _auth.authStateChanges().listen((User? firebaseUser) async {
        _cancelSubscriptions();
        if (firebaseUser != null) {
          // Lắng nghe thông tin người dùng & số dư thay đổi real-time từ UserRepository
          _userSub = _userRepo.streamUser(firebaseUser.uid).listen((user) {
            _currentUser = user;
            notifyListeners();
          });
          
          // Lắng nghe lịch sử cược real-time từ BetRepository
          _betsSub = _betRepo.streamBetHistory(firebaseUser.uid).listen((betsList) {
            _bets = betsList;
            notifyListeners();
          });

          // Lắng nghe lịch sử giao dịch real-time
          _listenToTransactions(firebaseUser.uid);
        } else {
          _currentUser = null;
          _transactions = [];
          _bets = [];
          notifyListeners();
        }
      });
    } else {
      _setupMockUser();
    }
  }

  void _setupMockUser() {
    final mockUser = UserModel(
      uid: 'mock_uid_123',
      fullName: 'Lương Toàn',
      username: 'toanlk04',
      email: 'toanlk04@gmail.com',
      phoneNumber: '0337868199',
      balance: 6870.0,
      vipLevel: 1,
      avatarUrl: 'assets/images/dragon_avatar.png',
      idCode: '621099131',
    );
    _mockUsers[mockUser.email] = mockUser;
    _mockUsers[mockUser.username] = mockUser;
    
    // Thêm các giao dịch giả lập
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx_1',
        userId: mockUser.uid,
        type: 'deposit',
        amount: 5000.0,
        status: 'completed',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: 'tx_2',
        userId: mockUser.uid,
        type: 'withdraw',
        amount: 200.0,
        status: 'completed',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Thêm các cược giả lập
    _mockBets.addAll([
      BetModel(
        id: 'bet_1',
        userId: mockUser.uid,
        gameType: 'Tai Xiu',
        detail: 'Tài Xỉu VIP - Phòng 1',
        choice: 'Tài',
        amount: 100.0,
        winAmount: 200.0,
        status: 'win',
        resultString: 'Tài (5, 4, 6) = 15',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      BetModel(
        id: 'bet_2',
        userId: mockUser.uid,
        gameType: 'Tai Xiu',
        detail: 'Tài Xỉu VIP - Phòng 1',
        choice: 'Xỉu',
        amount: 50.0,
        winAmount: 0.0,
        status: 'loss',
        resultString: 'Tài (4, 5, 3) = 12',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  void _listenToTransactions(String uid) {
    _txsSub = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      final txList = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
      txList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _transactions = txList;
      notifyListeners();
    });
  }

  // --- Core Methods ---

  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isFirebaseActive) {
        String email = emailOrUsername;
        if (!emailOrUsername.contains('@')) {
          final query = await _firestore
              .collection('users')
              .where('username', isEqualTo: emailOrUsername)
              .limit(1)
              .get()
              .timeout(
                const Duration(seconds: 8),
                onTimeout: () => throw TimeoutException('Kết nối máy chủ Firestore quá hạn. Vui lòng kiểm tra mạng.'),
              );
          if (query.docs.isEmpty) {
            throw Exception('Tên đăng nhập không tồn tại');
          }
          email = query.docs.first.data()['email'];
        }

        UserCredential creds = await _auth
            .signInWithEmailAndPassword(
              email: email,
              password: password,
            )
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Kết nối đăng nhập quá hạn. Vui lòng thử lại.'),
            );
        
        final userProfile = await _userRepo.getUser(creds.user!.uid).timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Không thể tải hồ sơ người dùng. Vui lòng thử lại.'),
            );
        _currentUser = userProfile;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (_mockUsers.containsKey(emailOrUsername)) {
          final user = _mockUsers[emailOrUsername]!;
          _currentUser = user;
          _transactions = List.from(_mockTransactions.where((t) => t.userId == user.uid));
          _bets = List.from(_mockBets.where((b) => b.userId == user.uid));
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception('Tên đăng nhập hoặc mật khẩu không đúng');
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isFirebaseActive) {
        // 1. Kiểm tra username tồn tại
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get()
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Kiểm tra tên đăng nhập quá hạn. Vui lòng thử lại.'),
            );
        if (usernameQuery.docs.isNotEmpty) {
          throw Exception('Tên đăng nhập đã được sử dụng');
        }

        // 2. Tạo tài khoản trong Firebase Authentication
        UserCredential creds = await _auth
            .createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Tạo tài khoản quá hạn. Vui lòng thử lại.'),
            );

        final String uid = creds.user!.uid;
        final String idCode = (100000000 + (uid.hashCode % 900000000)).toString();

        // 3. Khởi tạo Profile người dùng với 1000 coin trong tài khoản
        final newUser = UserModel(
          uid: uid,
          fullName: fullName,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          balance: 1000.0, // Mỗi tài khoản mới nhận được 1000 COIN
          vipLevel: 1,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: idCode,
        );

        await _userRepo.createUser(newUser).timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('Tạo hồ sơ dữ liệu quá hạn. Vui lòng thử lại.'),
            );
        _currentUser = newUser;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (_mockUsers.containsKey(email) || _mockUsers.containsKey(username)) {
          throw Exception('Email hoặc Tên đăng nhập đã được đăng ký');
        }

        final String uid = 'mock_uid_${DateTime.now().millisecondsSinceEpoch}';
        final String idCode = (100000000 + (uid.hashCode % 900000000)).toString();
        
        final newUser = UserModel(
          uid: uid,
          fullName: fullName,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          balance: 1000.0, // Nhận 1000 COIN cho tài khoản Mock
          vipLevel: 1,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: idCode,
        );

        _mockUsers[email] = newUser;
        _mockUsers[username] = newUser;
        _currentUser = newUser;
        
        _transactions = [];
        _bets = [];

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _cancelSubscriptions();
    if (isFirebaseActive) {
      await _auth.signOut();
    } else {
      _currentUser = null;
      _transactions = [];
      _bets = [];
      notifyListeners();
    }
  }

  Future<void> deposit(double amount) async {
    if (_currentUser == null) return;
    
    if (isFirebaseActive) {
      // 1. Cập nhật số dư trước (critical)
      try {
        await _userRepo.updateBalanceAtomic(_currentUser!.uid, amount);
      } catch (e) {
        debugPrint("CRITICAL ERROR: Failed to update balance in deposit: $e");
        rethrow;
      }

      // 2. Ghi nhật ký giao dịch (phụ) - không chặn cập nhật số dư
      try {
        final txRef = _firestore.collection('transactions').doc();
        final tx = TransactionModel(
          id: txRef.id,
          userId: _currentUser!.uid,
          type: 'deposit',
          amount: amount,
          status: 'completed',
          timestamp: DateTime.now(),
        );
        await _firestore.collection('transactions').doc(txRef.id).set(tx.toMap());
      } catch (e) {
        debugPrint("WARNING: Failed to log deposit transaction: $e");
      }
    } else {
      // Mock Deposit
      final newBalance = _currentUser!.balance + amount;
      final tx = TransactionModel(
        id: 'tx_mock_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.uid,
        type: 'deposit',
        amount: amount,
        status: 'completed',
        timestamp: DateTime.now(),
      );
      _mockTransactions.add(tx);
      _transactions.insert(0, tx);
      _currentUser = _currentUser!.copyWith(balance: newBalance);
      notifyListeners();
    }
  }

  Future<bool> withdraw(double amount) async {
    if (_currentUser == null || _currentUser!.balance < amount) return false;

    if (isFirebaseActive) {
      // 1. Cập nhật giảm số dư trước (critical)
      try {
        await _userRepo.updateBalanceAtomic(_currentUser!.uid, -amount);
      } catch (e) {
        debugPrint("CRITICAL ERROR: Failed to update balance in withdraw: $e");
        rethrow;
      }

      // 2. Ghi nhật ký giao dịch (phụ) - không chặn cập nhật số dư
      try {
        final txRef = _firestore.collection('transactions').doc();
        final tx = TransactionModel(
          id: txRef.id,
          userId: _currentUser!.uid,
          type: 'withdraw',
          amount: amount,
          status: 'completed',
          timestamp: DateTime.now(),
        );
        await _firestore.collection('transactions').doc(txRef.id).set(tx.toMap());
      } catch (e) {
        debugPrint("WARNING: Failed to log withdraw transaction: $e");
      }
      return true;
    } else {
      // Mock Withdraw
      final newBalance = _currentUser!.balance - amount;
      final tx = TransactionModel(
        id: 'tx_mock_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.uid,
        type: 'withdraw',
        amount: amount,
        status: 'completed',
        timestamp: DateTime.now(),
      );
      _mockTransactions.add(tx);
      _transactions.insert(0, tx);
      _currentUser = _currentUser!.copyWith(balance: newBalance);
      notifyListeners();
      return true;
    }
  }

  Future<void> placeBet(BetModel bet) async {
    if (_currentUser == null) return;
    
    // Cược thắng sẽ được + (winAmount - amount) vào ví, cược thua bị trừ (amount)
    // Tổng số lượng thay đổi số dư thực tế:
    final double netChange = -bet.amount + bet.winAmount;

    if (isFirebaseActive) {
      // 1. Cập nhật số dư trước (critical)
      try {
        await _userRepo.updateBalanceAtomic(_currentUser!.uid, netChange);
      } catch (e) {
        debugPrint("CRITICAL ERROR: Failed to update balance in placeBet: $e");
        rethrow;
      }

      // 2. Thêm bản ghi cược vào collection 'bet_history' (phụ)
      try {
        await _betRepo.addBet(bet);
      } catch (e) {
        debugPrint("WARNING: Failed to log bet to bet_history: $e");
      }
      
      // 3. Ghi chép nhật ký giao dịch tài chính (phụ)
      try {
        final txRef = _firestore.collection('transactions').doc();
        final tx = TransactionModel(
          id: txRef.id,
          userId: _currentUser!.uid,
          type: bet.winAmount > 0 ? 'bet_win' : 'bet_loss',
          amount: bet.winAmount > 0 ? bet.winAmount : bet.amount,
          status: 'completed',
          timestamp: DateTime.now(),
        );
        await _firestore.collection('transactions').doc(txRef.id).set(tx.toMap());
      } catch (e) {
        debugPrint("WARNING: Failed to log transaction in placeBet: $e");
      }
    } else {
      // Mock Bet
      final newBalance = _currentUser!.balance + netChange;
      final completeBet = BetModel(
        id: 'bet_mock_${DateTime.now().millisecondsSinceEpoch}',
        userId: bet.userId,
        gameType: bet.gameType,
        detail: bet.detail,
        choice: bet.choice,
        amount: bet.amount,
        winAmount: bet.winAmount,
        status: bet.status,
        resultString: bet.resultString,
        timestamp: bet.timestamp,
      );
      
      _mockBets.add(completeBet);
      _bets.insert(0, completeBet);
      
      final tx = TransactionModel(
        id: 'tx_mock_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.uid,
        type: bet.winAmount > 0 ? 'bet_win' : 'bet_loss',
        amount: bet.winAmount > 0 ? bet.winAmount : bet.amount,
        status: 'completed',
        timestamp: DateTime.now(),
      );
      _mockTransactions.add(tx);
      _transactions.insert(0, tx);
      
      _currentUser = _currentUser!.copyWith(balance: newBalance);
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? fullName, String? phoneNumber}) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
    );

    if (isFirebaseActive) {
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      
      await _firestore.collection('users').doc(_currentUser!.uid).update(updates);
      _currentUser = updatedUser;
    } else {
      _currentUser = updatedUser;
    }
    notifyListeners();
  }

  // Cập nhật ảnh đại diện (Avatar)
  Future<void> updateAvatar(String avatarUrl) async {
    if (_currentUser == null) return;
    if (isFirebaseActive) {
      await _userRepo.updateAvatar(_currentUser!.uid, avatarUrl);
    } else {
      _currentUser = _currentUser!.copyWith(avatarUrl: avatarUrl);
      notifyListeners();
    }
  }

  // Đổi mật khẩu tài khoản qua Firebase Auth
  Future<void> changePassword(String newPassword) async {
    if (isFirebaseActive) {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception("Người dùng chưa đăng nhập hệ thống.");
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
