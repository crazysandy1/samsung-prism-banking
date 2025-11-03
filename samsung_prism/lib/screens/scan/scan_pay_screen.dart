import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/balance_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';

class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({super.key});

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startQRScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRScanned: (String scannedData) {
            _processScannedData(scannedData);
          },
        ),
      ),
    );
  }

  void _processScannedData(String scannedData) {
    // Parse the scanned QR data
    Map<String, dynamic>? parsedData = _parseQRData(scannedData);
    
    if (parsedData == null) {
      // Show error dialog if QR data couldn't be parsed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Invalid QR Code',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: const Text('This QR code does not contain valid payment information.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    Map<String, dynamic> merchantInfo = parsedData;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'QR Code Scanned',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merchant: ${merchantInfo['merchant']}',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: \$${merchantInfo['amount']}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Description: ${merchantInfo['description']}',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              'Scanned Data: $scannedData',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(
                merchantInfo['amount'].toDouble(), 
                merchantInfo['merchant'], 
                merchantInfo['description']
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseQRData(String qrData) {
    try {
      // Try to parse as JSON first
      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        final Map<String, dynamic> data = json.decode(qrData);
        return {
          'merchant': data['merchant'] ?? 'Unknown Merchant',
          'amount': double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
          'description': data['description'] ?? 'Payment via QR',
        };
      }
      
      // Try to parse as UPI format
      if (qrData.startsWith('upi://')) {
        final uri = Uri.parse(qrData);
        return {
          'merchant': uri.queryParameters['pn'] ?? 'UPI Merchant',
          'amount': double.tryParse(uri.queryParameters['am'] ?? '0') ?? 0.0,
          'description': uri.queryParameters['tn'] ?? 'UPI Payment',
        };
      }
      
      // Simple fallback parsing for custom formats
      final lines = qrData.split('\n');
      final data = <String, dynamic>{};
      
      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().toLowerCase();
            final value = parts.sublist(1).join(':').trim();
            
            if (key.contains('merchant') || key.contains('name')) {
              data['merchant'] = value;
            } else if (key.contains('amount') || key.contains('price')) {
              data['amount'] = double.tryParse(value) ?? 0.0;
            } else if (key.contains('description') || key.contains('note')) {
              data['description'] = value;
            }
          }
        }
      }
      
      // Return with defaults if some data found
      if (data.isNotEmpty) {
        return {
          'merchant': data['merchant'] ?? 'QR Merchant',
          'amount': data['amount'] ?? 0.0,
          'description': data['description'] ?? 'QR Payment',
        };
      }
      
      return null;
    } catch (e) {
      print('Error parsing QR data: $e');
      return null;
    }
  }

  void _processPayment(double amount, String merchant, String description) async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Set balance provider for real-time updates
    transactionProvider.setBalanceProvider(balanceProvider);

    if (balanceProvider.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Add transaction (which will automatically update balance via real-time sync)
    await transactionProvider.addBankingTransaction(
      amount: amount,
      description: description,
      type: TransactionType.sent,
      category: TransactionCategory.payment,
      recipientName: merchant,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of \$${amount.toStringAsFixed(2)} successful!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Scan & Pay',
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
                _buildScanTab(),
                _buildPayTab(),
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
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.qr_code_scanner),
            text: 'Scan QR',
          ),
          Tab(
            icon: Icon(Icons.qr_code),
            text: 'My QR',
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildScannerCard(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentScans(),
        ],
      ),
    );
  }

  Widget _buildPayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMyQRCard(),
          const SizedBox(height: 24),
          _buildQRSettings(),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBlue, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1),
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
                // Scanner corners
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.primaryBlue, width: 3),
                        left: BorderSide(color: AppColors.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.primaryBlue, width: 3),
                        right: BorderSide(color: AppColors.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.primaryBlue, width: 3),
                        left: BorderSide(color: AppColors.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.primaryBlue, width: 3),
                        right: BorderSide(color: AppColors.primaryBlue, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Point your camera at a QR code',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan merchant QR codes to pay instantly',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startQRScan,
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: Text(
              'Start Scanning',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
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
                'Scan Bills',
                FontAwesomeIcons.receipt,
                AppColors.accentOrange,
                () {
                  // TODO: Implement bill scanning
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Scan Products',
                FontAwesomeIcons.shoppingCart,
                AppColors.accentGreen,
                () {
                  // TODO: Implement product scanning
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
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

  Widget _buildRecentScans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Scans',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildScanItem('Starbucks Coffee', '\$5.99', 'Today 2:30 PM'),
        _buildScanItem('Shell Gas Station', '\$45.00', 'Yesterday 8:15 AM'),
        _buildScanItem('McDonald\'s', '\$12.50', '2 days ago'),
      ],
    );
  }

  Widget _buildScanItem(String merchant, String amount, String time) {
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
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.qr_code, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQRCard() {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        final qrData = 'samsung_prism_bank:${balanceProvider.accountNumber}';
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
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
            children: [
              Text(
                'My Payment QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Account: ${balanceProvider.accountNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Show this QR code to receive payments',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement QR code sharing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR code shared!')),
                        );
                      },
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('Share', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement QR code download
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR code saved!')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          'Request Amount',
          'Create QR for specific amount',
          Icons.request_quote,
          () {
            _showAmountRequestDialog();
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          'QR History',
          'View QR payment history',
          Icons.history,
          () {
            // TODO: Implement QR history
          },
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          'Security Settings',
          'Manage QR code security',
          Icons.security,
          () {
            // TODO: Implement security settings
          },
        ),
      ],
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
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
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
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

  void _showAmountRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Request Amount',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Generate QR with amount
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR code generated with amount!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Generate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final Function(String) onQRScanned;

  const QRScannerScreen({Key? key, required this.onQRScanned}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          isScanning = false;
        });
        widget.onQRScanned(barcode.rawValue!);
        Navigator.pop(context);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => cameraController.switchCamera(),
            icon: const Icon(Icons.camera_front),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.primaryBlue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Point your camera at a QR code',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// QR Scanner Overlay Shape
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderOffset
        ? borderWidthSize / 2
        : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    // Draw the border lines
    final path = Path()
      // Top left
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset + _borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset + borderRadius)
      ..quadraticBezierTo(
          cutOutRect.left - borderOffset,
          cutOutRect.top - borderOffset,
          cutOutRect.left - borderOffset + borderRadius,
          cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.left - borderOffset + _borderLength, cutOutRect.top - borderOffset)
      // Top right
      ..moveTo(cutOutRect.right + borderOffset - _borderLength, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right + borderOffset - borderRadius, cutOutRect.top - borderOffset)
      ..quadraticBezierTo(
          cutOutRect.right + borderOffset,
          cutOutRect.top - borderOffset,
          cutOutRect.right + borderOffset,
          cutOutRect.top - borderOffset + borderRadius)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset + _borderLength)
      // Bottom right
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset - _borderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset - borderRadius)
      ..quadraticBezierTo(
          cutOutRect.right + borderOffset,
          cutOutRect.bottom + borderOffset,
          cutOutRect.right + borderOffset - borderRadius,
          cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.right + borderOffset - _borderLength, cutOutRect.bottom + borderOffset)
      // Bottom left
      ..moveTo(cutOutRect.left - borderOffset + _borderLength, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.left - borderOffset + borderRadius, cutOutRect.bottom + borderOffset)
      ..quadraticBezierTo(
          cutOutRect.left - borderOffset,
          cutOutRect.bottom + borderOffset,
          cutOutRect.left - borderOffset,
          cutOutRect.bottom + borderOffset - borderRadius)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset - _borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
