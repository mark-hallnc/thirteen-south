import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import 'ai/ai_difficulty.dart';
import 'models/game_statistics.dart';
import 'models/coin_statistics.dart';
import 'preferences_scope.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';
import 'locale_controller_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  bool _soundsEnabled = true;
  AiDifficulty _difficulty = AiDifficulty.normal;
  GameStatistics _statistics = const GameStatistics();
  PreferencesService? _preferencesService;
  CoinStatistics _coins = const CoinStatistics();

  Future<bool> _commitStake(String gameId, int stake) async {
    final service =
        _preferencesService ??
        PreferencesService(await SharedPreferences.getInstance());
    final committed = await service.commitStake(gameId, stake);
    if (mounted) setState(() => _coins = service.loadCoins());
    return committed;
  }

  Future<CoinStatistics> _settleGame(
    String gameId,
    int stake,
    bool humanWon,
  ) async {
    final service =
        _preferencesService ??
        PreferencesService(await SharedPreferences.getInstance());
    final coins = await service.settleGame(
      gameId: gameId,
      stake: stake,
      humanWon: humanWon,
    );
    if (mounted) setState(() => _coins = coins);
    return coins;
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final service = PreferencesService(preferences);
    final value = preferences.getString(_localeKey);
    if (!mounted) return;
    setState(() {
      _preferencesService = service;
      _difficulty = service.loadDifficulty();
      _soundsEnabled = service.loadSoundsEnabled();
      _statistics = service.loadStatistics();
      _coins = service.loadCoins();
      if (value != null && value != 'system') _locale = Locale(value);
    });
  }

  Future<void> _setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale?.languageCode ?? 'system');
  }

  Future<void> _setSoundsEnabled(bool enabled) async {
    setState(() => _soundsEnabled = enabled);
    final service =
        _preferencesService ??
        PreferencesService(await SharedPreferences.getInstance());
    _preferencesService = service;
    await service.saveSoundsEnabled(enabled);
  }

  Future<void> _setDifficulty(AiDifficulty difficulty) async {
    setState(() => _difficulty = difficulty);
    final service =
        _preferencesService ??
        PreferencesService(await SharedPreferences.getInstance());
    _preferencesService = service;
    await service.saveDifficulty(difficulty);
  }

  Future<void> _recordGameResult(String gameId, bool humanWon) async {
    final service =
        _preferencesService ??
        PreferencesService(await SharedPreferences.getInstance());
    _preferencesService = service;
    final statistics = await service.recordGameResult(
      gameId: gameId,
      humanWon: humanWon,
    );
    if (mounted) setState(() => _statistics = statistics);
  }

  Future<void> _resetStatistics() async {
    final service =
        _preferencesService ??
        PreferencesService(await SharedPreferences.getInstance());
    _preferencesService = service;
    final statistics = await service.resetStatistics();
    if (mounted) setState(() => _statistics = statistics);
  }

  @override
  Widget build(BuildContext context) {
    return PreferencesScope(
      difficulty: _difficulty,
      coins: _coins,
      commitStake: _commitStake,
      settleGame: _settleGame,
      soundsEnabled: _soundsEnabled,
      setSoundsEnabled: _setSoundsEnabled,
      statistics: _statistics,
      setDifficulty: _setDifficulty,
      recordGameResult: _recordGameResult,
      resetStatistics: _resetStatistics,
      child: LocaleControllerScope(
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
      ),
    );
  }
}
