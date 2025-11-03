import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceAssistantProvider with ChangeNotifier {
  // Speech Recognition
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  // State Management
  VoiceState _voiceState = VoiceState.idle;
  String _recognizedText = '';
  String _currentSpeakingText = '';
  bool _isInitialized = false;
  String? _lastError;
  double _speechLevel = 0.0;
  
  // Voice Settings
  String _selectedLanguage = 'en-US';
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;
  bool _autoSpeak = true;
  
  // Available Languages Map
  final Map<String, String> _languageMap = {
    'en': 'en-US',    // English
    'hi': 'hi-IN',    // Hindi
    'bn': 'bn-IN',    // Bengali
    'te': 'te-IN',    // Telugu
    'ta': 'ta-IN',    // Tamil
    'kn': 'kn-IN',    // Kannada
    'ml': 'ml-IN',    // Malayalam
    'mr': 'mr-IN',    // Marathi
    'gu': 'gu-IN',    // Gujarati
    'pa': 'pa-IN',    // Punjabi
    'or': 'or-IN',    // Odia
    'ur': 'ur-IN',    // Urdu
  };

  // Getters
  VoiceState get voiceState => _voiceState;
  String get recognizedText => _recognizedText;
  String get currentSpeakingText => _currentSpeakingText;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  double get speechLevel => _speechLevel;
  bool get isListening => _voiceState == VoiceState.listening;
  bool get isSpeaking => _voiceState == VoiceState.speaking;
  bool get isProcessing => _voiceState == VoiceState.processing;
  String get selectedLanguage => _selectedLanguage;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;
  double get speechVolume => _speechVolume;
  bool get autoSpeak => _autoSpeak;
  
  Map<String, String> get availableLanguages => _languageMap;

  /// Initialize Voice Assistant
  Future<bool> initialize() async {
    try {
      debugPrint('🎤 Initializing Voice Assistant...');
      
      // Request permissions
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        _setError('Microphone permission denied');
        return false;
      }

      // Initialize Speech-to-Text
      final sttAvailable = await _speechToText.initialize(
        onError: (error) {
          debugPrint('❌ STT Error: ${error.errorMsg}');
          _setError('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('🎤 STT Status: $status');
          if (status == 'done') {
            _setVoiceState(VoiceState.idle);
          }
        },
      );

      if (!sttAvailable) {
        _setError('Speech recognition not available on this device');
        return false;
      }

      // Initialize Text-to-Speech
      await _initializeTts();
      
      // Load saved settings
      await _loadSettings();

      _isInitialized = true;
      _lastError = null;
      notifyListeners();
      
      debugPrint('✅ Voice Assistant initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Voice Assistant initialization failed: $e');
      _setError('Failed to initialize voice assistant: $e');
      return false;
    }
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    try {
      // Set TTS completion handler
      _flutterTts.setCompletionHandler(() {
        _setVoiceState(VoiceState.idle);
        _currentSpeakingText = '';
        notifyListeners();
      });

      // Set TTS error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('❌ TTS Error: $msg');
        _setError('Text-to-speech error: $msg');
      });

      // Configure TTS settings
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_speechVolume);
      await _flutterTts.setPitch(_speechPitch);
      await _flutterTts.setLanguage(_selectedLanguage);
      
      debugPrint('✅ TTS initialized successfully');
    } catch (e) {
      debugPrint('❌ TTS initialization failed: $e');
      throw Exception('TTS initialization failed: $e');
    }
  }

  /// Start Speech Recognition
  Future<void> startListening({String? languageCode}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_voiceState == VoiceState.listening) {
      return; // Already listening
    }

    try {
      _setVoiceState(VoiceState.listening);
      _recognizedText = '';
      _lastError = null;

      final language = languageCode ?? _selectedLanguage;
      
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _recognizedText = result.recognizedWords;
          _speechLevel = result.hasConfidenceRating ? result.confidence : 0.0;
          notifyListeners();
          
          if (result.finalResult) {
            debugPrint('🎤 Final recognition: $_recognizedText');
            _setVoiceState(VoiceState.processing);
          }
        },
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: language,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
      
      debugPrint('🎤 Started listening in language: $language');
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
      _setError('Failed to start listening: $e');
    }
  }

  /// Stop Speech Recognition
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      
      if (_voiceState == VoiceState.listening) {
        _setVoiceState(VoiceState.idle);
      }
      
      debugPrint('🎤 Stopped listening');
    } catch (e) {
      debugPrint('❌ Failed to stop listening: $e');
      _setError('Failed to stop listening: $e');
    }
  }

  /// Speak Text
  Future<void> speak(String text, {String? languageCode}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    try {
      // Stop any current speech
      await stopSpeaking();
      
      _setVoiceState(VoiceState.speaking);
      _currentSpeakingText = text;

      final language = languageCode ?? _selectedLanguage;
      await _flutterTts.setLanguage(language);
      
      debugPrint('🔊 Speaking: $text (Language: $language)');
      await _flutterTts.speak(text);
      
    } catch (e) {
      debugPrint('❌ Failed to speak: $e');
      _setError('Failed to speak: $e');
    }
  }

  /// Stop Speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      
      if (_voiceState == VoiceState.speaking) {
        _setVoiceState(VoiceState.idle);
      }
      
      _currentSpeakingText = '';
      notifyListeners();
      
      debugPrint('🔊 Stopped speaking');
    } catch (e) {
      debugPrint('❌ Failed to stop speaking: $e');
    }
  }

  /// Set Language
  Future<void> setLanguage(String localeCode) async {
    try {
      final sttLanguage = _languageMap[localeCode] ?? 'en-US';
      _selectedLanguage = sttLanguage;
      
      if (_isInitialized) {
        await _flutterTts.setLanguage(sttLanguage);
      }
      
      await _saveSettings();
      notifyListeners();
      
      debugPrint('🌍 Language set to: $sttLanguage');
    } catch (e) {
      debugPrint('❌ Failed to set language: $e');
      _setError('Failed to set language: $e');
    }
  }

  /// Set Speech Rate
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      
      if (_isInitialized) {
        await _flutterTts.setSpeechRate(_speechRate);
      }
      
      await _saveSettings();
      notifyListeners();
      
      debugPrint('🎚️ Speech rate set to: $_speechRate');
    } catch (e) {
      debugPrint('❌ Failed to set speech rate: $e');
    }
  }

  /// Set Speech Pitch
  Future<void> setSpeechPitch(double pitch) async {
    try {
      _speechPitch = pitch.clamp(0.5, 2.0);
      
      if (_isInitialized) {
        await _flutterTts.setPitch(_speechPitch);
      }
      
      await _saveSettings();
      notifyListeners();
      
      debugPrint('🎚️ Speech pitch set to: $_speechPitch');
    } catch (e) {
      debugPrint('❌ Failed to set speech pitch: $e');
    }
  }

  /// Set Speech Volume
  Future<void> setSpeechVolume(double volume) async {
    try {
      _speechVolume = volume.clamp(0.0, 1.0);
      
      if (_isInitialized) {
        await _flutterTts.setVolume(_speechVolume);
      }
      
      await _saveSettings();
      notifyListeners();
      
      debugPrint('🎚️ Speech volume set to: $_speechVolume');
    } catch (e) {
      debugPrint('❌ Failed to set speech volume: $e');
    }
  }

  /// Toggle Auto Speak
  void setAutoSpeak(bool enabled) {
    _autoSpeak = enabled;
    _saveSettings();
    notifyListeners();
    debugPrint('🔄 Auto speak ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Clear Recognition Text
  void clearRecognizedText() {
    _recognizedText = '';
    notifyListeners();
  }

  /// Clear Error
  void clearError() {
    _lastError = null;
    if (_voiceState == VoiceState.error) {
      _setVoiceState(VoiceState.idle);
    }
  }

  /// Get Available TTS Languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      if (!_isInitialized) return [];
      
      final languages = await _flutterTts.getLanguages;
      return languages?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('❌ Failed to get available languages: $e');
      return [];
    }
  }

  /// Check if Speech Recognition is Available
  Future<bool> isSpeechAvailable() async {
    return await _speechToText.hasPermission && 
           await _speechToText.initialize();
  }

  // Private Methods
  
  void _setVoiceState(VoiceState state) {
    _voiceState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _setVoiceState(VoiceState.error);
    debugPrint('❌ Voice Assistant Error: $error');
  }

  /// Save Voice Settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_language', _selectedLanguage);
      await prefs.setDouble('voice_speech_rate', _speechRate);
      await prefs.setDouble('voice_speech_pitch', _speechPitch);
      await prefs.setDouble('voice_speech_volume', _speechVolume);
      await prefs.setBool('voice_auto_speak', _autoSpeak);
    } catch (e) {
      debugPrint('❌ Failed to save voice settings: $e');
    }
  }

  /// Load Voice Settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLanguage = prefs.getString('voice_language') ?? 'en-US';
      _speechRate = prefs.getDouble('voice_speech_rate') ?? 0.5;
      _speechPitch = prefs.getDouble('voice_speech_pitch') ?? 1.0;
      _speechVolume = prefs.getDouble('voice_speech_volume') ?? 1.0;
      _autoSpeak = prefs.getBool('voice_auto_speak') ?? true;
      
      debugPrint('📱 Loaded voice settings');
    } catch (e) {
      debugPrint('❌ Failed to load voice settings: $e');
    }
  }

  @override
  void dispose() {
    stopListening();
    stopSpeaking();
    super.dispose();
  }
}