import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/language_option.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.onThemeChanged,
    super.key,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final AppThemeKey currentTheme;
  final ValueChanged<AppThemeKey> onThemeChanged;

  static const List<LanguageOption> _languageOptions = <LanguageOption>[
    LanguageOption(code: 'de', label: 'Deutsch'),
    LanguageOption(code: 'en', label: 'English'),
    LanguageOption(code: 'es', label: 'Espanol'),
    LanguageOption(code: 'fr', label: 'Francais'),
    LanguageOption(code: 'it', label: 'Italiano'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l10n.settingsLanguageTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: currentLocale.languageCode,
          decoration: InputDecoration(
            labelText: l10n.settingsLanguageLabel,
            border: const OutlineInputBorder(),
          ),
          items:
              _languageOptions
                  .map(
                    (LanguageOption option) => DropdownMenuItem<String>(
                      value: option.code,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
          onChanged: (String? selectedCode) {
            if (selectedCode == null) {
              return;
            }
            onLocaleChanged(Locale(selectedCode));
          },
        ),
        const SizedBox(height: 20),
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<AppThemeKey>(
          value: currentTheme,
          decoration: const InputDecoration(
            labelText: 'Farbschema',
            border: OutlineInputBorder(),
          ),
          items:
              AppThemeKey.values
                  .map(
                    (AppThemeKey option) => DropdownMenuItem<AppThemeKey>(
                      value: option,
                      child: Text(option.displayName),
                    ),
                  )
                  .toList(),
          onChanged: (AppThemeKey? selectedTheme) {
            if (selectedTheme == null) {
              return;
            }
            onThemeChanged(selectedTheme);
          },
        ),
      ],
    );
  }
}
