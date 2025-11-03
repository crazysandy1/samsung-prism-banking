/// Secure Transaction Screen with Location-Based Security
/// 
/// Provides secure transaction processing with location verification

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_security_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/transaction_monitoring_service.dart';
import '../../utils/app_colors.dart';

class SecureTransactionScreen extends StatefulWidget {
  const SecureTransactionScreen({super.key});

  @override
  State<SecureTransactionScreen> createState() => _SecureTransactionScreenState();
}

class _SecureTransactionScreenState extends State<SecureTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TransactionMonitoringService _transactionService = TransactionMonitoringService();
  
  bool _isProcessing = false;
  bool _isLocationSafe = false;
  String? _locationStatus;

  @override
  void initState() {
    super.initState();
    _checkLocationSafety();
  }

  void _checkLocationSafety() async {
    final isLocationSafe = await _transactionService.isLocationSafeForTransactions();
    setState(() {
      _isLocationSafe = isLocationSafe;
      _locationStatus = isLocationSafe 
          ? 'Trusted location detected' 
          : 'Untrusted location - High amount transactions will be flagged';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Secure Transfer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.shield),
            onPressed: () {
              Navigator.pushNamed(context, '/security-alerts');
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, LocationSecurityProvider>(
        builder: (context, authProvider, locationProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationStatusCard(),
                  const SizedBox(height: 24),
                  _buildTransactionForm(),
                  const SizedBox(height: 32),
                  _buildSecurityFeatures(),
                  const SizedBox(height: 32),
                  _buildTransferButton(authProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLocationSafe ? FontAwesomeIcons.shieldHalved : FontAwesomeIcons.triangleExclamation,
                  color: _isLocationSafe ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Security Status',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _locationStatus ?? 'Checking location...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _isLocationSafe ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            if (!_isLocationSafe) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/trusted-locations');
                },
                icon: const Icon(FontAwesomeIcons.plus, size: 16),
                label: const Text('Manage Trusted Locations'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _recipientController,
          decoration: InputDecoration(
            labelText: 'Recipient Account',
            hintText: 'Enter account number or UPI ID',
            prefixIcon: const Icon(FontAwesomeIcons.user),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter recipient details';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            hintText: 'Enter amount',
            prefixIcon: const Icon(FontAwesomeIcons.rupeeSign),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
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
          onChanged: (value) {
            final amount = double.tryParse(value);
            if (amount != null && amount >= 2000 && !_isLocationSafe) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('High amount transaction from untrusted location will generate security alert'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Transaction purpose',
            prefixIcon: const Icon(FontAwesomeIcons.message),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSecurityFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Features',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildSecurityFeature(
          icon: FontAwesomeIcons.locationDot,
          title: 'Location Verification',
          description: 'Transaction location is verified against trusted locations',
          isActive: true,
        ),
        _buildSecurityFeature(
          icon: FontAwesomeIcons.bell,
          title: 'High Amount Alerts',
          description: 'Transactions ≥₹2000 from untrusted locations trigger alerts',
          isActive: true,
        ),
        _buildSecurityFeature(
          icon: FontAwesomeIcons.keyboard,
          title: 'Keystroke Authentication',
          description: 'Biometric typing patterns verify your identity',
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isActive ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
            color: isActive ? Colors.green : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _processTransaction(authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.arrowRight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Process Secure Transfer',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _processTransaction(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Set balance provider for real-time updates
      transactionProvider.setBalanceProvider(balanceProvider);
      
      final amount = double.parse(_amountController.text);
      final recipient = _recipientController.text;
      final description = _descriptionController.text.isEmpty ? 'Secure Transfer' : _descriptionController.text;
      
      // Check if user has sufficient balance
      if (balanceProvider.balance < amount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(FontAwesomeIcons.xmark, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Insufficient balance'),
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // Check transaction security
      final securityResult = await _transactionService.checkTransactionSecurity(
        amount: amount,
        transactionType: 'secure_transfer',
        description: description,
      );

      if (securityResult.alertRequired) {
        // Show security warning dialog
        final proceed = await _showSecurityWarningDialog(securityResult);
        if (!proceed) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      // Process the secure banking transaction with real-time balance updates
      final referenceNumber = await transactionProvider.addBankingTransaction(
        amount: amount,
        description: description,
        type: TransactionType.sent,
        category: TransactionCategory.transfer,
        recipientAccount: recipient,
      );

      if (referenceNumber != null) {
        // Also record in the monitoring service for security tracking
        await _transactionService.recordTransaction(
          amount: amount,
          transactionType: 'secure_transfer',
          description: description,
          location: securityResult.currentLocation,
        );

        // Show success message with reference number
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(FontAwesomeIcons.check, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Secure transfer of ₹${amount.toStringAsFixed(2)} processed successfully!\nReference: $referenceNumber'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Clear form
          _amountController.clear();
          _recipientController.clear();
          _descriptionController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(FontAwesomeIcons.xmark, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Secure transfer failed. Please try again.'),
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.xmark, color: Colors.white),
                const SizedBox(width: 8),
                Text('Transaction failed: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _showSecurityWarningDialog(TransactionSecurityResult securityResult) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              FontAwesomeIcons.triangleExclamation,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Security Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(securityResult.reason),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Note:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This transaction will be logged and monitored for suspicious activity.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
