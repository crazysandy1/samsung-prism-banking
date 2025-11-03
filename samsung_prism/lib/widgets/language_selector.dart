import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';

import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  // Map of language codes to their flag emojis
  final Map<String, String> _languageFlags = const {
    'en': 'US',
    'hi': 'IN',
    'bn': 'BD',
    'te': 'IN',
    'ta': 'IN',
    'kn': 'IN',
    'ml': 'IN',
    'mr': 'IN',
    'gu': 'IN',
    'pa': 'IN',
    'or': 'IN',
    'ur': 'IN',
  };

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    final supportedLocales = localeProvider.supportedLocales;

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectLanguage),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: supportedLocales.length,
          itemBuilder: (context, index) {
            final locale = supportedLocales[index];
            final languageCode = locale.languageCode;
            final languageName = localeProvider.languageNames[languageCode] ?? languageCode.toUpperCase();
            final countryCode = _languageFlags[languageCode] ?? 'US';
            
            return ListTile(
              leading: CountryFlag.fromCountryCode(
                countryCode,
                height: 24,
                width: 36,
              ),
              title: Text(languageName),
              trailing: currentLocale?.languageCode == languageCode 
                  ? const Icon(Icons.check_circle, color: Colors.blue) 
                  : null,
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }

  // Helper method to show the language selector dialog
  static Future<void> showLanguageSelector(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => const LanguageSelector(),
    );
  }
}
