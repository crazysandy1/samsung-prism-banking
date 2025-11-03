import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/keystroke_auth_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/keystroke_recorder.dart';
import '../../models/keystroke_models.dart';

class KeystrokeSetupScreen extends StatefulWidget {
  const KeystrokeSetupScreen({super.key});

  @override
  State<KeystrokeSetupScreen> createState() => _KeystrokeSetupScreenState();
}

class _KeystrokeSetupScreenState extends State<KeystrokeSetupScreen> {
  final _trainingPasswordController = TextEditingController();
  
  int _currentStep = 0; // Start at 0 (skip URL configuration)
  int _trainingSamplesCollected = 0;
  final int _requiredSamples = 5;
  List<KeystrokeSession> _trainingSessions = [];
  bool _isTraining = false;
  String? _passedUserId; // Store the passed userId
  
  // Key for keystroke recorder to force rebuild and clear input
  Key _keystrokeRecorderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeKeystrokeAuth();
  }

  void _initializeKeystrokeAuth() async {
    // Get the passed userId from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments['userId'] != null) {
        _passedUserId = arguments['userId'] as String;
        print('DEBUG: Received userId from navigation: $_passedUserId');
        setState(() {}); // Trigger rebuild with the userId
      }
    });
    
    // Provider will auto-configure with default settings
    await Future.delayed(Duration.zero); // Ensure provider is initialized
  }

  @override
  void dispose() {
    _trainingPasswordController.dispose();
    super.dispose();
  }

  // Get the correct userId - prioritize passed userId, then Firebase email, then Firebase UID, then demo_user
  String _getUserId() {
    if (_passedUserId != null && _passedUserId!.isNotEmpty) {
      return _passedUserId!;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.email ?? authProvider.user?.uid ?? 'demo_user';
  }

  void _nextStep() {
    if (_currentStep < 1) { // Only one step now: training
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _trainModel() async {
    final keystrokeProvider = Provider.of<KeystrokeAuthProvider>(context, listen: false);
    
    // Use the consistent userId
    final userId = _getUserId();
    
    print('DEBUG: Training model with user ID: $userId');
    print('DEBUG: Passed userId: $_passedUserId');
    print('DEBUG: Firebase UID: ${Provider.of<AuthProvider>(context, listen: false).user?.uid}');
    print('DEBUG: User email: ${Provider.of<AuthProvider>(context, listen: false).user?.email}');
    
    setState(() {
      _isTraining = true;
    });

    try {
      // Train the model with collected samples
      for (final session in _trainingSessions) {
        await keystrokeProvider.trainUser(userId, session: session);
      }
      
      if (keystrokeProvider.state.status != KeystrokeAuthStatus.error) {
        _showMessage('Model training completed successfully! Your keystroke pattern has been saved.', isError: false);
        
        // Keep the trained data available - don't clear it
        // Just show success and allow user to continue
        
        // Navigate back to login after a delay to show the success message
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/enhanced-login');
        }
      } else {
        _showMessage('Model training failed. Please try again.', isError: true);
      }
    } catch (e) {
      _showMessage('Training error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isTraining = false;
      });
    }
  }

  void _onKeystrokeSessionComplete(KeystrokeSession session) {
    // Use the consistent userId
    final userId = _getUserId();
    
    final sessionWithUser = session.copyWith(userId: userId);
    _trainingSessions.add(sessionWithUser);
    
    setState(() {
      _trainingSamplesCollected = _trainingSessions.length;
      // Clear the input and regenerate the recorder widget
      _keystrokeRecorderKey = UniqueKey();
    });

    // Clear the text field after recording
    _trainingPasswordController.clear();

    if (_trainingSamplesCollected >= _requiredSamples) {
      _showMessage('All training samples collected! Ready to train your model.', isError: false);
      _nextStep();
    } else {
      _showMessage('Sample ${_trainingSamplesCollected}/$_requiredSamples collected. Please type the password again.', isError: false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) { // Only 2 steps now: training and completion
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentStep ? AppColors.primaryBlue : AppColors.textLight,
          ),
        );
      }),
    );
  }

  Widget _buildTrainingDataStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collect Training Data',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Type your password $_requiredSamples times to train the keystroke model',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        
        // Debug info
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            'Training for user: ${_getUserId()}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.keyboard,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Training Progress',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '$_trainingSamplesCollected / $_requiredSamples samples collected',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: _trainingSamplesCollected / _requiredSamples,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        if (_trainingSamplesCollected < _requiredSamples) ...[
          KeystrokeRecorder(
            key: _keystrokeRecorderKey,
            onSessionComplete: _onKeystrokeSessionComplete,
            hintText: 'Type your password to record timing pattern',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Type naturally as you would during normal login. The system will record your keystroke timing patterns.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All training samples collected successfully!',
                    style: GoogleFonts.poppins(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Proceed to Training',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModelTrainingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Train Model',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Train the machine learning model with your keystroke patterns',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.psychology,
                size: 64,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to Train',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your keystroke patterns have been collected. Click below to train the authentication model.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isTraining ? null : _trainModel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isTraining
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Training Model...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Train Model',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/enhanced-login');
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.poppins(
                color: AppColors.textGrey,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Keystroke Setup',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Consumer<KeystrokeAuthProvider>(
                      builder: (context, keystrokeProvider, child) {
                        switch (_currentStep) {
                          case 0:
                            return _buildTrainingDataStep();
                          case 1:
                            return _buildModelTrainingStep();
                          default:
                            return _buildTrainingDataStep();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: Text(
                          'Previous',
                          style: GoogleFonts.poppins(
                            color: AppColors.textGrey,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    
                    Text(
                      'Step ${_currentStep + 1} of 2',
                      style: GoogleFonts.poppins(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox.shrink(), // Placeholder for symmetry
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
