import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'utils/android_optimizations.dart';
import 'widgets/performance_debug_overlay.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/enhanced_login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/enhanced_signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/transfer/transfer_screen.dart';
import 'screens/scan/scan_pay_screen.dart';
import 'screens/transactions/transaction_history_screen.dart';
import 'screens/location/location_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/keystroke/keystroke_setup_screen.dart';
import 'screens/security/trusted_locations_screen.dart';
import 'screens/security/security_alerts_screen.dart';
import 'screens/security/secure_transaction_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/balance_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/location_provider.dart' as location_provider;
import 'providers/keystroke_auth_provider.dart';
import 'providers/location_security_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/voice_assistant_provider.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Apply Android emulator optimizations
  AndroidOptimizations.configureForEmulator();
  
  // Initialize Firebase with optimized settings for Android emulator
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firebase Auth for better Android emulator performance
  firebase_auth.FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true, // Disable phone verification for emulator
    forceRecaptchaFlow: false, // Disable reCAPTCHA for faster login
  );
  
  runApp(const SamsungPrismBankingApp());
}

class SamsungPrismBankingApp extends StatefulWidget {
  const SamsungPrismBankingApp({super.key});

  @override
  State<SamsungPrismBankingApp> createState() => _SamsungPrismBankingAppState();
}

class _SamsungPrismBankingAppState extends State<SamsungPrismBankingApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => location_provider.LocationProvider()),
        ChangeNotifierProvider(create: (_) => KeystrokeAuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationSecurityProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..loadLocale()),
        ChangeNotifierProvider(create: (_) => VoiceAssistantProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return PerformanceDebugOverlay(
            child: MaterialApp(
              title: 'Samsung Prism Banking',
              debugShowCheckedModeBanner: false,
              locale: localeProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: localeProvider.supportedLocales,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                primaryColor: AppColors.primaryBlue,
                scaffoldBackgroundColor: AppColors.backgroundGrey,
                textTheme: GoogleFonts.poppinsTextTheme(),
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  titleTextStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                cardTheme: const CardThemeData(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              home: const SplashScreen(),
              routes: {
                '/login': (context) => const LoginScreen(),
                '/enhanced-login': (context) => const EnhancedLoginScreen(),
                '/signup': (context) => const SignUpScreen(),
                '/enhanced-signup': (context) => const EnhancedSignUpScreen(),
                '/home': (context) => const HomeScreen(),
                '/transfer': (context) => const TransferScreen(),
                '/scan-pay': (context) => const ScanPayScreen(),
                '/transactions': (context) => const TransactionHistoryScreen(),
                '/location': (context) => const LocationScreen(),
                '/profile': (context) => const ProfileScreen(),
                '/keystroke-setup': (context) => const KeystrokeSetupScreen(),
                '/trusted-locations': (context) => const TrustedLocationsScreen(),
                '/security-alerts': (context) => const SecurityAlertsScreen(),
                '/secure-transaction': (context) => const SecureTransactionScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
