/// Security Alerts Screen
/// 
/// Displays security alerts for location-based and transaction-based threats

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/location_security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_security_models.dart';
import '../../utils/app_colors.dart';

class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationSecurityProvider>(context, listen: false);
    
    if (authProvider.user?.uid != null) {
      await locationProvider.loadSecurityAlerts(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Security Alerts',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<LocationSecurityProvider>(
            builder: (context, locationProvider, child) {
              if (locationProvider.unreadAlertsCount > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${locationProvider.unreadAlertsCount}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<LocationSecurityProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final alerts = locationProvider.securityAlerts;

          if (alerts.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadAlerts();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(alert, locationProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.shieldHalved,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Security Alerts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account is secure. We\'ll notify you\nif any suspicious activity is detected.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(SecurityAlert alert, LocationSecurityProvider locationProvider) {
    return Card(
      elevation: alert.isRead ? 1 : 3,
      color: alert.isRead ? Colors.white : Colors.red.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          if (!alert.isRead) {
            locationProvider.markAlertAsRead(alert.id);
          }
          _showAlertDetails(alert);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAlertColor(alert.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAlertIcon(alert.type),
                      color: _getAlertColor(alert.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: GoogleFonts.poppins(
                            fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(alert.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!alert.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              if (alert.transactionAmount != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Amount: ₹${alert.transactionAmount!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (alert.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.locationDot,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert.location!.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(SecurityAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.type),
              color: _getAlertColor(alert.type),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Time: ${DateFormat('MMMM dd, yyyy • hh:mm a').format(alert.timestamp)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              if (alert.transactionAmount != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
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
                        'Transaction Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        '₹${alert.transactionAmount!.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (alert.location != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.locationDot,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Location Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.location!.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                      if (alert.location!.address != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          alert.location!.address!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[600],
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(SecurityAlertType type) {
    switch (type) {
      case SecurityAlertType.suspicious_location:
        return FontAwesomeIcons.locationDot;
      case SecurityAlertType.high_amount_transaction:
        return FontAwesomeIcons.exclamationTriangle;
      case SecurityAlertType.new_device_login:
        return FontAwesomeIcons.mobileScreen;
      case SecurityAlertType.multiple_failed_attempts:
        return FontAwesomeIcons.lock;
      case SecurityAlertType.location_change:
        return FontAwesomeIcons.route;
    }
  }

  Color _getAlertColor(SecurityAlertType type) {
    switch (type) {
      case SecurityAlertType.suspicious_location:
        return Colors.orange;
      case SecurityAlertType.high_amount_transaction:
        return Colors.red;
      case SecurityAlertType.new_device_login:
        return Colors.blue;
      case SecurityAlertType.multiple_failed_attempts:
        return Colors.red;
      case SecurityAlertType.location_change:
        return Colors.purple;
    }
  }
}
