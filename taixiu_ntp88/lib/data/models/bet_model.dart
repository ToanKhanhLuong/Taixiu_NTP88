import 'package:cloud_firestore/cloud_firestore.dart';

class BetModel {
  final String id;
  final String userId;
  final String gameType; // 'Tai Xiu' | 'Casino' | 'Football Bets'
  final String detail; // e.g., 'Tai Xiu Room 1'
  final String choice; // 'Tài' | 'Xỉu' | etc.
  final double amount;
  final double winAmount; // positive for win, 0 for loss
  final String status; // 'win' | 'loss' | 'pending'
  final String resultString; // e.g., 'Tài (5, 6, 4) = 15'
  final DateTime timestamp;

  BetModel({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.detail,
    required this.choice,
    required this.amount,
    required this.winAmount,
    required this.status,
    required this.resultString,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'gameType': gameType,
      'detail': detail,
      'choice': choice,
      'amount': amount,
      'winAmount': winAmount,
      'status': status,
      'resultString': resultString,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory BetModel.fromMap(Map<String, dynamic> map) {
    DateTime time;
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      time = DateTime.parse(map['timestamp']);
    } else {
      time = DateTime.now();
    }

    return BetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      gameType: map['gameType'] ?? 'Tai Xiu',
      detail: map['detail'] ?? '',
      choice: map['choice'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      winAmount: (map['winAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      resultString: map['resultString'] ?? '',
      timestamp: time,
    );
  }
}
