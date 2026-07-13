import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database/firebase_service.dart';
import '../models/user_model.dart';
import 'friend_repository.dart';

class PrivateChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  PrivateChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory PrivateChatMessage.fromMap(Map<String, dynamic> map) {
    DateTime time;
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      time = DateTime.parse(map['timestamp']);
    } else {
      time = DateTime.now();
    }
    return PrivateChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Người chơi',
      message: map['message'] ?? '',
      timestamp: time,
    );
  }
}

class PrivateChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory read tracking and notifier triggers
  static final Map<String, DateTime> _lastReadTimes = {};
  static final Map<String, bool> _mockRoomUnread = {};
  static final StreamController<void> _readTrigger = StreamController<void>.broadcast();

  // Mark room as read
  void markAsRead(String currentUid, String friendUid) {
    final roomId = getRoomId(currentUid, friendUid);
    _lastReadTimes[roomId] = DateTime.now();
    _mockRoomUnread[roomId] = false;
    _readTrigger.add(null);
  }

  // Stream if there are any unread messages for the current user
  Stream<bool> streamHasUnreadMessages(String currentUid) {
    if (currentUid.isEmpty) return Stream.value(false);
    final controller = StreamController<bool>();
    StreamSubscription? firestoreSub;
    StreamSubscription? triggerSub;

    void checkAndEmit(List<DocumentSnapshot> docs) {
      bool hasUnread = false;
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final roomId = doc.id;
        final lastSenderId = data['lastSenderId'] as String?;
        final timestamp = data['lastTimestamp'] as Timestamp?;

        if (lastSenderId != null && lastSenderId != currentUid && timestamp != null) {
          final lastRead = _lastReadTimes[roomId];
          if (lastRead == null || timestamp.toDate().isAfter(lastRead)) {
            hasUnread = true;
            break;
          }
        }
      }
      if (!controller.isClosed) {
        controller.add(hasUnread);
      }
    }

    if (!FirebaseService.isInitialized) {
      return _streamMockHasUnread(currentUid);
    }

    final roomsQuery = _firestore
        .collection('private_chats')
        .where('uids', arrayContains: currentUid);

    List<DocumentSnapshot> currentDocs = [];

    firestoreSub = roomsQuery.snapshots().listen((snapshot) {
      currentDocs = snapshot.docs;
      checkAndEmit(currentDocs);
    });

    triggerSub = _readTrigger.stream.listen((_) {
      checkAndEmit(currentDocs);
    });

    controller.onCancel = () {
      firestoreSub?.cancel();
      triggerSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // Stream if a specific friend has sent an unread message to us
  Stream<bool> streamFriendHasUnread(String currentUid, String friendUid) {
    if (currentUid.isEmpty || friendUid.isEmpty) return Stream.value(false);
    final roomId = getRoomId(currentUid, friendUid);

    if (!FirebaseService.isInitialized) {
      final controller = StreamController<bool>();
      void emitStatus() {
        if (!controller.isClosed) {
          controller.add(_mockRoomUnread[roomId] ?? false);
        }
      }
      emitStatus();
      final sub = _readTrigger.stream.listen((_) => emitStatus());
      controller.onCancel = () {
        sub.cancel();
        controller.close();
      };
      return controller.stream;
    }

    return _firestore
        .collection('private_chats')
        .doc(roomId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return false;
      final lastSenderId = data['lastSenderId'] as String?;
      final timestamp = data['lastTimestamp'] as Timestamp?;
      if (lastSenderId != null && lastSenderId != currentUid && timestamp != null) {
        final lastRead = _lastReadTimes[roomId];
        return lastRead == null || timestamp.toDate().isAfter(lastRead);
      }
      return false;
    });
  }

  // Stream mock unread status
  Stream<bool> _streamMockHasUnread(String currentUid) {
    final controller = StreamController<bool>();
    void emitStatus() {
      final hasUnread = _mockRoomUnread.values.any((unread) => unread);
      if (!controller.isClosed) controller.add(hasUnread);
    }
    emitStatus();
    final sub = _readTrigger.stream.listen((_) => emitStatus());
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };
    return controller.stream;
  }

  // Generate a deterministic room ID
  String getRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // Stream private messages in real-time (last 50 messages)
  Stream<List<PrivateChatMessage>> streamMessages(String currentUid, String friendUid) {
    if (!FirebaseService.isInitialized) {
      return _streamMockMessages(currentUid, friendUid);
    }
    final roomId = getRoomId(currentUid, friendUid);
    return _firestore
        .collection('private_chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PrivateChatMessage.fromMap(data);
      }).toList();
      return list.reversed.toList();
    });
  }

  // Send message
  Future<void> sendMessage({
    required String currentUid,
    required String friendUid,
    required String senderName,
    required String message,
  }) async {
    if (!FirebaseService.isInitialized) {
      _saveMockMessage(currentUid, friendUid, senderName, message);
      return;
    }
    final roomId = getRoomId(currentUid, friendUid);
    final docRef = _firestore
        .collection('private_chats')
        .doc(roomId)
        .collection('messages')
        .doc();

    final msg = PrivateChatMessage(
      id: docRef.id,
      senderId: currentUid,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(docRef, msg.toMap());
    
    final roomRef = _firestore.collection('private_chats').doc(roomId);
    batch.set(roomRef, {
      'lastMessage': message,
      'lastSenderId': currentUid,
      'lastSenderName': senderName,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'uids': [currentUid, friendUid],
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // --- Mock implementation for Preview mode ---
  static final Map<String, List<PrivateChatMessage>> _mockRoomMessages = {};
  static final Map<String, StreamController<List<PrivateChatMessage>>> _mockControllers = {};

  Stream<List<PrivateChatMessage>> _streamMockMessages(String currentUid, String friendUid) {
    final roomId = getRoomId(currentUid, friendUid);
    if (!_mockRoomMessages.containsKey(roomId)) {
      _mockRoomMessages[roomId] = [
        PrivateChatMessage(
          id: 'm1',
          senderId: friendUid,
          senderName: 'Bạn bè',
          message: 'Chào bạn nhé! Hôm nay tài xỉu cầu đẹp lắm.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        PrivateChatMessage(
          id: 'm2',
          senderId: currentUid,
          senderName: 'Tôi',
          message: 'Uầy, thế hả bạn? Để tí tớ vào chiến.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        PrivateChatMessage(
          id: 'm3',
          senderId: friendUid,
          senderName: 'Bạn bè',
          message: 'Ừa, tranh thủ cược đi nha!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ];
    }

    if (!_mockControllers.containsKey(roomId)) {
      _mockControllers[roomId] = StreamController<List<PrivateChatMessage>>.broadcast();
    }

    final controller = StreamController<List<PrivateChatMessage>>();
    controller.add(List.from(_mockRoomMessages[roomId]!));

    final sub = _mockControllers[roomId]!.stream.listen((data) {
      if (!controller.isClosed) controller.add(List.from(data));
    });

    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  void _saveMockMessage(String currentUid, String friendUid, String senderName, String message) {
    final roomId = getRoomId(currentUid, friendUid);
    final msg = PrivateChatMessage(
      id: 'mock_msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUid,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
    );

    if (!_mockRoomMessages.containsKey(roomId)) {
      _mockRoomMessages[roomId] = [];
    }
    _mockRoomMessages[roomId]!.add(msg);
    if (_mockRoomMessages[roomId]!.length > 30) {
      _mockRoomMessages[roomId]!.removeAt(0);
    }

    if (!_mockControllers.containsKey(roomId)) {
      _mockControllers[roomId] = StreamController<List<PrivateChatMessage>>.broadcast();
    }
    _mockControllers[roomId]!.add(List.from(_mockRoomMessages[roomId]!));

    // Simulate auto-reply
    Future.delayed(const Duration(seconds: 1), () {
      final replyMsg = PrivateChatMessage(
        id: 'mock_reply_${DateTime.now().millisecondsSinceEpoch}',
        senderId: friendUid,
        senderName: friendUid == 'mock_friend_1' ? 'Nguyễn Khánh' : (friendUid == 'mock_friend_2' ? 'Trần Hải' : 'Bạn bè'),
        message: _getRandomReply(),
        timestamp: DateTime.now(),
      );
      _mockRoomMessages[roomId]!.add(replyMsg);
      if (_mockRoomMessages[roomId]!.length > 30) {
        _mockRoomMessages[roomId]!.removeAt(0);
      }
      _mockRoomUnread[roomId] = true;
      _readTrigger.add(null);
      _mockControllers[roomId]!.add(List.from(_mockRoomMessages[roomId]!));
    });
  }

  String _getRandomReply() {
    final replies = [
      'Ok nha bạn ơi!',
      'Tí nữa rảnh làm vài ván tài xỉu chung nhé.',
      'Chúc bạn gặp nhiều may mắn nha!',
      'Hôm nay bạn quay vòng quay tỉ phú trúng giải gì chưa?',
      'Chơi vui vẻ nhé!',
    ];
    return replies[math.Random().nextInt(replies.length)];
  }

  // Stream a combined list of all unread/pending notifications
  Stream<List<Map<String, dynamic>>> streamAllNotifications(String currentUid, UserModel? user) {
    if (currentUid.isEmpty) return Stream.value([]);
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    StreamSubscription? reqSub;
    StreamSubscription? chatSub;
    
    List<Map<String, dynamic>> requestsList = [];
    List<Map<String, dynamic>> chatsList = [];
    
    void emitCombined() {
      final List<Map<String, dynamic>> combined = [];
      
      // 1. Add reward notification if user has unclaimed bonuses
      if (user != null) {
        final hasUnclaimed = user.unclaimedFirstDepositBonus > 0 || 
                       user.unclaimedVipLevelRewards > 0 || 
                       user.unclaimedRebate > 0;
        if (hasUnclaimed) {
          combined.add({
            'id': 'reward_bonus',
            'title': 'Nhận thưởng ưu đãi',
            'body': 'Bạn có phần thưởng khuyến mãi chưa nhận',
            'type': 'reward',
            'timestamp': DateTime.now(),
          });
        }
      }
      
      // 2. Add friend requests notifications
      for (final req in requestsList) {
        if (req['type'] == 'received') {
          combined.add({
            'id': 'req_${req['uid']}',
            'title': 'Lời mời kết bạn',
            'body': 'Bạn nhận được lời mời kết bạn từ ${req['fullName']}',
            'type': 'friend_request',
            'timestamp': req['timestamp'] as DateTime? ?? DateTime.now(),
            'payload': req,
          });
        }
      }
      
      // 3. Add private chat notifications
      for (final chat in chatsList) {
        combined.add({
          'id': 'chat_${chat['roomId']}',
          'title': 'Tin nhắn riêng',
          'body': 'Bạn có tin nhắn mới từ ${chat['senderName']}',
          'type': 'private_chat',
          'timestamp': chat['timestamp'] as DateTime? ?? DateTime.now(),
          'payload': chat['friendUid'],
        });
      }
      
      // Sort by timestamp descending
      combined.sort((a, b) {
        final DateTime tA = a['timestamp'];
        final DateTime tB = b['timestamp'];
        return tB.compareTo(tA);
      });
      
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }
    
    // Stream 1: Friend requests
    reqSub = FriendRepository().streamFriendRequests(currentUid).listen((reqs) {
      requestsList = reqs;
      emitCombined();
    });
    
    // Stream 2: Private chats
    if (!FirebaseService.isInitialized) {
      void checkMockChats() {
        chatsList = [];
        _mockRoomUnread.forEach((roomId, unread) {
          if (unread) {
            final parts = roomId.split('_');
            final friendUid = parts[0] == currentUid ? parts[1] : parts[0];
            final friendName = friendUid == 'mock_friend_1' ? 'Nguyễn Khánh' : (friendUid == 'mock_friend_2' ? 'Trần Hải' : 'Bạn bè');
            chatsList.add({
              'roomId': roomId,
              'senderName': friendName,
              'friendUid': friendUid,
              'timestamp': DateTime.now(),
            });
          }
        });
        emitCombined();
      }
      
      checkMockChats();
      chatSub = _readTrigger.stream.listen((_) {
        checkMockChats();
      });
    } else {
      chatSub = _firestore
          .collection('private_chats')
          .where('uids', arrayContains: currentUid)
          .snapshots()
          .listen((snapshot) {
        chatsList = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final roomId = doc.id;
          final lastSenderId = data['lastSenderId'] as String?;
          final lastSenderName = data['lastSenderName'] as String? ?? 'Bạn bè';
          final timestamp = data['lastTimestamp'] as Timestamp?;
          
          if (lastSenderId != null && lastSenderId != currentUid && timestamp != null) {
            final lastRead = _lastReadTimes[roomId];
            if (lastRead == null || timestamp.toDate().isAfter(lastRead)) {
              final parts = roomId.split('_');
              final friendUid = parts[0] == currentUid ? parts[1] : parts[0];
              chatsList.add({
                'roomId': roomId,
                'senderName': lastSenderName,
                'friendUid': friendUid,
                'timestamp': timestamp.toDate(),
              });
            }
          }
        }
        emitCombined();
      });
    }
    
    controller.onCancel = () {
      reqSub?.cancel();
      chatSub?.cancel();
      controller.close();
    };
    
    return controller.stream;
  }
}
