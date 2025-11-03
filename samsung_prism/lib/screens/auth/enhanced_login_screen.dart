import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/keystroke_auth_provider.dart';
import '../../providers/location_security_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/keystroke_recorder.dart';
import '../../widgets/language_selector.dart';
import '../../models/keystroke_models.dart';
import '../../l10n/app_localizations.dart';
import 'enhanced_signup_screen.dart';

class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _useKeystrokeDynamics = false;
  KeystrokeSession? _passwordKeystrokeSession;
  String? _capturedPassword; // Store the password from keystroke session

  @override
  void initState() {
    super.initState();
    _initializeKeystrokeAuth();
  }

  void _initializeKeystrokeAuth() async {
    final keystrokeProvider = Provider.of<KeystrokeAuthProvider>(context, listen: false);
    await keystrokeProvider.loadConfiguration();
    
    // If not configured, auto-configure with localhost
    if (!keystrokeProvider.isConfigured) {
      print('DEBUG: Auto-configuring keystroke provider with localhost');
      try {
        await keystrokeProvider.configure(
          serverIp: 'localhost',
          port: 5000,
          useHttps: false,
        );
        print('DEBUG: Auto-configuration successful');
      } catch (e) {
        print('DEBUG: Auto-configuration failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final keystrokeProvider = Provider.of<KeystrokeAuthProvider>(context, listen: false);
      
      // If keystroke dynamics is disabled, use traditional login only
      if (!_useKeystrokeDynamics) {
        print('DEBUG: Keystroke dynamics disabled, using traditional login');
        await _performTraditionalLogin(authProvider);
        return;
      }
      
      print('DEBUG: Keystroke dynamics enabled, starting keystroke auth flow');
      final userId = _emailController.text.trim();
      
      // Auto-configure if needed
      if (!keystrokeProvider.isConfigured) {
        print('DEBUG: Provider not configured, attempting auto-configuration');
        try {
          await keystrokeProvider.configure(
            serverIp: 'localhost',
            port: 5000,
            useHttps: false,
          );
        } catch (e) {
          print('DEBUG: Auto-configuration failed: $e');
          if (mounted) {
            _showError('Unable to connect to keystroke server. Redirecting to setup...');
            Navigator.pushReplacementNamed(
              context, 
              '/keystroke-setup',
              arguments: {'userId': userId}, // Pass the userId
            );
          }
          return;
        }
      }
      
      // Load user info to check training status
      print('DEBUG: Loading user info for $userId');
      await keystrokeProvider.loadUserInfo(userId);
      
      // Debug: Check what user info we have
      final userInfo = keystrokeProvider.state.userInfo;
      print('DEBUG: User info loaded: $userInfo');
      if (userInfo != null) {
        print('DEBUG: Training samples: ${userInfo.trainingSamples}');
        print('DEBUG: Has trained model: ${userInfo.hasTrainedModel}');
        print('DEBUG: Needs more training: ${userInfo.needsMoreTraining}');
      }
      
      final needsTraining = keystrokeProvider.needsTraining(userId);
      print('DEBUG: needsTraining result: $needsTraining');
      
      // Check if user needs training first
      if (needsTraining) {
        print('DEBUG: User needs training, redirecting to setup with userId: $userId');
        if (mounted) {
          _showError('User needs keystroke training. Redirecting to setup...');
          Navigator.pushReplacementNamed(
            context, 
            '/keystroke-setup',
            arguments: {'userId': userId}, // Pass the userId
          );
        }
        return;
      }
      
      // Check if we have keystroke data
      if (_passwordKeystrokeSession == null) {
        print('DEBUG: No keystroke session data available');
        _showError('Please type your password to record keystroke pattern.');
        return;
      }
      
      // Check if we have the captured password
      if (_capturedPassword == null || _capturedPassword!.isEmpty) {
        print('DEBUG: No password captured from keystroke session');
        _showError('Please enter your password.');
        return;
      }
      
      // Validate password length
      if (_capturedPassword!.length < 6) {
        print('DEBUG: Password too short');
        _showError('Password must be at least 6 characters.');
        return;
      }
      
      print('DEBUG: Proceeding with keystroke authentication');
      try {
        // Authenticate with keystroke dynamics FIRST
        final keystrokeAuthSuccess = await keystrokeProvider.authenticateUser(
          userId,
          session: _passwordKeystrokeSession,
        );

        if (!keystrokeAuthSuccess) {
          // Keystroke authentication failed - DO NOT proceed to Firebase
          print('DEBUG: Keystroke authentication failed');
          if (mounted) {
            _showError('Keystroke pattern verification failed. Access denied.');
          }
          return;
        }
        
        print('DEBUG: Keystroke authentication successful');
        // Keystroke authentication passed - now show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keystroke pattern verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Keystroke authentication error - DO NOT proceed to Firebase
        print('Keystroke authentication error: $e');
        if (mounted) {
          _showError('Keystroke authentication failed: ${e.toString()}');
        }
        return;
      }
      
      // Step 2: Traditional email/password authentication (only after keystroke passes)
      print('DEBUG: Proceeding with Firebase authentication');
      await _performTraditionalLogin(authProvider);
    }
  }

  Future<void> _performTraditionalLogin(AuthProvider authProvider) async {
    final locationProvider = Provider.of<LocationSecurityProvider>(context, listen: false);
    final email = _emailController.text.trim();
    
    // Use captured password from keystroke session if available, otherwise use password controller
    final password = _useKeystrokeDynamics && _capturedPassword != null 
        ? _capturedPassword! 
        : _passwordController.text;
    
    print('DEBUG: Using ${_useKeystrokeDynamics ? "captured" : "controller"} password for Firebase auth');
    print('DEBUG: Password length: ${password.length}');
    
    final traditionalAuthSuccess = await authProvider.signInWithEmailAndPassword(
      email,
      password,
    );

    // Record login attempt regardless of success/failure
    try {
      await locationProvider.recordLoginAttempt(
        userId: email, // Use email as userId for now
        isSuccessful: traditionalAuthSuccess,
        authMethod: _useKeystrokeDynamics ? 'password+keystroke' : 'password',
      );
    } catch (e) {
      print('Failed to record login attempt: $e');
    }

    if (!traditionalAuthSuccess) {
      if (mounted) {
        _showError(authProvider.errorMessage ?? 'Firebase authentication failed');
      }
      return;
    }

    // Success - initialize location security for the user
    try {
      if (authProvider.user?.uid != null) {
        await locationProvider.initializeForUser(authProvider.user!.uid);
      }
    } catch (e) {
      print('Failed to initialize location security: $e');
    }

    // Navigate to home
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onKeystrokeSessionComplete(KeystrokeSession session) {
    setState(() {
      _passwordKeystrokeSession = session.copyWith(
        userId: _emailController.text.trim(),
      );
      // Store the captured password for Firebase authentication
      _capturedPassword = session.capturedText;
      print('DEBUG: Password captured from keystroke session: ${_capturedPassword?.isNotEmpty == true ? "[REDACTED]" : "EMPTY"}');
    });
  }

  Widget _buildKeystrokeStatus() {
    return Consumer<KeystrokeAuthProvider>(
      builder: (context, keystrokeProvider, child) {
        String status;
        Color color;
        IconData icon;
        
        if (!keystrokeProvider.isConfigured) {
          status = 'Keystroke recording enabled - Setup required';
          color = AppColors.warning;
          icon = Icons.warning_amber;
        } else {
          status = keystrokeProvider.getStatusMessage();
          color = keystrokeProvider.getStatusColor();
          icon = _getStatusIcon(keystrokeProvider.state.status);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(KeystrokeAuthStatus status) {
    switch (status) {
      case KeystrokeAuthStatus.idle:
        return Icons.security;
      case KeystrokeAuthStatus.recording:
        return Icons.fiber_manual_record;
      case KeystrokeAuthStatus.training:
      case KeystrokeAuthStatus.authenticating:
        return Icons.hourglass_empty;
      case KeystrokeAuthStatus.success:
        return Icons.check_circle;
      case KeystrokeAuthStatus.failure:
      case KeystrokeAuthStatus.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue,
              AppColors.primaryBlue.withOpacity(0.8),
              AppColors.secondaryBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title
                      Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.appTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure Financial Management',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.welcomeBack,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field with Keystroke Recording
                          Consumer<KeystrokeAuthProvider>(
                            builder: (context, keystrokeProvider, child) {
                              if (_useKeystrokeDynamics) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password (with keystroke verification)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    PasswordKeystrokeRecorder(
                                      onSessionComplete: _onKeystrokeSessionComplete,
                                      hintText: AppLocalizations.of(context)!.password,
                                      enabled: !keystrokeProvider.state.isProcessing,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildKeystrokeStatus(),
                                  ],
                                );
                              } else {
                                return TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.password,
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Keystroke Dynamics Toggle
                          Consumer<KeystrokeAuthProvider>(
                            builder: (context, keystrokeProvider, child) {
                              if (keystrokeProvider.isConfigured) {
                                return CheckboxListTile(
                                  value: _useKeystrokeDynamics,
                                  onChanged: (value) {
                                    setState(() {
                                      _useKeystrokeDynamics = value ?? false;
                                      // Clear captured data when toggling
                                      if (!_useKeystrokeDynamics) {
                                        _passwordKeystrokeSession = null;
                                        _capturedPassword = null;
                                      }
                                    });
                                  },
                                  title: const Text(
                                    'Enable Keystroke Verification',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'Additional security through typing pattern analysis',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Keystroke Verification Unavailable',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.amber[700],
                                              ),
                                            ),
                                            Text(
                                              'Server not configured. Go to Settings to connect.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.amber[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context, 
                                            '/keystroke-setup',
                                            arguments: {'userId': _emailController.text.trim()}, // Pass the current email
                                          );
                                        },
                                        child: const Text('Setup', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          
                          const SizedBox(height: 24),

                          // Login Button
                          Consumer2<AuthProvider, KeystrokeAuthProvider>(
                            builder: (context, authProvider, keystrokeProvider, child) {
                              final isLoading = authProvider.isLoading || keystrokeProvider.state.isProcessing;
                              
                              return ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.login,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Forgot Password
                          TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: Text(
                              AppLocalizations.of(context)!.forgotPassword,
                              style: GoogleFonts.poppins(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.dontHaveAccount,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EnhancedSignUpScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.signup,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Language Selector
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const LanguageSelector(),
                  );
                },
                icon: const Icon(
                  Icons.language,
                  color: Colors.black87,
                ),
                tooltip: AppLocalizations.of(context)!.selectLanguage,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
