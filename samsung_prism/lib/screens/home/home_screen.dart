import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/language_selector.dart';
import '../transfer/transfer_screen.dart';
import '../scan/scan_pay_screen.dart';
import '../transactions/transaction_history_screen.dart';
import '../location/location_screen.dart';
import '../profile/profile_screen.dart';
import '../agent_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Set up balance provider connection for real-time updates
    transactionProvider.setBalanceProvider(balanceProvider);
    
    balanceProvider.fetchBalance();
    transactionProvider.fetchTransactions();
    locationProvider.getCurrentLocation();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: _currentIndex == 0 ? _buildHomeContent() : _buildOtherPages(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildBalanceCard(),
              _buildQuickActions(),
              _buildRecentTransactions(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherPages() {
    switch (_currentIndex) {
      case 1:
        return const TransactionHistoryScreen();
      case 2:
        return const LocationScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Text(
                        _getUserDisplayName(authProvider),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  // Language Selector Button
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, child) {
                      String languageCode = localeProvider.locale?.languageCode.toUpperCase() ?? 'EN';
                      return Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              LanguageSelector.showLanguageSelector(context);
                            },
                            child: Center(
                              child: Text(
                                languageCode,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Notification Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // TODO: Implement notifications
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text('Notifications coming soon!'),
                                ],
                              ),
                              backgroundColor: AppColors.primaryBlue,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Consumer<BalanceProvider>(
            builder: (context, balanceProvider, child) {
              return Text(
                _isBalanceVisible 
                    ? '\$${balanceProvider.balance.toStringAsFixed(2)}'
                    : '****',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Consumer<BalanceProvider>(
            builder: (context, balanceProvider, child) {
              return Row(
                children: [
                  const Icon(Icons.credit_card, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '**** **** **** ${balanceProvider.accountNumber.length > 4 ? balanceProvider.accountNumber.substring(balanceProvider.accountNumber.length - 4) : balanceProvider.accountNumber}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Transfer',
                  FontAwesomeIcons.exchangeAlt,
                  AppColors.primaryBlue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TransferScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Scan & Pay',
                  FontAwesomeIcons.qrcode,
                  AppColors.accentGreen,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanPayScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'History',
                  FontAwesomeIcons.history,
                  AppColors.accentOrange,
                  () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'ATM Locator',
                  FontAwesomeIcons.mapMarkerAlt,
                  AppColors.accentPurple,
                  () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'AI Assistant',
                  FontAwesomeIcons.robot,
                  const Color(0xFF1976D2),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AgentChatScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Secure Transfer',
                  FontAwesomeIcons.shield,
                  Colors.green,
                  () {
                    Navigator.pushNamed(context, '/secure-transaction');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              final recentTransactions = transactionProvider.getRecentTransactions(3);
              
              // Show loading state
              if (transactionProvider.isLoading) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Show error state
              if (transactionProvider.errorMessage != null) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading transactions',
                        style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transactionProvider.errorMessage!,
                        style: GoogleFonts.poppins(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          transactionProvider.clearError();
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              if (recentTransactions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: GoogleFonts.poppins(
                            color: AppColors.textGrey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total transactions: ${transactionProvider.transactionCount}',
                          style: GoogleFonts.poppins(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh, size: 18),
                                const SizedBox(width: 8),
                                Text('Refresh Data'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: recentTransactions.map((transaction) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: transaction.type == TransactionType.received
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            transaction.type == TransactionType.received
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: transaction.type == TransactionType.received
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                transaction.recipientName ?? 'Transfer',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${transaction.type == TransactionType.received ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: transaction.type == TransactionType.received
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGrey,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String _getUserDisplayName(AuthProvider authProvider) {
    final user = authProvider.user;
    if (user == null) return 'User';
    
    // Try to get display name first
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    
    // If no display name, try to extract name from email
    if (user.email != null && user.email!.isNotEmpty) {
      final emailName = user.email!.split('@')[0];
      // Capitalize first letter and replace dots/underscores with spaces
      final cleanName = emailName
          .replaceAll(RegExp(r'[._]'), ' ')
          .split(' ')
          .map((word) => word.isNotEmpty 
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
              : word)
          .join(' ');
      return cleanName;
    }
    
    return 'User';
  }
}
