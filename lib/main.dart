import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'locale_controller_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TienLenApp());
}

class TienLenApp extends StatefulWidget {
  const TienLenApp({super.key});

  @override
  State<TienLenApp> createState() => _TienLenAppState();
}

class _TienLenAppState extends State<TienLenApp> {
  static const _localeKey = 'app_locale';
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final value = (await SharedPreferences.getInstance()).getString(_localeKey);
    if (!mounted || value == null || value == 'system') return;
    setState(() => _locale = Locale(value));
  }

  Future<void> _setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale?.languageCode ?? 'system');
  }

  @override
  Widget build(BuildContext context) {
    return LocaleControllerScope(
      locale: _locale,
      setLocale: _setLocale,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale?.languageCode == 'vi') return const Locale('vi');
          return const Locale('en');
        },
        home: const HomeScreen(),
      ),
    );
  }
}
