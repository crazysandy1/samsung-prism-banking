import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/balance_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accountController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _performTransfer() async {
    if (_formKey.currentState!.validate()) {
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Set balance provider for real-time updates
      transactionProvider.setBalanceProvider(balanceProvider);
      
      final amount = double.parse(_amountController.text);
      final account = _accountController.text;
      final description = _descriptionController.text.isEmpty ? 'Money Transfer' : _descriptionController.text;
      
      // Check if user has sufficient balance
      if (balanceProvider.balance < amount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient balance'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // Use the new banking transaction system with real-time balance updates
      final referenceNumber = await transactionProvider.addBankingTransaction(
        amount: amount,
        description: description,
        type: TransactionType.sent,
        category: TransactionCategory.transfer,
        recipientAccount: account,
      );
      
      if (referenceNumber != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transfer completed successfully!\nReference: $referenceNumber'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transfer failed. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Money Transfer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBankTransferTab(),
                _buildMobileTransferTab(),
                _buildSelfTransferTab(),
                _buildOthersTab(),
              ],
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
          Tab(text: 'Bank Transfer'),
          Tab(text: 'Mobile'),
          Tab(text: 'Self'),
          Tab(text: 'Others'),
        ],
      ),
    );
  }

  Widget _buildBankTransferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransferCard(
              'Bank to Bank Transfer',
              'Transfer money to another bank account',
              FontAwesomeIcons.university,
              AppColors.primaryBlue,
            ),
            const SizedBox(height: 24),
            _buildBalanceDisplay(),
            const SizedBox(height: 24),
            _buildFormFields(),
            const SizedBox(height: 32),
            _buildTransferButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTransferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransferCard(
            'Mobile Transfer',
            'Transfer money using mobile number',
            FontAwesomeIcons.mobileAlt,
            AppColors.accentGreen,
          ),
          const SizedBox(height: 24),
          _buildBalanceDisplay(),
          const SizedBox(height: 24),
          _buildMobileForm(),
          const SizedBox(height: 32),
          _buildTransferButton(),
        ],
      ),
    );
  }

  Widget _buildSelfTransferTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransferCard(
            'Self Transfer',
            'Transfer between your own accounts',
            FontAwesomeIcons.exchangeAlt,
            AppColors.accentOrange,
          ),
          const SizedBox(height: 24),
          _buildBalanceDisplay(),
          const SizedBox(height: 24),
          _buildSelfTransferForm(),
          const SizedBox(height: 32),
          _buildTransferButton(),
        ],
      ),
    );
  }

  Widget _buildOthersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransferCard(
            'Other Options',
            'International transfers and more',
            FontAwesomeIcons.globe,
            AppColors.accentPurple,
          ),
          const SizedBox(height: 24),
          _buildOtherOptions(),
        ],
      ),
    );
  }

  Widget _buildTransferCard(String title, String subtitle, IconData icon, Color color) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${balanceProvider.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _accountController,
          decoration: InputDecoration(
            labelText: 'Recipient Account Number',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildMobileForm() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfTransferForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'From Account',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
            DropdownMenuItem(value: 'checking', child: Text('Checking Account')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'To Account',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
            DropdownMenuItem(value: 'checking', child: Text('Checking Account')),
          ],
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherOptions() {
    return Column(
      children: [
        _buildOptionCard(
          'International Transfer',
          'Send money abroad',
          FontAwesomeIcons.globe,
          AppColors.info,
          () {
            // TODO: Implement international transfer
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          'Bulk Transfer',
          'Multiple transfers at once',
          FontAwesomeIcons.list,
          AppColors.warning,
          () {
            // TODO: Implement bulk transfer
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          'Scheduled Transfer',
          'Set up recurring transfers',
          FontAwesomeIcons.clock,
          AppColors.accentPurple,
          () {
            // TODO: Implement scheduled transfer
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferButton() {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: balanceProvider.isLoading ? null : _performTransfer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: balanceProvider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Transfer Money',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
