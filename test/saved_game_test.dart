import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/ai/ai_difficulty.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/models/playing_card.dart';
import 'package:tien_len/screens/game_screen.dart';
import 'package:tien_len/services/preferences_service.dart';
import 'package:tien_len/services/saved_game_service.dart';
import 'package:tien_len/widgets/player_hand.dart';

import 'ui_test.dart' show humanLeadEngine;

void main() {
  late SavedGameService service;
  setUp(() async {
    // Drain writes from the previous widget before replacing the mock store.
    await SavedGameService.open();
    SharedPreferences.setMockInitialValues({});
    service = await SavedGameService.open();
  });

  test(
    'round trip preserves exact engine and UI state, including trick passes',
    () async {
      final engine = humanLeadEngine()..difficulty = AiDifficulty.hard;
      engine.playCards(engine.players.first.id, [
        engine.players.first.hand.first,
      ]);
      engine.pass(engine.state.currentPlayer.id);
      final expected = engine.toJson();
      final order = engine.players.first.hand.reversed.toList();
      await service.save(SavedGame.capture(engine, order));
      expect(service.hasSavedGame(), isTrue);
      final restored = service.load()!;
      expect(restored.engine.toJson(), expected);
      expect(restored.engine.gameId, engine.gameId);
      expect(restored.engine.state.currentPlayerIndex, 2);
      expect(
        restored.engine.state.currentTableMove,
        engine.state.currentTableMove,
      );
      expect(restored.engine.state.passedPlayerIds, {engine.players[1].id});
      expect(restored.humanCardOrder, order);
      // Both games must clear the same trick after the remaining players pass.
      for (final game in [engine, restored.engine]) {
        expect(game.pass(game.state.currentPlayer.id).isValid, isTrue);
        expect(game.pass(game.state.currentPlayer.id).isValid, isTrue);
        expect(game.state.currentTableMove, isNull);
        expect(game.state.passedPlayerIds, isEmpty);
        expect(game.state.currentPlayerIndex, 0);
      }
      expect(restored.engine.toJson(), engine.toJson());
    },
  );

  test('opening requirement, game ID and full hands survive a fresh deal', () {
    final engine = GameEngine()..startNewGame();
    final restored = GameEngine.fromJson(
      jsonDecode(jsonEncode(engine.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), engine.toJson());
    expect(restored.state.openingRuleActive, isTrue);
  });

  test('completed games clear the slot and new games replace it', () async {
    final first = humanLeadEngine();
    await service.save(SavedGame.capture(first, first.players.first.hand));
    final next = humanLeadEngine(winningHand: true);
    await service.save(SavedGame.capture(next, next.players.first.hand));
    expect(service.load()!.engine.gameId, next.gameId);
    next.playCards(next.players.first.id, [next.players.first.hand.single]);
    await service.save(SavedGame.capture(next, []));
    expect(service.hasSavedGame(), isFalse);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        SavedGameService.saveKey,
      ),
      isFalse,
    );
  });

  test(
    'queued snapshots cannot overwrite a newer save or completion',
    () async {
      final engine = humanLeadEngine(winningHand: true);
      final pending = service.save(
        SavedGame.capture(engine, engine.players.first.hand),
      );
      engine.playCards(engine.players.first.id, [
        engine.players.first.hand.single,
      ]);
      final clearing = service.save(SavedGame.capture(engine, []));
      await Future.wait([pending, clearing]);
      expect(service.load(), isNull);
    },
  );

  test('invalid and unsupported saves are ignored', () async {
    final preferences = await SharedPreferences.getInstance();
    for (final value in ['broken', '{"version":99}', '{}']) {
      await preferences.setString(SavedGameService.saveKey, value);
      expect(service.hasSavedGame(), isFalse);
    }
  });

  testWidgets(
    'Continue restores order with no selection; leaving keeps the save',
    (tester) async {
      final engine = humanLeadEngine();
      final order = engine.players.first.hand.reversed.toList();
      await service.save(SavedGame.capture(engine, order));
      await tester.pumpWidget(const TienLenApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('continue-game-button')));
      await tester.pumpAndSettle();
      final screen = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(screen.engine!.toJson(), engine.toJson());
      var hand = tester.widget<PlayerHand>(find.byType(PlayerHand));
      expect(hand.cards, order);
      expect(hand.selectedCards, isEmpty);
      hand.onCardTap(order.first);
      hand.onReorder!(0, 1);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('continue-game-button')),
        findsOneWidget,
      );
      expect(service.load()!.engine.gameId, engine.gameId);
      await tester.tap(find.byKey(const ValueKey('continue-game-button')));
      await tester.pumpAndSettle();
      hand = tester.widget<PlayerHand>(find.byType(PlayerHand));
      expect(hand.cards, order.reversed.toList());
      expect(hand.selectedCards, isEmpty);
      final stats = PreferencesService(
        await SharedPreferences.getInstance(),
      ).loadStatistics();
      expect(stats.gamesPlayed, 0);
      expect(stats.losses, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Home hides Continue without a save and confirms replacing one', (
    tester,
  ) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continue-game-button')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    final engine = humanLeadEngine();
    await service.save(SavedGame.capture(engine, engine.players.first.hand));
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();
    expect(find.text('Your saved game will be replaced.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.load()!.engine.gameId, engine.gameId);
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start New Game'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-staked-game')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(GameScreen), findsOneWidget);
    expect(service.load()!.engine.gameId, isNot(engine.gameId));
    final stats = PreferencesService(
      await SharedPreferences.getInstance(),
    ).loadStatistics();
    expect(stats.gamesPlayed, 0);
    expect(stats.losses, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('restored AI turn resumes once and completion clears the save', (
    tester,
  ) async {
    final engine = humanLeadEngine();
    engine.playCards(engine.players.first.id, [
      engine.players.first.hand.first,
    ]);
    await service.save(SavedGame.capture(engine, engine.players.first.hand));
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-game-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final restored = tester.widget<GameScreen>(find.byType(GameScreen)).engine!;
    expect(restored.state.currentPlayerIndex, 1);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(restored.state.winner, same(restored.players[1]));
    expect(service.hasSavedGame(), isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continue-game-button')), findsNothing);
  });
}
