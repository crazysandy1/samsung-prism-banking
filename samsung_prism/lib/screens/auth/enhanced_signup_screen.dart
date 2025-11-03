import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/keystroke_auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/keystroke_recorder.dart';
import '../../models/keystroke_models.dart';

class EnhancedSignUpScreen extends StatefulWidget {
  const EnhancedSignUpScreen({super.key});

  @override
  State<EnhancedSignUpScreen> createState() => _EnhancedSignUpScreenState();
}

class _EnhancedSignUpScreenState extends State<EnhancedSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _enableKeystrokeTraining = false;
  
  // Keystroke training state
  List<KeystrokeSession> _trainingSessions = [];
  int _currentTrainingStep = 0;
  final int _requiredTrainingSessions = 3;
  bool _isTrainingMode = false;
  String? _trainingText;

  // Predefined training texts
  final List<String> _trainingTexts = [
    'The quick brown fox jumps over the lazy dog',
    'Hello world, this is my password pattern',
    'Banking security is very important to us',
  ];

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
      try {
        await keystrokeProvider.configure(
          serverIp: 'localhost',
          port: 5000,
          useHttps: false,
        );
      } catch (e) {
        print('Keystroke auto-configuration failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startKeystrokeTraining() {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address first');
      return;
    }

    setState(() {
      _isTrainingMode = true;
      _currentTrainingStep = 0;
      _trainingSessions.clear();
      _trainingText = _trainingTexts[_currentTrainingStep];
    });
  }

  void _onTrainingSessionComplete(KeystrokeSession session) {
    final userId = _emailController.text.trim();
    final completedSession = session.copyWith(userId: userId);
    
    setState(() {
      _trainingSessions.add(completedSession);
      _currentTrainingStep++;
      
      if (_currentTrainingStep < _requiredTrainingSessions) {
        _trainingText = _trainingTexts[_currentTrainingStep];
      } else {
        _trainingText = null;
        _performKeystrokeTraining();
      }
    });
  }

  void _performKeystrokeTraining() async {
    final keystrokeProvider = Provider.of<KeystrokeAuthProvider>(context, listen: false);
    final userId = _emailController.text.trim();

    try {
      // Train the model with all collected sessions
      for (final session in _trainingSessions) {
        await keystrokeProvider.trainUser(userId, session: session);
      }

      if (mounted) {
        setState(() {
          _isTrainingMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keystroke training completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTrainingMode = false;
        });
        _showError('Keystroke training failed: ${e.toString()}');
      }
    }
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
      );

      if (success && mounted) {
        if (_enableKeystrokeTraining && _trainingSessions.isNotEmpty) {
          // Show success message with keystroke info
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully with keystroke security!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Sign up failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

  Widget _buildTrainingSection() {
    if (!_enableKeystrokeTraining) return const SizedBox.shrink();

    return Consumer<KeystrokeAuthProvider>(
      builder: (context, keystrokeProvider, child) {
        return Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keystroke Security Training',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (!_isTrainingMode && _trainingSessions.isEmpty) ...[
                Text(
                  'Train your unique typing pattern for enhanced security. This will help protect your account even if your password is compromised.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: keystrokeProvider.isConfigured ? _startKeystrokeTraining : null,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(
                      'Start Keystroke Training',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (!keystrokeProvider.isConfigured)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Keystroke server not available. Training will be skipped.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              
              if (_isTrainingMode && _trainingText != null) ...[
                Text(
                  'Training Step ${_currentTrainingStep + 1} of $_requiredTrainingSessions',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type the following text exactly as shown:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _trainingText!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TrainingKeystrokeRecorder(
                  key: ValueKey('training_${_currentTrainingStep}'),
                  onSessionComplete: _onTrainingSessionComplete,
                  trainingText: _trainingText!,
                  enabled: !keystrokeProvider.state.isProcessing,
                ),
              ],
              
              if (_trainingSessions.isNotEmpty && !_isTrainingMode) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Keystroke training completed (${_trainingSessions.length}/$_requiredTrainingSessions sessions)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (keystrokeProvider.state.isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        keystrokeProvider.state.message ?? 'Processing...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      size: 50,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join Samsung Prism Banking with Enhanced Security',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Sign Up Form
                  Container(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Full Name Field
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
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
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Keystroke Training Toggle
                          Consumer<KeystrokeAuthProvider>(
                            builder: (context, keystrokeProvider, child) {
                              return CheckboxListTile(
                                value: _enableKeystrokeTraining,
                                onChanged: (value) {
                                  setState(() {
                                    _enableKeystrokeTraining = value ?? false;
                                    if (!_enableKeystrokeTraining) {
                                      _isTrainingMode = false;
                                      _trainingSessions.clear();
                                      _currentTrainingStep = 0;
                                    }
                                  });
                                },
                                title: Text(
                                  'Enable Keystroke Security',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Train your unique typing pattern for enhanced security',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),

                          // Keystroke Training Section
                          _buildTrainingSection(),

                          const SizedBox(height: 30),

                          // Sign Up Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              final isProcessing = authProvider.isLoading || _isTrainingMode;
                              
                              return SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isProcessing
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          'Create Account',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
