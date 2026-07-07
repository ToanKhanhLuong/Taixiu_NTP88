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

  // Cập nhật ảnh đại diện (Avatar)
  Future<void> updateAvatar(String uid, String avatarUrl) async {
    if (!FirebaseService.isInitialized) return;
    await _firestore.collection('users').doc(uid).update({
      'avatarUrl': avatarUrl,
    });
  }
}
