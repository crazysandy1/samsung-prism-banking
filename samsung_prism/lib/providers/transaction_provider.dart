import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'balance_provider.dart';

enum TransactionType { 
  // Outgoing transactions
  sent, 
  withdrawal, 
  billPayment,
  onlinePurchase,
  atmWithdrawal,
  bankCharges,
  
  // Incoming transactions  
  received, 
  deposit, 
  salaryDeposit,
  interest,
  refund,
  cashback,
  
  // Internal transactions
  accountTransfer,
  investmentPurchase,
  investmentRedemption,
}

enum TransactionStatus {
  pending,
  processing, 
  completed,
  failed,
  cancelled,
  reversed
}

enum TransactionCategory {
  transfer,
  payment,
  deposit,
  withdrawal,
  investment,
  salary,
  bills,
  shopping,
  entertainment,
  food,
  transport,
  healthcare,
  education,
  other
}

class Transaction {
  final String id;
  final double amount;
  final String description;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionStatus status;
  final TransactionCategory category;
  final String? recipientAccount;
  final String? recipientName;
  final String? recipientBank;
  final String? referenceNumber;
  final String? upiId;
  final double? balanceAfter;
  final double? charges;
  final String? location;
  final Map<String, dynamic>? metadata;
  
  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.status,
    required this.category,
    this.recipientAccount,
    this.recipientName,
    this.recipientBank,
    this.referenceNumber,
    this.upiId,
    this.balanceAfter,
    this.charges,
    this.location,
    this.metadata,
  });
  
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.sent,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.completed,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TransactionCategory.transfer,
      ),
      recipientAccount: data['recipientAccount'],
      recipientName: data['recipientName'],
      recipientBank: data['recipientBank'],
      referenceNumber: data['referenceNumber'],
      upiId: data['upiId'],
      balanceAfter: data['balanceAfter']?.toDouble(),
      charges: data['charges']?.toDouble(),
      location: data['location'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
      'status': status.name,
      'category': category.name,
      'recipientAccount': recipientAccount,
      'recipientName': recipientName,
      'recipientBank': recipientBank,
      'referenceNumber': referenceNumber,
      'upiId': upiId,
      'balanceAfter': balanceAfter,
      'charges': charges,
      'location': location,
      'metadata': metadata,
    };
  }

  bool get isIncoming => [
    TransactionType.received,
    TransactionType.deposit,
    TransactionType.salaryDeposit,
    TransactionType.interest,
    TransactionType.refund,
    TransactionType.cashback,
  ].contains(type);

  bool get isOutgoing => [
    TransactionType.sent,
    TransactionType.withdrawal,
    TransactionType.billPayment,
    TransactionType.onlinePurchase,
    TransactionType.atmWithdrawal,
    TransactionType.bankCharges,
    TransactionType.investmentPurchase,
  ].contains(type);

  String get formattedAmount {
    final prefix = isOutgoing ? '-' : '+';
    return '$prefix₹${amount.toStringAsFixed(2)}';
  }

  String get statusDisplay {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.reversed:
        return 'Reversed';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.processing:
        return Colors.blue;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
      case TransactionStatus.reversed:
        return Colors.purple;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case TransactionCategory.transfer:
        return Icons.swap_horiz;
      case TransactionCategory.payment:
        return Icons.payment;
      case TransactionCategory.deposit:
        return Icons.account_balance_wallet;
      case TransactionCategory.withdrawal:
        return Icons.money_off;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.bills:
        return Icons.receipt;
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.transport:
        return Icons.directions_bus;
      case TransactionCategory.healthcare:
        return Icons.local_hospital;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.other:
        return Icons.more_horiz;
    }
  }
}

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  BalanceProvider? _balanceProvider;
  
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Add a method to get recent transactions count for debugging
  int get transactionCount => _transactions.length;
  
  /// Set balance provider for real-time balance updates
  void setBalanceProvider(BalanceProvider balanceProvider) {
    _balanceProvider = balanceProvider;
    print('BalanceProvider connection established successfully');
  }
  
  Future<void> fetchTransactions() async {
    try {
      _setLoading(true);
      _clearError();
      final User? user = _auth.currentUser;
      
      if (user == null) {
        _setError('No user logged in');
        _setLoading(false);
        return;
      }

      print('Fetching transactions for user: ${user.uid}');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      print('Found ${snapshot.docs.length} transaction documents');
      
      // Convert to Transaction objects and sort in memory to avoid composite index requirement
      var transactions = snapshot.docs
          .map((doc) {
            try {
              return Transaction.fromFirestore(doc);
            } catch (e) {
              print('Error parsing transaction ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Transaction>()
          .toList();
      
      // Sort by timestamp descending
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit
      if (transactions.length > 50) {
        transactions = transactions.take(50).toList();
      }
      
      _transactions = transactions;
      print('Successfully loaded ${transactions.length} transactions');
      
      _setLoading(false);
    } catch (e) {
      print('Error fetching transactions: $e');
      _setError('Failed to fetch transactions: $e');
      _setLoading(false);
    }
  }
  
  /// Add a new transaction with proper balance calculation and realistic banking features
  Future<String?> addBankingTransaction({
    required double amount,
    required String description,
    required TransactionType type,
    required TransactionCategory category,
    String? recipientAccount,
    String? recipientName,
    String? recipientBank,
    String? upiId,
    double? charges,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        _setError('No user logged in');
        return null;
      }
      
      // Generate transaction reference number
      final referenceNumber = _generateReferenceNumber();
      
      // Get current balance
      final balanceProvider = await _getCurrentBalance(user.uid);
      final currentBalance = balanceProvider ?? 0.0;
      
      // Calculate balance after transaction
      final balanceAfter = _calculateBalanceAfter(currentBalance, amount, type);
      
      // Create transaction data
      final transactionData = {
        'userId': user.uid,
        'amount': amount,
        'description': description,
        'type': type.name,
        'status': TransactionStatus.completed.name,
        'category': category.name,
        'recipientAccount': recipientAccount,
        'recipientName': recipientName,
        'recipientBank': recipientBank,
        'referenceNumber': referenceNumber,
        'upiId': upiId,
        'balanceAfter': balanceAfter,
        'charges': charges,
        'location': location,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      print('Adding enhanced transaction: amount=$amount, type=${type.name}, balance_after=$balanceAfter');
      
      // Add transaction to Firestore
      await _firestore.collection('transactions').add(transactionData);
      
      // Update user balance
      await _firestore.collection('users').doc(user.uid).update({
        'balance': balanceAfter,
        'lastTransactionTime': FieldValue.serverTimestamp(),
      });
      
      print('Enhanced transaction added successfully with reference: $referenceNumber');
      
      // Update balance provider immediately for real-time UI updates
      if (_balanceProvider != null) {
        print('Triggering balance refresh after transaction...');
        await _balanceProvider!.forceRefreshBalance();
        print('Balance refresh completed');
      } else {
        print('Warning: BalanceProvider not set, balance won\'t update automatically');
      }
      
      // Refresh transactions
      await fetchTransactions();
      return referenceNumber;
      
    } catch (e) {
      print('Error adding enhanced transaction: $e');
      _setError('Failed to add transaction: $e');
      return null;
    }
  }

  /// Legacy method for backward compatibility
  Future<bool> addTransaction({
    required double amount,
    required String description,
    required TransactionType type,
    String? recipientAccount,
    String? recipientName,
  }) async {
    final category = _mapTypeToCategory(type);
    final referenceNumber = await addBankingTransaction(
      amount: amount,
      description: description,
      type: type,
      category: category,
      recipientAccount: recipientAccount,
      recipientName: recipientName,
    );
    return referenceNumber != null;
  }

  /// Generate realistic bank reference number
  String _generateReferenceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 999999;
    return 'TXN${timestamp.toString().substring(7)}${random.toString().padLeft(6, '0')}';
  }

  /// Get current balance from user document
  Future<double?> _getCurrentBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return (data['balance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting current balance: $e');
      return null;
    }
  }

  /// Calculate balance after transaction
  double _calculateBalanceAfter(double currentBalance, double amount, TransactionType type) {
    final transaction = Transaction(
      id: '',
      amount: amount,
      description: '',
      timestamp: DateTime.now(),
      type: type,
      status: TransactionStatus.completed,
      category: TransactionCategory.transfer,
    );
    
    if (transaction.isOutgoing) {
      return currentBalance - amount;
    } else {
      return currentBalance + amount;
    }
  }

  /// Map transaction type to category
  TransactionCategory _mapTypeToCategory(TransactionType type) {
    switch (type) {
      case TransactionType.sent:
      case TransactionType.received:
        return TransactionCategory.transfer;
      case TransactionType.billPayment:
        return TransactionCategory.bills;
      case TransactionType.onlinePurchase:
        return TransactionCategory.shopping;
      case TransactionType.salaryDeposit:
        return TransactionCategory.salary;
      case TransactionType.atmWithdrawal:
      case TransactionType.withdrawal:
        return TransactionCategory.withdrawal;
      case TransactionType.deposit:
        return TransactionCategory.deposit;
      default:
        return TransactionCategory.other;
    }
  }
  
  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }
  
  double getTotalAmountByType(TransactionType type) {
    return _transactions
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  List<Transaction> getRecentTransactions(int count) {
    return _transactions.take(count).toList();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Generate realistic sample transactions for testing
  Future<void> generateRealisticSampleTransactions() async {
    final sampleTransactions = [
      // Salary deposit
      {
        'amount': 85000.0,
        'description': 'Monthly Salary - March 2025',
        'type': TransactionType.salaryDeposit,
        'category': TransactionCategory.salary,
        'location': 'Mumbai, Maharashtra',
      },
      
      // Bill payments
      {
        'amount': 2850.0,
        'description': 'Electricity Bill - MSEB',
        'type': TransactionType.billPayment,
        'category': TransactionCategory.bills,
        'recipientName': 'Maharashtra State Electricity Board',
      },
      {
        'amount': 1200.0,
        'description': 'Mobile Recharge - Airtel',
        'type': TransactionType.billPayment,
        'category': TransactionCategory.bills,
        'recipientName': 'Bharti Airtel Limited',
      },
      
      // Online purchases
      {
        'amount': 3499.0,
        'description': 'Amazon Purchase - Electronics',
        'type': TransactionType.onlinePurchase,
        'category': TransactionCategory.shopping,
        'recipientName': 'Amazon Pay India',
        'metadata': {'merchant_category': 'electronics', 'order_id': 'AMZ2025039485'},
      },
      {
        'amount': 899.0,
        'description': 'Zomato Food Order',
        'type': TransactionType.onlinePurchase,
        'category': TransactionCategory.food,
        'recipientName': 'Zomato Limited',
        'location': 'Bangalore, Karnataka',
      },
      
      // ATM withdrawal
      {
        'amount': 5000.0,
        'description': 'ATM Cash Withdrawal',
        'type': TransactionType.atmWithdrawal,
        'category': TransactionCategory.withdrawal,
        'location': 'Koramangala, Bangalore',
        'charges': 20.0,
        'metadata': {'atm_id': 'HDFC0002845', 'card_last4': '4729'},
      },
      
      // UPI transfers
      {
        'amount': 500.0,
        'description': 'UPI Transfer to Friend',
        'type': TransactionType.sent,
        'category': TransactionCategory.transfer,
        'recipientName': 'Arjun Kumar',
        'upiId': 'arjunkumar@paytm',
      },
      
      // Investment
      {
        'amount': 10000.0,
        'description': 'SIP - HDFC Equity Fund',
        'type': TransactionType.investmentPurchase,
        'category': TransactionCategory.investment,
        'recipientName': 'HDFC Asset Management',
        'metadata': {'folio_number': 'HDFC123456789', 'nav': '245.67'},
      },
      
      // Refund
      {
        'amount': 1299.0,
        'description': 'Flipkart Order Refund',
        'type': TransactionType.refund,
        'category': TransactionCategory.shopping,
        'recipientName': 'Flipkart Internet Pvt Ltd',
        'metadata': {'original_order': 'FKT987654321', 'refund_reason': 'item_damaged'},
      },
      
      // Transport
      {
        'amount': 180.0,
        'description': 'Uber Ride - Home to Office',
        'type': TransactionType.onlinePurchase,
        'category': TransactionCategory.transport,
        'recipientName': 'Uber India Systems',
        'location': 'Bangalore, Karnataka',
      },
      
      // Bank charges
      {
        'amount': 150.0,
        'description': 'Monthly Account Maintenance Charges',
        'type': TransactionType.bankCharges,
        'category': TransactionCategory.other,
        'recipientName': 'Samsung Prism Bank',
      },
      
      // Interest credit
      {
        'amount': 423.50,
        'description': 'Interest Credited - Savings Account',
        'type': TransactionType.interest,
        'category': TransactionCategory.deposit,
        'metadata': {'interest_rate': '4.5%', 'period': 'Mar 2025'},
      },
    ];

    for (int i = 0; i < sampleTransactions.length; i++) {
      final transaction = sampleTransactions[i];
      
      await addBankingTransaction(
        amount: transaction['amount'] as double,
        description: transaction['description'] as String,
        type: transaction['type'] as TransactionType,
        category: transaction['category'] as TransactionCategory,
        recipientName: transaction['recipientName'] as String?,
        upiId: transaction['upiId'] as String?,
        charges: transaction['charges'] as double?,
        location: transaction['location'] as String?,
        metadata: transaction['metadata'] as Map<String, dynamic>?,
      );
      
      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Get transactions by category
  List<Transaction> getTransactionsByCategory(TransactionCategory category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  /// Get transactions by status
  List<Transaction> getTransactionsByStatus(TransactionStatus status) {
    return _transactions.where((t) => t.status == status).toList();
  }

  /// Calculate total spent in a category for current month
  double getMonthlySpendingByCategory(TransactionCategory category) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _transactions
        .where((t) => 
          t.category == category && 
          t.isOutgoing && 
          t.timestamp.isAfter(startOfMonth) &&
          t.status == TransactionStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get spending insights for dashboard
  Map<String, dynamic> getSpendingInsights() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final completedTransactions = _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();
    
    final monthlyIncome = completedTransactions
        .where((t) => t.isIncoming && t.timestamp.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyExpenses = completedTransactions
        .where((t) => t.isOutgoing && t.timestamp.isAfter(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final categorySpending = <TransactionCategory, double>{};
    for (final category in TransactionCategory.values) {
      categorySpending[category] = getMonthlySpendingByCategory(category);
    }
    
    return {
      'monthly_income': monthlyIncome,
      'monthly_expenses': monthlyExpenses,
      'net_savings': monthlyIncome - monthlyExpenses,
      'category_spending': categorySpending,
      'total_transactions': completedTransactions.length,
      'pending_transactions': getTransactionsByStatus(TransactionStatus.pending).length,
    };
  }
}
