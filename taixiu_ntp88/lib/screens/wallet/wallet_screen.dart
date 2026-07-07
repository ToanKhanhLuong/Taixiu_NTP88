import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../data/models/transaction_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showTransactionDialog(bool isDeposit) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            isDeposit ? "NẠP COIN" : "RÚT COIN",
            style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDeposit 
                      ? "Nhập số lượng COIN bạn muốn nạp vào tài khoản Macau Prestige của mình."
                      : "Nhập số lượng COIN bạn muốn rút từ tài khoản Macau Prestige của mình.",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Số lượng (COIN)",
                    prefixIcon: Icon(Icons.monetization_on, color: AppColors.goldAccent),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số lượng';
                    }
                    final numVal = double.tryParse(value);
                    if (numVal == null || numVal <= 0) {
                      return 'Vui lòng nhập một số dương hợp lệ';
                    }
                    if (!isDeposit) {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final currentBalance = authService.currentUser?.balance ?? 0.0;
                      if (numVal > currentBalance) {
                        return 'Số dư không đủ (${currentBalance.toStringAsFixed(0)} COIN)';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("HỦY", style: TextStyle(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                
                final amount = double.parse(_amountController.text.trim());
                final authService = Provider.of<AuthService>(context, listen: false);
                
                Navigator.of(context).pop();
                
                if (isDeposit) {
                  await authService.deposit(amount);
                  _showSuccessSnackBar("Đã nạp thành công ${amount.toStringAsFixed(0)} COIN");
                } else {
                  final success = await authService.withdraw(amount);
                  if (success) {
                    _showSuccessSnackBar("Đã rút thành công ${amount.toStringAsFixed(0)} COIN");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDeposit ? AppColors.success : AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
              ),
              child: Text(isDeposit ? "NẠP TIỀN" : "RÚT TIỀN"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTxType(String type) {
    switch (type) {
      case 'deposit': return 'Nạp tiền';
      case 'withdraw': return 'Rút tiền';
      case 'bet_win': return 'Thắng cược';
      case 'bet_loss': return 'Thua cược';
      default: return 'Giao dịch';
    }
  }

  Color _getTxColor(String type) {
    if (type == 'deposit' || type == 'bet_win') {
      return AppColors.success;
    }
    return AppColors.danger;
  }

  String _getTxSign(String type) {
    if (type == 'deposit' || type == 'bet_win') {
      return '+';
    }
    return '-';
  }

  IconData _getTxIcon(String type) {
    switch (type) {
      case 'deposit': return Icons.arrow_downward;
      case 'withdraw': return Icons.arrow_upward;
      case 'bet_win': return Icons.emoji_events;
      default: return Icons.casino;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return 'THÀNH CÔNG';
      case 'pending': return 'ĐANG XỬ LÝ';
      case 'failed': return 'THẤT BẠI';
      default: return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final txList = authService.transactions;
    final balance = user?.balance ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: const Text(
          "MACAU PRESTIGE",
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "${balance.toStringAsFixed(0)} COIN",
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Total Balance Card (Gold Gradient)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldAccent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TỔNG SỐ DƯ",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "VIP ${user?.vipLevel ?? 1}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${balance.toStringAsFixed(0)} COIN",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ID tài khoản: ${user?.idCode ?? '987654321'}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons: DEPOSIT / WITHDRAW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTransactionDialog(true),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text(
                      "NẠP TIỀN",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTransactionDialog(false),
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    label: const Text(
                      "RÚT TIỀN",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Transaction History Label
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "LỊCH SỬ GIAO DỊCH",
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Transactions List
          Expanded(
            child: txList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, color: AppColors.textGrey.withOpacity(0.4), size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          "Chưa có giao dịch nào được ghi lại.",
                          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: txList.length,
                    itemBuilder: (context, index) {
                      final TransactionModel tx = txList[index];
                      
                      return Card(
                        color: AppColors.cardDark,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.borderGrey),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getTxColor(tx.type).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTxIcon(tx.type),
                              color: _getTxColor(tx.type),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            _formatTxType(tx.type),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            "${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year} ${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${_getTxSign(tx.type)}${tx.amount.toStringAsFixed(0)} COIN",
                                style: TextStyle(
                                  color: _getTxColor(tx.type),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _translateStatus(tx.status),
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
