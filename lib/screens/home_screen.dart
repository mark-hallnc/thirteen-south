import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../widgets/home_hero_graphic.dart';
import '../widgets/stake_selector.dart';
import '../preferences_scope.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const HomeHeroGraphic(),
                  const SizedBox(height: 18),
                  Text(
                    loc.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.paid_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(loc.coinAmount(PreferencesScope.of(context).coinBalance),
                        key: const ValueKey('home-coin-balance')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_hasSave) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('continue-game-button'),
                        onPressed: () => _openGame(resume: true),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(loc.continueGame),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('new-game-button'),
                      onPressed: _openGame,
                      style: _hasSave ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      ) : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(loc.newGame),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RulesScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(loc.rules),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(loc.settings),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
