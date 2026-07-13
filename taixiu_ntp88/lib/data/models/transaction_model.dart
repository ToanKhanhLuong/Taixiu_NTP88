import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'deposit' | 'withdraw' | 'bet_win' | 'bet_loss' | 'transfer_out' | 'transfer_in'
  final double amount;
  final String status; // 'completed' | 'pending' | 'failed'
  final DateTime timestamp;
  final String? note;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      if (note != null) 'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    DateTime time;
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      time = DateTime.parse(map['timestamp']);
    } else {
      time = DateTime.now();
    }

    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'completed',
      timestamp: time,
      note: map['note'] as String?,
    );
  }
}
