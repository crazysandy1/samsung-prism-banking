/// Trusted Locations Management Screen
/// 
/// Allows users to view and manage their trusted locations for enhanced security

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/location_security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_security_models.dart';
import '../../utils/app_colors.dart';

class TrustedLocationsScreen extends StatefulWidget {
  const TrustedLocationsScreen({super.key});

  @override
  State<TrustedLocationsScreen> createState() => _TrustedLocationsScreenState();
}

class _TrustedLocationsScreenState extends State<TrustedLocationsScreen> {
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '5.0');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationSecurityProvider>(context, listen: false);
    
    if (authProvider.user?.uid != null) {
      await locationProvider.loadTrustedLocations(authProvider.user!.uid);
      await locationProvider.getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Trusted Locations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<LocationSecurityProvider, AuthProvider>(
        builder: (context, locationProvider, authProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentLocationCard(locationProvider),
                const SizedBox(height: 20),
                _buildAddLocationSection(locationProvider, authProvider),
                const SizedBox(height: 20),
                _buildTrustedLocationsList(locationProvider, authProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentLocationCard(LocationSecurityProvider locationProvider) {
    final currentLocation = locationProvider.currentLocation;
    final isCurrentTrusted = locationProvider.isCurrentLocationTrusted();

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
                  FontAwesomeIcons.locationDot,
                  color: isCurrentTrusted ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (currentLocation != null) ...[
              Text(
                currentLocation.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentTrusted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentTrusted ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isCurrentTrusted ? 'Trusted Location' : 'Untrusted Location',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isCurrentTrusted ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Location not available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await locationProvider.getCurrentLocation();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Get Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddLocationSection(LocationSecurityProvider locationProvider, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Current Location as Trusted',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationNameController,
              decoration: InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Home, Office, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(FontAwesomeIcons.tag),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Radius (km)',
                hintText: '5.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(FontAwesomeIcons.circle),
                suffixText: 'km',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: locationProvider.currentLocation != null && !locationProvider.isLoading
                    ? () => _addTrustedLocation(locationProvider, authProvider)
                    : null,
                icon: const Icon(FontAwesomeIcons.plus, size: 18),
                label: const Text('Add Trusted Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustedLocationsList(LocationSecurityProvider locationProvider, AuthProvider authProvider) {
    final trustedLocations = locationProvider.trustedLocations;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trusted Locations (${trustedLocations.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (trustedLocations.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      FontAwesomeIcons.mapLocationDot,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trusted locations added yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your current location to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trustedLocations.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final location = trustedLocations[index];
                  return _buildTrustedLocationItem(location, locationProvider, authProvider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustedLocationItem(TrustedLocation trustedLocation, LocationSecurityProvider locationProvider, AuthProvider authProvider) {
    final currentLocation = locationProvider.currentLocation;
    final distance = currentLocation?.distanceFrom(trustedLocation.location);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          FontAwesomeIcons.mapPin,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        trustedLocation.name,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trustedLocation.location.displayName,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Radius: ${trustedLocation.radiusKm}km',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: 8),
                Text(
                  '• ${distance.toStringAsFixed(1)}km away',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: () => _removeTrustedLocation(trustedLocation, locationProvider, authProvider),
        icon: const Icon(
          FontAwesomeIcons.trash,
          color: Colors.red,
          size: 18,
        ),
      ),
    );
  }

  void _addTrustedLocation(LocationSecurityProvider locationProvider, AuthProvider authProvider) async {
    final name = _locationNameController.text.trim();
    final radiusText = _radiusController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter a location name');
      return;
    }

    double radius;
    try {
      radius = double.parse(radiusText);
      if (radius <= 0 || radius > 50) {
        _showError('Radius must be between 0.1 and 50 km');
        return;
      }
    } catch (e) {
      _showError('Please enter a valid radius');
      return;
    }

    final success = await locationProvider.addTrustedLocation(
      userId: authProvider.user!.uid,
      name: name,
      radiusKm: radius,
    );

    if (success) {
      _locationNameController.clear();
      _radiusController.text = '5.0';
      _showSuccess('Trusted location added successfully!');
    } else {
      _showError(locationProvider.errorMessage ?? 'Failed to add trusted location');
    }
  }

  void _removeTrustedLocation(TrustedLocation trustedLocation, LocationSecurityProvider locationProvider, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Trusted Location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove "${trustedLocation.name}" from your trusted locations?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await locationProvider.removeTrustedLocation(
                userId: authProvider.user!.uid,
                locationId: trustedLocation.id,
              );
              
              if (success) {
                _showSuccess('Trusted location removed successfully!');
              } else {
                _showError(locationProvider.errorMessage ?? 'Failed to remove trusted location');
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
