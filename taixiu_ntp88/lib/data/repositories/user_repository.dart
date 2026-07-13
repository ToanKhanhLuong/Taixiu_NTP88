import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../services/database/firebase_service.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lắng nghe dữ liệu người dùng thay đổi theo thời gian thực (để cập nhật số dư tức thời)
  Stream<UserModel?> streamUser(String uid) {
    if (!FirebaseService.isInitialized) {
      return Stream.value(null);
    }
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Lấy dữ liệu người dùng một lần
  Future<UserModel?> getUser(String uid) async {
    if (!FirebaseService.isInitialized) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Tạo tài khoản người dùng mới trên Firestore
  Future<void> createUser(UserModel user) async {
    if (!FirebaseService.isInitialized) return;
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // Cập nhật số dư tài khoản một cách nguyên tử (Atomic Update)
  Future<void> updateBalanceAtomic(String uid, double amount) async {
    if (!FirebaseService.isInitialized) return;
    
    // Sử dụng FieldValue.increment để đảm bảo tính nguyên tử (tránh race condition khi cược/nạp/rút cùng lúc)
    await _firestore.collection('users').doc(uid).update({
      'balance': FieldValue.increment(amount),
    });
  }

  // Cập nhật số dư cược đồng thời cộng dồn hoàn trả
  Future<void> updateBalanceAndRebateAtomic(String uid, double balanceChange, double rebateChange) async {
    if (!FirebaseService.isInitialized) return;
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Không tìm thấy thông tin tài khoản!");
      
      final data = snapshot.data()!;
      final double currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      final double currentRebate = (data['unclaimedRebate'] as num?)?.toDouble() ?? 0.0;
      
      transaction.update(docRef, {
        'balance': currentBalance + balanceChange,
        'unclaimedRebate': currentRebate + rebateChange,
      });
    });
  }

  // Ghi nhận giao dịch nạp tiền một cách nguyên tử (Cập nhật Balance, TotalDeposited, vipLevel, và các trường tích lũy thưởng)
  Future<void> recordDepositAtomic(String uid, double amount) async {
    if (!FirebaseService.isInitialized) return;

    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Không tìm thấy thông tin tài khoản!");

      final data = snapshot.data()!;
      final double currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      final double currentTotalDeposited = (data['totalDeposited'] as num?)?.toDouble() ?? 0.0;
      final int currentVip = (data['vipLevel'] as num?)?.toInt() ?? 0;
      
      final double currentUnclaimedFirstDeposit = (data['unclaimedFirstDepositBonus'] as num?)?.toDouble() ?? 0.0;
      final double currentUnclaimedVipRewards = (data['unclaimedVipLevelRewards'] as num?)?.toDouble() ?? 0.0;

      final double newTotalDeposited = currentTotalDeposited + amount;
      final int newVipLevel = UserModel.calculateVipLevel(newTotalDeposited);

      // 1. Tính thưởng nạp đầu: nạp >= 50 khi chưa từng nạp (totalDeposited == 0)
      double promoBonus = 0.0;
      if (currentTotalDeposited == 0.0 && amount >= 50.0) {
        promoBonus += 40.0;
      }

      // 2. Tính thưởng lên VIP
      double vipReward = 0.0;
      for (int v = currentVip + 1; v <= newVipLevel; v++) {
        if (v >= 1 && v <= 6) {
          vipReward += 50 * math.pow(2, v - 1);
        }
      }

      // Số dư chỉ tăng theo số tiền thực nạp. Các khoản thưởng tích lũy vào ví nhận thưởng
      final double newBalance = currentBalance + amount;

      transaction.update(docRef, {
        'balance': newBalance,
        'totalDeposited': newTotalDeposited,
        'vipLevel': newVipLevel,
        'unclaimedFirstDepositBonus': currentUnclaimedFirstDeposit + promoBonus,
        'unclaimedVipLevelRewards': currentUnclaimedVipRewards + vipReward,
      });
    });
  }

  // Nhận thưởng nạp đầu
  Future<void> claimFirstDepositBonus(String uid) async {
    if (!FirebaseService.isInitialized) return;
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Không tìm thấy thông tin tài khoản!");
      
      final data = snapshot.data()!;
      final double unclaimed = (data['unclaimedFirstDepositBonus'] as num?)?.toDouble() ?? 0.0;
      if (unclaimed <= 0) throw Exception("Không có phần thưởng nạp đầu để nhận!");
      
      final double currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      transaction.update(docRef, {
        'balance': currentBalance + unclaimed,
        'unclaimedFirstDepositBonus': 0.0,
      });
    });
  }

  // Nhận thưởng thăng cấp VIP
  Future<void> claimVipLevelRewards(String uid) async {
    if (!FirebaseService.isInitialized) return;
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Không tìm thấy thông tin tài khoản!");
      
      final data = snapshot.data()!;
      final double unclaimed = (data['unclaimedVipLevelRewards'] as num?)?.toDouble() ?? 0.0;
      if (unclaimed <= 0) throw Exception("Không có phần thưởng thăng cấp VIP để nhận!");

      final double currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      transaction.update(docRef, {
        'balance': currentBalance + unclaimed,
        'unclaimedVipLevelRewards': 0.0,
      });
    });
  }

  // Nhận hoàn trả VIP
  Future<void> claimRebate(String uid) async {
    if (!FirebaseService.isInitialized) return;
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Không tìm thấy thông tin tài khoản!");
      
      final data = snapshot.data()!;
      final double unclaimed = (data['unclaimedRebate'] as num?)?.toDouble() ?? 0.0;
      if (unclaimed <= 0) throw Exception("Không có tiền hoàn trả để nhận!");

      final double currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      transaction.update(docRef, {
        'balance': currentBalance + unclaimed,
        'unclaimedRebate': 0.0,
      });
    });
  }

  // Điểm danh nhận thưởng nguyên tử (Atomic Check-in)
  Future<void> claimCheckInAtomic(String uid, double rewardAmount, DateTime checkInTime) async {
    if (!FirebaseService.isInitialized) return;
    final docRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Không tìm thấy thông tin tài khoản!");

      final data = snapshot.data()!;
      DateTime? lastTime;
      if (data['lastCheckInTime'] != null) {
        if (data['lastCheckInTime'] is Timestamp) {
          lastTime = (data['lastCheckInTime'] as Timestamp).toDate();
        } else if (data['lastCheckInTime'] is String) {
          lastTime = DateTime.tryParse(data['lastCheckInTime']);
        }
      }

      if (lastTime != null) {
        final diff = checkInTime.difference(lastTime);
        if (diff.inHours < 5) {
          final hoursLeft = 5 - diff.inHours;
          final minutesLeft = 60 - (diff.inMinutes % 60);
          throw Exception("Vui lòng đợi thêm $hoursLeft giờ $minutesLeft phút để tiếp tục điểm danh.");
        }
      }

      final double currentBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      
      transaction.update(docRef, {
        'balance': currentBalance + rewardAmount,
        'lastCheckInTime': Timestamp.fromDate(checkInTime),
      });
    });
  }


  // Cập nhật ảnh đại diện (Avatar)
  Future<void> updateAvatar(String uid, String avatarUrl) async {
    if (!FirebaseService.isInitialized) return;
    await _firestore.collection('users').doc(uid).update({
      'avatarUrl': avatarUrl,
    });
  }

  // Chuyển coin giữa hai người dùng (Atomic Transaction)
  Future<void> transferCoin({
    required String senderUid,
    required String receiverUid,
    required double amount,
  }) async {
    if (!FirebaseService.isInitialized) return;
    if (amount <= 0) throw Exception("Số coin chuyển phải lớn hơn 0!");

    final senderRef = _firestore.collection('users').doc(senderUid);
    final receiverRef = _firestore.collection('users').doc(receiverUid);

    await _firestore.runTransaction((transaction) async {
      final senderSnap = await transaction.get(senderRef);
      final receiverSnap = await transaction.get(receiverRef);

      if (!senderSnap.exists) throw Exception("Không tìm thấy tài khoản người gửi!");
      if (!receiverSnap.exists) throw Exception("Không tìm thấy tài khoản người nhận!");

      final senderBalance = (senderSnap.data()!['balance'] as num?)?.toDouble() ?? 0.0;
      if (senderBalance < amount) {
        throw Exception("Số dư không đủ để chuyển!");
      }

      transaction.update(senderRef, {
        'balance': senderBalance - amount,
      });

      final receiverBalance = (receiverSnap.data()!['balance'] as num?)?.toDouble() ?? 0.0;
      transaction.update(receiverRef, {
        'balance': receiverBalance + amount,
      });
    });
  }
}
