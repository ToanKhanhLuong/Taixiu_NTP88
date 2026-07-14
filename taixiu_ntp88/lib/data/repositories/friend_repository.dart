import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database/firebase_service.dart';
import '../models/user_model.dart';

class FriendRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Static properties for Preview/Mock mode
  static final List<UserModel> _mockFriends = [];
  static final List<Map<String, dynamic>> _mockRequests = [];

  static final _friendsController = StreamController<List<UserModel>>.broadcast();
  static final _requestsController = StreamController<List<Map<String, dynamic>>>.broadcast();

  static void _initMockData() {
    if (_mockFriends.isEmpty && _mockRequests.isEmpty) {
      _mockFriends.addAll([
        UserModel(
          uid: 'mock_friend_1',
          fullName: 'Nguyễn Khánh',
          username: 'khanhn',
          email: 'khanhn@gmail.com',
          phoneNumber: '0912345678',
          balance: 2000.0,
          vipLevel: 3,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: '111222333',
        ),
        UserModel(
          uid: 'mock_friend_2',
          fullName: 'Trần Hải',
          username: 'haitr',
          email: 'haitr@gmail.com',
          phoneNumber: '0987654321',
          balance: 1500.0,
          vipLevel: 2,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: '444555666',
        ),
      ]);

      _mockRequests.addAll([
        {
          'uid': 'mock_friend_3',
          'fullName': 'Phạm Bình',
          'username': 'binhp',
          'email': 'binhp@gmail.com',
          'phoneNumber': '0933445566',
          'vipLevel': 1,
          'avatarUrl': 'assets/images/dragon_avatar.png',
          'idCode': '777888999',
          'type': 'received',
          'timestamp': DateTime.now(),
        },
        {
          'uid': 'mock_friend_4',
          'fullName': 'Lê Hoa',
          'username': 'hoale',
          'email': 'hoale@gmail.com',
          'phoneNumber': '0922889900',
          'vipLevel': 0,
          'avatarUrl': 'assets/images/dragon_avatar.png',
          'idCode': '123123123',
          'type': 'sent',
          'timestamp': DateTime.now(),
        }
      ]);
      _friendsController.add(_mockFriends);
      _requestsController.add(_mockRequests);
    }
  }

  // Stream active friends list
  Stream<List<UserModel>> streamFriends(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    if (!FirebaseService.isInitialized) {
      _initMockData();
      final controller = StreamController<List<UserModel>>();
      controller.add(List.from(_mockFriends));

      final sub = _friendsController.stream.listen((data) {
        if (!controller.isClosed) controller.add(List.from(data));
      });

      controller.onCancel = () {
        sub.cancel();
        controller.close();
      };

      return controller.stream;
    }

    final controller = StreamController<List<UserModel>>();
    StreamSubscription? friendsSub;
    final Map<String, StreamSubscription> userSubs = {};
    final Map<String, UserModel> friendProfiles = {};

    void emitProfiles() {
      if (controller.isClosed) return;
      controller.add(friendProfiles.values.toList());
    }

    friendsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .listen((friendsSnapshot) {
      final currentFriendUids = friendsSnapshot.docs.map((d) => d.id).toSet();

      // Clean up subscriptions for removed friends
      final removedUids = userSubs.keys.where((id) => !currentFriendUids.contains(id)).toList();
      for (final id in removedUids) {
        userSubs[id]?.cancel();
        userSubs.remove(id);
        friendProfiles.remove(id);
      }

      if (currentFriendUids.isEmpty) {
        emitProfiles();
        return;
      }

      // Add subscriptions for new friends
      for (final friendUid in currentFriendUids) {
        if (!userSubs.containsKey(friendUid)) {
          final userSub = _firestore
              .collection('users')
              .doc(friendUid)
              .snapshots()
              .listen((userDoc) {
            if (userDoc.exists && userDoc.data() != null) {
              friendProfiles[friendUid] = UserModel.fromMap(userDoc.data()!);
            }
            emitProfiles();
          }, onError: (e) {
            debugPrint("Error listening to friend $friendUid profile: $e");
          });
          userSubs[friendUid] = userSub;
        }
      }
    }, onError: (err) {
      if (!controller.isClosed) controller.addError(err);
    });

    controller.onCancel = () {
      friendsSub?.cancel();
      for (final sub in userSubs.values) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  // Stream pending incoming and outgoing requests
  Stream<List<Map<String, dynamic>>> streamFriendRequests(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    if (!FirebaseService.isInitialized) {
      _initMockData();
      final controller = StreamController<List<Map<String, dynamic>>>();
      controller.add(List.from(_mockRequests));

      final sub = _requestsController.stream.listen((data) {
        if (!controller.isClosed) controller.add(List.from(data));
      });

      controller.onCancel = () {
        sub.cancel();
        controller.close();
      };

      return controller.stream;
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('friend_requests')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': data['uid'],
          'fullName': data['fullName'],
          'username': data['username'],
          'avatarUrl': data['avatarUrl'],
          'idCode': data['idCode'],
          'vipLevel': data['vipLevel'] ?? 0,
          'type': data['type'],
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  // Stream if there is any pending incoming friend request
  Stream<bool> streamHasIncomingRequests(String uid) {
    if (uid.isEmpty) return Stream.value(false);
    return streamFriendRequests(uid).map((list) {
      return list.any((req) => req['type'] == 'received');
    });
  }

  // Find friend by UID
  Future<UserModel?> findFriendByUid(String currentUid, String friendUid) async {
    if (!FirebaseService.isInitialized) {
      _initMockData();
      try {
        return _mockFriends.firstWhere((f) => f.uid == friendUid);
      } catch (_) {
        return null;
      }
    }
    final doc = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .doc(friendUid)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    // Fallback: search main users collection
    final mainDoc = await _firestore.collection('users').doc(friendUid).get();
    if (mainDoc.exists) {
      return UserModel.fromMap(mainDoc.data()!);
    }
    return null;
  }

  // Find user by unique 9-digit idCode
  Future<UserModel?> findUserByIdCode(String idCode) async {
    if (!FirebaseService.isInitialized) {
      _initMockData();
      final allMockUsers = [
        UserModel(
          uid: 'mock_search_1',
          fullName: 'Vũ Nam',
          username: 'namvu',
          email: 'namvu@gmail.com',
          phoneNumber: '0977889900',
          balance: 5000.0,
          vipLevel: 4,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: '999999999',
        ),
        UserModel(
          uid: 'mock_search_2',
          fullName: 'Đỗ Tiến',
          username: 'tiendo',
          email: 'tiendo@gmail.com',
          phoneNumber: '0966554433',
          balance: 100.0,
          vipLevel: 0,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: '888888888',
        ),
        ..._mockFriends,
        UserModel(
          uid: 'mock_friend_3',
          fullName: 'Phạm Bình',
          username: 'binhp',
          email: 'binhp@gmail.com',
          phoneNumber: '0933445566',
          balance: 500.0,
          vipLevel: 1,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: '777888999',
        ),
        UserModel(
          uid: 'mock_friend_4',
          fullName: 'Lê Hoa',
          username: 'hoale',
          email: 'hoale@gmail.com',
          phoneNumber: '0922889900',
          balance: 300.0,
          vipLevel: 0,
          avatarUrl: 'assets/images/dragon_avatar.png',
          idCode: '123123123',
        ),
      ];
      try {
        return allMockUsers.firstWhere((u) => u.idCode == idCode);
      } catch (_) {
        return null;
      }
    }

    final query = await _firestore
        .collection('users')
        .where('idCode', isEqualTo: idCode)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // Send friend request
  Future<void> sendFriendRequest(UserModel currentUser, UserModel targetUser) async {
    if (FirebaseService.isInitialized) {
      final batch = _firestore.batch();

      final sentRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .doc(targetUser.uid);

      final receivedRef = _firestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('friend_requests')
          .doc(currentUser.uid);

      batch.set(sentRef, {
        'uid': targetUser.uid,
        'fullName': targetUser.fullName,
        'username': targetUser.username,
        'avatarUrl': targetUser.avatarUrl,
        'idCode': targetUser.idCode,
        'vipLevel': targetUser.vipLevel,
        'type': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.set(receivedRef, {
        'uid': currentUser.uid,
        'fullName': currentUser.fullName,
        'username': currentUser.username,
        'avatarUrl': currentUser.avatarUrl,
        'idCode': currentUser.idCode,
        'vipLevel': currentUser.vipLevel,
        'type': 'received',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } else {
      _initMockData();
      if (!_mockRequests.any((r) => r['uid'] == targetUser.uid)) {
        _mockRequests.add({
          'uid': targetUser.uid,
          'fullName': targetUser.fullName,
          'username': targetUser.username,
          'avatarUrl': targetUser.avatarUrl,
          'idCode': targetUser.idCode,
          'type': 'sent',
          'timestamp': DateTime.now(),
        });
        _requestsController.add(List.from(_mockRequests));
      }
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(UserModel currentUser, UserModel targetUser) async {
    if (FirebaseService.isInitialized) {
      final batch = _firestore.batch();

      final req1 = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .doc(targetUser.uid);
      final req2 = _firestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('friend_requests')
          .doc(currentUser.uid);
      batch.delete(req1);
      batch.delete(req2);

      final friend1 = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(targetUser.uid);
      final friend2 = _firestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('friends')
          .doc(currentUser.uid);

      batch.set(friend1, {
        'uid': targetUser.uid,
        'fullName': targetUser.fullName,
        'username': targetUser.username,
        'avatarUrl': targetUser.avatarUrl,
        'idCode': targetUser.idCode,
        'vipLevel': targetUser.vipLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.set(friend2, {
        'uid': currentUser.uid,
        'fullName': currentUser.fullName,
        'username': currentUser.username,
        'avatarUrl': currentUser.avatarUrl,
        'idCode': currentUser.idCode,
        'vipLevel': currentUser.vipLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } else {
      _initMockData();
      _mockRequests.removeWhere((r) => r['uid'] == targetUser.uid);
      _requestsController.add(List.from(_mockRequests));

      if (!_mockFriends.any((f) => f.uid == targetUser.uid)) {
        _mockFriends.add(targetUser);
        _friendsController.add(List.from(_mockFriends));
      }
    }
  }

  // Decline/Cancel friend request
  Future<void> declineFriendRequest(String currentUid, String targetUid) async {
    if (FirebaseService.isInitialized) {
      final batch = _firestore.batch();
      final req1 = _firestore
          .collection('users')
          .doc(currentUid)
          .collection('friend_requests')
          .doc(targetUid);
      final req2 = _firestore
          .collection('users')
          .doc(targetUid)
          .collection('friend_requests')
          .doc(currentUid);
      batch.delete(req1);
      batch.delete(req2);
      await batch.commit();
    } else {
      _initMockData();
      _mockRequests.removeWhere((r) => r['uid'] == targetUid);
      _requestsController.add(List.from(_mockRequests));
    }
  }

  // Unfriend
  Future<void> unfriend(String currentUid, String friendUid) async {
    if (FirebaseService.isInitialized) {
      final batch = _firestore.batch();
      final f1 = _firestore
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(friendUid);
      final f2 = _firestore
          .collection('users')
          .doc(friendUid)
          .collection('friends')
          .doc(currentUid);
      batch.delete(f1);
      batch.delete(f2);
      await batch.commit();
    } else {
      _initMockData();
      _mockFriends.removeWhere((f) => f.uid == friendUid);
      _friendsController.add(List.from(_mockFriends));
    }
  }
}
