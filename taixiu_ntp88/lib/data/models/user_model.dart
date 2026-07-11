class UserModel {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final double balance;
  final double totalDeposited;
  final int vipLevel;
  final String avatarUrl;
  final String idCode;
  
  // Unclaimed promotional balances
  final double unclaimedFirstDepositBonus;
  final double unclaimedVipLevelRewards;
  final double unclaimedRebate;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.balance = 1000.0, // Default signup balance
    this.totalDeposited = 0.0,
    this.vipLevel = 0,
    this.avatarUrl = 'assets/images/dragon_avatar.png',
    required this.idCode,
    this.unclaimedFirstDepositBonus = 0.0,
    this.unclaimedVipLevelRewards = 0.0,
    this.unclaimedRebate = 0.0,
  });

  static int calculateVipLevel(double totalDeposited) {
    if (totalDeposited < 1000) return 0;
    if (totalDeposited < 5000) return 1;
    if (totalDeposited < 10000) return 2;
    if (totalDeposited < 15000) return 3;
    if (totalDeposited < 20000) return 4;
    if (totalDeposited < 25000) return 5;
    return 6;
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    double? balance,
    double? totalDeposited,
    int? vipLevel,
    String? avatarUrl,
    String? idCode,
    double? unclaimedFirstDepositBonus,
    double? unclaimedVipLevelRewards,
    double? unclaimedRebate,
  }) {
    final newTotalDeposited = totalDeposited ?? this.totalDeposited;
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      balance: balance ?? this.balance,
      totalDeposited: newTotalDeposited,
      vipLevel: vipLevel ?? (totalDeposited != null ? calculateVipLevel(newTotalDeposited) : this.vipLevel),
      avatarUrl: avatarUrl ?? this.avatarUrl,
      idCode: idCode ?? this.idCode,
      unclaimedFirstDepositBonus: unclaimedFirstDepositBonus ?? this.unclaimedFirstDepositBonus,
      unclaimedVipLevelRewards: unclaimedVipLevelRewards ?? this.unclaimedVipLevelRewards,
      unclaimedRebate: unclaimedRebate ?? this.unclaimedRebate,
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
      'totalDeposited': totalDeposited,
      'vipLevel': vipLevel,
      'avatarUrl': avatarUrl,
      'idCode': idCode,
      'unclaimedFirstDepositBonus': unclaimedFirstDepositBonus,
      'unclaimedVipLevelRewards': unclaimedVipLevelRewards,
      'unclaimedRebate': unclaimedRebate,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final double totalDepositedVal = (map['totalDeposited'] as num?)?.toDouble() ?? 0.0;
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      totalDeposited: totalDepositedVal,
      vipLevel: (map['vipLevel'] as num?)?.toInt() ?? calculateVipLevel(totalDepositedVal),
      avatarUrl: map['avatarUrl'] ?? 'assets/images/dragon_avatar.png',
      idCode: map['idCode'] ?? '',
      unclaimedFirstDepositBonus: (map['unclaimedFirstDepositBonus'] as num?)?.toDouble() ?? 0.0,
      unclaimedVipLevelRewards: (map['unclaimedVipLevelRewards'] as num?)?.toDouble() ?? 0.0,
      unclaimedRebate: (map['unclaimedRebate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
