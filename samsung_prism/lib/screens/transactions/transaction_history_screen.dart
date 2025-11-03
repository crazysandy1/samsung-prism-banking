import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/balance_provider.dart';
import '../../utils/app_colors.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.fetchTransactions();
  }

  void _addTestTransaction() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Try to get balance provider for real-time updates
    try {
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      transactionProvider.setBalanceProvider(balanceProvider);
    } catch (e) {
      // Balance provider might not be available in this context
      print('Balance provider not available: $e');
    }
    
    try {
      // Generate realistic banking sample transactions
      await transactionProvider.generateRealisticSampleTransactions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Realistic banking transactions generated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating transactions: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addTestTransaction,
            tooltip: 'Add Test Transactions',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTransactions(),
                _buildTransactionsByType(TransactionType.sent),
                _buildTransactionsByType(TransactionType.received),
                _buildTransactionsByStatus(TransactionStatus.pending),
                _buildTopCategories(),
                _buildAnalytics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final sentTotal = transactionProvider.getTotalAmountByType(TransactionType.sent);
        final receivedTotal = transactionProvider.getTotalAmountByType(TransactionType.received);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sent',
                  '\$${sentTotal.toStringAsFixed(2)}',
                  Icons.arrow_upward,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Received',
                  '\$${receivedTotal.toStringAsFixed(2)}',
                  Icons.arrow_downward,
                  AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primaryBlue,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Sent'),
          Tab(text: 'Received'),
          Tab(text: 'Pending'),
          Tab(text: 'Categories'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildAllTransactions() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (transactionProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transactionProvider.errorMessage!,
                    style: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      transactionProvider.clearError();
                      _loadTransactions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = transactionProvider.transactions;

        if (transactions.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => _loadTransactions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionsByType(TransactionType type) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (transactionProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      transactionProvider.clearError();
                      _loadTransactions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = transactionProvider.getTransactionsByType(type);

        if (transactions.isEmpty) {
          return _buildEmptyState(
            message: 'No ${type.name} transactions found',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadTransactions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final isReceived = transaction.isIncoming;
    
    // Get color based on transaction status
    Color statusColor = _getStatusColor(transaction.status);
    Color categoryColor = _getCategoryColor(transaction.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            width: 4,
            color: categoryColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main transaction row
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getCategoryIcon(transaction.category),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.description,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusDisplayText(transaction.status),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Recipient/Category info
                      Row(
                        children: [
                          if (transaction.recipientName != null)
                            Expanded(
                              child: Text(
                                isReceived ? 'From ${transaction.recipientName}' : 'To ${transaction.recipientName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (transaction.recipientName != null) const SizedBox(width: 8),
                          Text(
                            transaction.category.name.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Date and reference
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateFormat.format(transaction.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          if (transaction.referenceNumber != null)
                            Text(
                              'Ref: ${transaction.referenceNumber}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount and balance section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isReceived ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: isReceived ? AppColors.success : AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                    if (transaction.balanceAfter != null)
                      Text(
                        'Bal: ₹${transaction.balanceAfter!.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Transaction type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTransactionTypeColor(transaction.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTransactionTypeDisplayText(transaction.type),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getTransactionTypeColor(transaction.type),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Additional info row (charges, location, UPI)
            if (transaction.charges != null || 
                transaction.location != null || 
                transaction.upiId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (transaction.charges != null) ...[
                      Icon(Icons.account_balance_wallet, size: 12, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        'Charges: ₹${transaction.charges!.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                    if (transaction.charges != null && 
                        (transaction.location != null || transaction.upiId != null))
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('•', style: TextStyle(color: Colors.grey)),
                      ),
                    if (transaction.location != null) ...[
                      Icon(Icons.location_on, size: 12, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          transaction.location!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (transaction.upiId != null) ...[
                      if (transaction.location != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('•', style: TextStyle(color: Colors.grey)),
                        ),
                      Icon(Icons.account_balance, size: 12, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        'UPI: ${transaction.upiId}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
        return AppColors.accentOrange;
      case TransactionStatus.processing:
        return AppColors.primaryBlue;
      case TransactionStatus.failed:
        return AppColors.error;
      case TransactionStatus.cancelled:
        return AppColors.textGrey;
      case TransactionStatus.reversed:
        return Colors.purple;
    }
  }

  String _getStatusDisplayText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'DONE';
      case TransactionStatus.pending:
        return 'PENDING';
      case TransactionStatus.processing:
        return 'PROCESSING';
      case TransactionStatus.failed:
        return 'FAILED';
      case TransactionStatus.cancelled:
        return 'CANCELLED';
      case TransactionStatus.reversed:
        return 'REVERSED';
    }
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.transfer:
        return AppColors.primaryBlue;
      case TransactionCategory.payment:
        return AppColors.accentOrange;
      case TransactionCategory.bills:
        return Colors.red[700]!;
      case TransactionCategory.shopping:
        return Colors.pink[600]!;
      case TransactionCategory.food:
        return Colors.orange[700]!;
      case TransactionCategory.transport:
        return Colors.blue[600]!;
      case TransactionCategory.salary:
        return AppColors.success;
      case TransactionCategory.investment:
        return Colors.green[700]!;
      case TransactionCategory.deposit:
        return AppColors.accentGreen;
      case TransactionCategory.withdrawal:
        return Colors.red[500]!;
      case TransactionCategory.entertainment:
        return Colors.purple[600]!;
      case TransactionCategory.healthcare:
        return Colors.teal[600]!;
      case TransactionCategory.education:
        return Colors.indigo[600]!;
      case TransactionCategory.other:
        return AppColors.textGrey;
    }
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.sent:
      case TransactionType.withdrawal:
      case TransactionType.atmWithdrawal:
      case TransactionType.billPayment:
      case TransactionType.onlinePurchase:
      case TransactionType.accountTransfer:
      case TransactionType.investmentPurchase:
      case TransactionType.bankCharges:
        return AppColors.error;
      case TransactionType.received:
      case TransactionType.deposit:
      case TransactionType.salaryDeposit:
      case TransactionType.interest:
      case TransactionType.refund:
      case TransactionType.cashback:
      case TransactionType.investmentRedemption:
        return AppColors.success;
    }
  }

  String _getTransactionTypeDisplayText(TransactionType type) {
    switch (type) {
      case TransactionType.sent:
        return 'SENT';
      case TransactionType.received:
        return 'RECEIVED';
      case TransactionType.withdrawal:
        return 'WITHDRAWAL';
      case TransactionType.deposit:
        return 'DEPOSIT';
      case TransactionType.billPayment:
        return 'BILL';
      case TransactionType.onlinePurchase:
        return 'PURCHASE';
      case TransactionType.atmWithdrawal:
        return 'ATM';
      case TransactionType.bankCharges:
        return 'CHARGES';
      case TransactionType.salaryDeposit:
        return 'SALARY';
      case TransactionType.interest:
        return 'INTEREST';
      case TransactionType.refund:
        return 'REFUND';
      case TransactionType.cashback:
        return 'CASHBACK';
      case TransactionType.accountTransfer:
        return 'TRANSFER';
      case TransactionType.investmentPurchase:
        return 'INVEST';
      case TransactionType.investmentRedemption:
        return 'REDEEM';
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
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

  Widget _buildTransactionsByStatus(TransactionStatus status) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = transactionProvider.getTransactionsByStatus(status);
        
        if (transactions.isEmpty) {
          return _buildEmptyState(
            message: 'No ${status.name} transactions found',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadTransactions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildTopCategories() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = transactionProvider.transactions;
        
        if (transactions.isEmpty) {
          return _buildEmptyState(message: 'No transactions to categorize');
        }

        // Group transactions by category and calculate totals
        final categoryTotals = <TransactionCategory, double>{};
        final categoryTransactions = <TransactionCategory, List<Transaction>>{};
        
        for (final transaction in transactions) {
          if (transaction.status == TransactionStatus.completed) {
            categoryTotals[transaction.category] = 
                (categoryTotals[transaction.category] ?? 0) + transaction.amount;
            
            categoryTransactions[transaction.category] = 
                categoryTransactions[transaction.category] ?? [];
            categoryTransactions[transaction.category]!.add(transaction);
          }
        }

        // Sort categories by total amount (descending)
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return RefreshIndicator(
          onRefresh: () async => _loadTransactions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final categoryEntry = sortedCategories[index];
              final category = categoryEntry.key;
              final total = categoryEntry.value;
              final categoryTransactionsList = categoryTransactions[category] ?? [];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: _getCategoryColor(category),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    category.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${categoryTransactionsList.length} transactions',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(category),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  children: categoryTransactionsList.take(5).map((transaction) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        transaction.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(transaction.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      trailing: Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: transaction.isIncoming ? AppColors.success : AppColors.error,
                        ),
                      ),
                      onTap: () => _showTransactionDetails(transaction),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'No transactions found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your transaction history will appear here',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total transactions in database: ${transactionProvider.transactionCount}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Refresh'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalytics() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final transactions = transactionProvider.transactions;
        
        if (transactions.isEmpty) {
          return _buildEmptyState(message: 'No data for analytics');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsCard(
                'This Month',
                _getMonthlyStats(transactions),
                Icons.calendar_month,
                AppColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              _buildAnalyticsCard(
                'Average Transaction',
                _getAverageTransactionAmount(transactions),
                Icons.trending_up,
                AppColors.accentGreen,
              ),
              const SizedBox(height: 16),
              _buildAnalyticsCard(
                'Most Frequent',
                _getMostFrequentTransaction(transactions),
                Icons.repeat,
                AppColors.accentOrange,
              ),
              const SizedBox(height: 24),
              _buildRecentActivity(transactions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<Transaction> transactions) {
    final recentTransactions = transactions.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ...recentTransactions.map((transaction) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.backgroundGrey),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.description,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: transaction.type == TransactionType.received 
                      ? AppColors.success 
                      : AppColors.error,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  String _getMonthlyStats(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonth = transactions.where((t) => 
        t.timestamp.year == now.year && t.timestamp.month == now.month).length;
    return '$thisMonth transactions';
  }

  String _getAverageTransactionAmount(List<Transaction> transactions) {
    if (transactions.isEmpty) return '\$0.00';
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    return '\$${(total / transactions.length).toStringAsFixed(2)}';
  }

  String _getMostFrequentTransaction(List<Transaction> transactions) {
    if (transactions.isEmpty) return 'None';
    final sentCount = transactions.where((t) => t.type == TransactionType.sent).length;
    final receivedCount = transactions.where((t) => t.type == TransactionType.received).length;
    return sentCount > receivedCount ? 'Sent' : 'Received';
  }

  void _showTransactionDetails(Transaction transaction) {
    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header with transaction icon and amount
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getCategoryColor(transaction.category), _getCategoryColor(transaction.category).withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          _getCategoryIcon(transaction.category),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              transaction.category.name.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            '${transaction.isIncoming ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(transaction.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusDisplayText(transaction.status),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Scrollable details section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Basic details
                    _buildDetailRow('Transaction ID', transaction.id),
                    _buildDetailRow('Type', _getTransactionTypeDisplayText(transaction.type)),
                    _buildDetailRow('Status', _getStatusDisplayText(transaction.status)),
                    _buildDetailRow('Category', transaction.category.name.toUpperCase()),
                    _buildDetailRow('Date & Time', dateFormat.format(transaction.timestamp)),
                    
                    if (transaction.referenceNumber != null)
                      _buildDetailRow('Reference Number', transaction.referenceNumber!),
                    
                    // Recipient information
                    if (transaction.recipientName != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recipient Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Recipient Name', transaction.recipientName!),
                      if (transaction.recipientAccount != null)
                        _buildDetailRow('Account Number', transaction.recipientAccount!),
                      if (transaction.recipientBank != null)
                        _buildDetailRow('Bank', transaction.recipientBank!),
                      if (transaction.upiId != null)
                        _buildDetailRow('UPI ID', transaction.upiId!),
                    ],
                    
                    // Financial information
                    const SizedBox(height: 16),
                    Text(
                      'Financial Details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Transaction Amount', '₹${transaction.amount.toStringAsFixed(2)}'),
                    if (transaction.charges != null && transaction.charges! > 0)
                      _buildDetailRow('Charges', '₹${transaction.charges!.toStringAsFixed(2)}'),
                    if (transaction.balanceAfter != null)
                      _buildDetailRow('Balance After Transaction', '₹${transaction.balanceAfter!.toStringAsFixed(2)}'),
                    
                    // Location information
                    if (transaction.location != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Location Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Location', transaction.location!),
                    ],
                    
                    // Additional metadata
                    if (transaction.metadata != null && transaction.metadata!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Additional Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...transaction.metadata!.entries.map((entry) =>
                        _buildDetailRow(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          entry.value.toString(),
                        ),
                      ).toList(),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Close button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(transaction.category),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Transactions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Transactions'),
              leading: Radio<String>(
                value: 'All',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Last 7 Days'),
              leading: Radio<String>(
                value: '7days',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Last 30 Days'),
              leading: Radio<String>(
                value: '30days',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Transactions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by description or amount',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            // TODO: Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
