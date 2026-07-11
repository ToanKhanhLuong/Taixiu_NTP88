import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bet_model.dart';
import '../../services/database/firebase_service.dart';

class BetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lắng nghe lịch sử cược theo thời gian thực từ Firestore collection 'bet_history'
  Stream<List<BetModel>> streamBetHistory(String uid) {
    if (!FirebaseService.isInitialized) {
      return Stream.value([]);
    }
    return _firestore
        .collection('bet_history')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Đảm bảo id của document được đưa vào model
            data['id'] = doc.id;
            return BetModel.fromMap(data);
          })
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list.take(100).toList();
    });
  }

  // Thêm một bản ghi cược mới vào Firestore collection 'bet_history'
  Future<void> addBet(BetModel bet) async {
    if (!FirebaseService.isInitialized) return;
    
    final docRef = _firestore.collection('bet_history').doc();
    final Map<String, dynamic> data = bet.toMap();
    data['id'] = docRef.id; // Gắn ID document tự sinh vào map dữ liệu
    
    await docRef.set(data);
  }
}
