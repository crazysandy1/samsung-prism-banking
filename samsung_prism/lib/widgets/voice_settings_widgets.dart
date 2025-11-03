import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_assistant_provider.dart';
import '../providers/locale_provider.dart';

class VoiceSettingsDialog extends StatefulWidget {
  const VoiceSettingsDialog({Key? key}) : super(key: key);

  @override
  State<VoiceSettingsDialog> createState() => _VoiceSettingsDialogState();
}

class _VoiceSettingsDialogState extends State<VoiceSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantProvider>(
      builder: (context, voiceProvider, child) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings_voice, color: Color(0xFF1976D2)),
              SizedBox(width: 8),
              Text('Voice Settings'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auto Speak Toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Auto Speak Responses'),
                    subtitle: const Text('Automatically speak agent responses'),
                    value: voiceProvider.autoSpeak,
                    onChanged: voiceProvider.setAutoSpeak,
                    secondary: const Icon(Icons.volume_up),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Speech Rate
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed),
                            const SizedBox(width: 8),
                            const Text(
                              'Speech Rate',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text('${(voiceProvider.speechRate * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: voiceProvider.speechRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: voiceProvider.setSpeechRate,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Speech Pitch
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune),
                            const SizedBox(width: 8),
                            const Text(
                              'Speech Pitch',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text('${voiceProvider.speechPitch.toStringAsFixed(1)}x'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: voiceProvider.speechPitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: voiceProvider.setSpeechPitch,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Speech Volume
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_up),
                            const SizedBox(width: 8),
                            const Text(
                              'Speech Volume',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text('${(voiceProvider.speechVolume * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: voiceProvider.speechVolume,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: voiceProvider.setSpeechVolume,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Test Speech Button
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _testSpeech(voiceProvider),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Speech'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _testSpeech(VoiceAssistantProvider voiceProvider) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final currentLocale = localeProvider.locale?.languageCode ?? 'en';
    
    // Test messages in different languages
    final testMessages = {
      'en': 'Hello! This is a test of the voice assistant speech settings.',
      'hi': 'नमस्ते! यह वॉयस असिस्टेंट स्पीच सेटिंग्स का परीक्षण है।',
      'kn': 'ಹಲೋ! ಇದು ವಾಯ್ಸ್ ಅಸಿಸ್ಟೆಂಟ್ ಸ್ಪೀಚ್ ಸೆಟ್ಟಿಂಗ್ಗಳ ಪರೀಕ್ಷೆ.',
      'bn': 'হ্যালো! এটি ভয়েস সহায়ক বক্তৃতা সেটিংসের একটি পরীক্ষা।',
      'te': 'హలో! ఇది వాయిస్ అసిస్టెంట్ స్పీచ్ సెట్టింగ్స్ యొక్క పరీక్ష.',
      'ta': 'வணக்கம்! இது குரல் உதவியாளர் பேச்சு அமைப்புகளின் சோதனை.',
      'ml': 'ഹലോ! ഇത് വോയ്‌സ് അസിസ്റ്റന്റ് സ്പീച്ച് ക്രമീകരണങ്ങളുടെ ഒരു ടെസ്റ്റാണ്.',
      'mr': 'नमस्कार! हे व्हॉइस असिस्टंट स्पीच सेटिंग्जची चाचणी आहे.',
      'gu': 'નમસ્તે! આ વોઇસ આસિસ્ટન્ટ સ્પીચ સેટિંગ્સનું પરીક્ષણ છે.',
      'pa': 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਇਹ ਵੌਇਸ ਅਸਿਸਟੈਂਟ ਸਪੀਚ ਸੈਟਿੰਗਸ ਦਾ ਟੈਸਟ ਹੈ।',
      'or': 'ନମସ୍କାର! ଏହା ଭଏସ୍ ଆସିଷ୍ଟାଣ୍ଟ ସ୍ପିଚ୍ ସେଟିଂସର ଏକ ପରୀକ୍ଷା।',
      'ur': 'ہیلو! یہ وائس اسسٹنٹ اسپیچ سیٹنگز کا ٹیسٹ ہے۔',
    };
    
    final testMessage = testMessages[currentLocale] ?? testMessages['en']!;
    voiceProvider.speak(testMessage, languageCode: voiceProvider.selectedLanguage);
  }
}

class VoiceLanguageSelector extends StatelessWidget {
  const VoiceLanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<VoiceAssistantProvider, LocaleProvider>(
      builder: (context, voiceProvider, localeProvider, child) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          tooltip: 'Select Voice Language',
          onSelected: (String languageCode) {
            voiceProvider.setLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return voiceProvider.availableLanguages.entries.map((entry) {
              final localeCode = entry.key;
              final languageCode = entry.value;
              
              // Language display names
              final languageNames = {
                'en': 'English',
                'hi': 'हिंदी (Hindi)',
                'kn': 'ಕನ್ನಡ (Kannada)',
                'bn': 'বাংলা (Bengali)',
                'te': 'తెలుగు (Telugu)',
                'ta': 'தமிழ் (Tamil)',
                'ml': 'മലയാളം (Malayalam)',
                'mr': 'मराठी (Marathi)',
                'gu': 'ગુજરાતી (Gujarati)',
                'pa': 'ਪੰਜਾਬੀ (Punjabi)',
                'or': 'ଓଡ଼ିଆ (Odia)',
                'ur': 'اردو (Urdu)',
              };
              
              final displayName = languageNames[localeCode] ?? localeCode;
              final isSelected = voiceProvider.selectedLanguage == languageCode;
              
              return PopupMenuItem<String>(
                value: localeCode,
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1976D2) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}

class VoicePermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRetry;

  const VoicePermissionDialog({
    Key? key,
    required this.title,
    required this.message,
    this.onOpenSettings,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.mic_off, color: Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          const Text(
            'To use voice features, please:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('• Allow microphone access'),
          const Text('• Enable speech recognition'),
          const Text('• Check device audio settings'),
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        if (onOpenSettings != null)
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}