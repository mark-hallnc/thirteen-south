import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../locale_controller_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = LocaleControllerScope.of(context);
    final selected = controller.locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              loc.language,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              child: RadioGroup<String>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == 'system') {
                    controller.setLocale(null);
                  } else if (value != null) {
                    controller.setLocale(Locale(value));
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      key: const ValueKey('language-system'),
                      value: 'system',
                      title: Text(loc.systemDefault),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      key: const ValueKey('language-en'),
                      value: 'en',
                      title: Text(loc.english),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      key: const ValueKey('language-vi'),
                      value: 'vi',
                      title: Text(loc.vietnamese),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
