import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../widgets/home_hero_graphic.dart';
import '../widgets/stake_selector.dart';
import '../widgets/wallet_pill.dart';
import '../services/saved_game_service.dart';
import 'game_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SavedGameService? _service;
  bool _hasSave = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _refreshSave();
  }

  Future<void> _refreshSave() async {
    final service = await SavedGameService.open();
    if (!mounted) return;
    setState(() {
      _service = service;
      _hasSave = service.hasSavedGame();
    });
  }

  Future<void> _openGame({bool resume = false}) async {
    if (_opening) return;
    _opening = true;
    try {
      final service = _service ?? await SavedGameService.open();
      final saved = service.load();
      if (!mounted) return;
      if (!resume && saved != null) {
        final loc = AppLocalizations.of(context)!;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.startNewGameTitle),
            content: Text(loc.replaceSavedGameMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.startNewGame),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      if (resume && saved == null) {
        await _refreshSave();
        return;
      }
      if (!mounted) return;
      final game = resume ? saved! : await selectNewGame(context);
      if (game == null || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            engine: game.engine,
            initialHumanCardOrder: game.humanCardOrder,
            stake: game.stake,
            stakeCommitted: game.stakeCommitted,
          ),
        ),
      );
      await _refreshSave();
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final tablet = size.shortestSide >= 600;
    final large = size.shortestSide >= 900;
    final side = tablet ? 40.0 : 24.0;
    final heroWidth = (size.width - side * 2)
        .clamp(
          0.0,
          large
              ? 600.0
              : tablet
              ? 480.0
              : 360.0,
        )
        .toDouble();
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF315D50),
      brightness: Brightness.dark,
    );
    final buttonHeight = tablet ? 68.0 : 56.0;
    final primaryStyle = FilledButton.styleFrom(
      minimumSize: Size(double.infinity, buttonHeight),
      textStyle: TextStyle(
        fontSize: tablet ? 22 : 18,
        fontWeight: FontWeight.w700,
      ),
    );
    final secondaryStyle = OutlinedButton.styleFrom(
      minimumSize: Size(0, buttonHeight),
      foregroundColor: const Color(0xFFE3EEE7),
      side: const BorderSide(color: Color(0xFF577B69)),
      textStyle: TextStyle(fontSize: tablet ? 20 : 16),
    );
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: const Color(0xFF081C16),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          bottom: const WalletStatusRow(),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -.4),
              radius: 1.05,
              colors: [Color(0xFF214E3D), Color(0xFF081C16)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      64,
                      side,
                      tablet ? 48 : 28,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: heroWidth,
                          height: heroWidth * 168 / 260,
                          child: const FittedBox(child: HomeHeroGraphic()),
                        ),
                        SizedBox(height: tablet ? 26 : 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Text(
                            loc.appTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFF6F4EA),
                              fontSize: large
                                  ? 56
                                  : tablet
                                  ? 46
                                  : 38,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -.7,
                            ),
                          ),
                        ),
                        SizedBox(height: tablet ? 40 : 28),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: large ? 640 : 600,
                          ),
                          child: Column(
                            children: [
                              if (_hasSave) ...[
                                FilledButton.icon(
                                  key: const ValueKey('continue-game-button'),
                                  onPressed: () => _openGame(resume: true),
                                  style: primaryStyle,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(loc.continueGame),
                                ),
                                const SizedBox(height: 14),
                              ],
                              FilledButton.icon(
                                key: const ValueKey('new-game-button'),
                                onPressed: _openGame,
                                style: _hasSave
                                    ? primaryStyle.copyWith(
                                        backgroundColor: WidgetStatePropertyAll(
                                          colors.secondaryContainer,
                                        ),
                                        foregroundColor: WidgetStatePropertyAll(
                                          colors.onSecondaryContainer,
                                        ),
                                      )
                                    : primaryStyle,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(loc.newGame),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const RulesScreen(),
                                            ),
                                          ),
                                      style: secondaryStyle,
                                      icon: const Icon(
                                        Icons.menu_book_outlined,
                                      ),
                                      label: Text(loc.rules),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const SettingsScreen(),
                                            ),
                                          ),
                                      style: secondaryStyle,
                                      icon: const Icon(Icons.tune_rounded),
                                      label: Text(loc.settings),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
