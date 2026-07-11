import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database/firebase_service.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final int vipLevel;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.vipLevel,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'vipLevel': vipLevel,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    DateTime time;
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      time = DateTime.parse(map['timestamp']);
    } else {
      time = DateTime.now();
    }
    return ChatMessage(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Người chơi',
      vipLevel: map['vipLevel'] ?? 0,
      message: map['message'] ?? '',
      timestamp: time,
    );
  }
}

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lắng nghe real-time 30 tin nhắn mới nhất
  Stream<List<ChatMessage>> streamMessages() {
    if (!FirebaseService.isInitialized) {
      return Stream.value([]);
    }
    return _firestore
        .collection('game_chat')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ChatMessage.fromMap(data);
          })
          .toList();
      // Đảo ngược danh sách để hiển thị tin nhắn cũ hơn ở trên, tin mới ở dưới
      return list.reversed.toList();
    });
  }

  // Gửi tin nhắn mới lên Firestore
  Future<void> sendMessage({
    required String userId,
    required String username,
    required int vipLevel,
    required String message,
  }) async {
    if (!FirebaseService.isInitialized) return;
    
    final docRef = _firestore.collection('game_chat').doc();
    final msg = ChatMessage(
      id: docRef.id,
      userId: userId,
      username: username,
      vipLevel: vipLevel,
      message: message,
      timestamp: DateTime.now(),
    );
    
    await docRef.set(msg.toMap());
  }
}
