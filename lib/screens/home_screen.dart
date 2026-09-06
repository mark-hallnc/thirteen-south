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
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, bottom: const WalletStatusRow()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    key: const ValueKey('home-header-panel'),
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const RadialGradient(
                        center: Alignment(0, -.45),
                        radius: 1.1,
                        colors: [Color(0xFF2A5B4B), Color(0xFF143B30)],
                      ),
                      border: Border.all(color: const Color(0xFF426658)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18103329),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HomeHeroGraphic(),
                        const SizedBox(height: 12),
                        Text(
                          loc.appTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: const Color(0xFFF6F4EA),
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                                letterSpacing: -.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      style: _hasSave
                          ? FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            )
                          : null,
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
