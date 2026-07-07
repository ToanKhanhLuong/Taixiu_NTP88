class UserModel {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final double balance;
  final int vipLevel;
  final String avatarUrl;
  final String idCode;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.balance = 1000.0, // Default signup balance
    this.vipLevel = 1,
    this.avatarUrl = 'assets/images/dragon_avatar.png',
    required this.idCode,
  });

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    double? balance,
    int? vipLevel,
    String? avatarUrl,
    String? idCode,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      balance: balance ?? this.balance,
      vipLevel: vipLevel ?? this.vipLevel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      idCode: idCode ?? this.idCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'balance': balance,
      'vipLevel': vipLevel,
      'avatarUrl': avatarUrl,
      'idCode': idCode,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      vipLevel: (map['vipLevel'] as num?)?.toInt() ?? 1,
      avatarUrl: map['avatarUrl'] ?? 'assets/images/dragon_avatar.png',
      idCode: map['idCode'] ?? '',
    );
  }
}
