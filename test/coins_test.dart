import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/models/coin_statistics.dart';
import 'package:tien_len/screens/game_screen.dart';
import 'package:tien_len/services/preferences_service.dart';
import 'package:tien_len/services/saved_game_service.dart';
import 'package:tien_len/widgets/player_hand.dart';
import 'package:tien_len/widgets/stake_selector.dart';
import 'package:tien_len/widgets/wallet_pill.dart';

import 'ui_test.dart' show humanLeadEngine;

void main() {
  late PreferencesService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = PreferencesService(await SharedPreferences.getInstance());
  });

  test('new players have 500 coins and no coin history', () {
    final coins = service.loadCoins();
    expect(coins.balance, 500);
    expect(coins.highestBalance, 500);
    expect(coins.won, 0);
    expect(coins.lost, 0);
  });

  test('25 stake commits once, wins net 75, and survives reload', () async {
    expect(await service.commitStake('win', 25), isTrue);
    expect(service.loadCoins().balance, 475);
    await service.commitStake('win', 25);
    expect(service.loadCoins().balance, 475);
    final coins = await service.settleGame(
      gameId: 'win',
      stake: 25,
      humanWon: true,
    );
    expect(coins.balance, 575);
    expect(coins.highestBalance, 575);
    expect(coins.won, 75);
    expect(coins.lost, 0);
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    expect(
      PreferencesService(preferences).loadCoins().toJson(),
      coins.toJson(),
    );
  });

  test('25 stake loss loses only the committed stake', () async {
    await service.commitStake('loss', 25);
    final coins = await service.settleGame(
      gameId: 'loss',
      stake: 25,
      humanWon: false,
    );
    expect(coins.balance, 475);
    expect(coins.highestBalance, 500);
    expect(coins.won, 0);
    expect(coins.lost, 25);
  });

  test('Free Play wins 10 and loses zero, including at zero balance', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      PreferencesService.coinStateKey,
      jsonEncode(const CoinStatistics(balance: 0).toJson()),
    );
    expect(await service.commitStake('unaffordable', 10), isFalse);
    expect(await service.commitStake('free-loss', 0), isTrue);
    await service.settleGame(gameId: 'free-loss', stake: 0, humanWon: false);
    expect(service.loadCoins().balance, 0);
    await service.commitStake('free-win', 0);
    await service.settleGame(gameId: 'free-win', stake: 0, humanWon: true);
    expect(service.loadCoins().balance, 10);
    expect(service.loadCoins().won, 10);
    expect(service.loadCoins().lost, 0);
  });

  test(
    'concurrent and older duplicate IDs cannot deduct or settle twice',
    () async {
      await Future.wait(
        List.generate(3, (_) => service.commitStake('one', 25)),
      );
      expect(service.loadCoins().balance, 475);
      await Future.wait(
        List.generate(
          3,
          (_) => service.settleGame(gameId: 'one', stake: 25, humanWon: true),
        ),
      );
      await service.commitStake('two', 0);
      await service.settleGame(gameId: 'two', stake: 0, humanWon: true);
      await service.settleGame(gameId: 'one', stake: 25, humanWon: true);
      expect(service.loadCoins().balance, 585);
      expect(service.loadCoins().won, 85);
    },
  );

  test(
    'replacing a game has no refund; normal reset keeps coin history',
    () async {
      await service.commitStake('abandoned', 25);
      await service.commitStake('replacement', 0);
      await service.settleGame(gameId: 'replacement', stake: 0, humanWon: true);
      final before = service.loadCoins().toJson();
      await service.resetStatistics();
      expect(service.loadCoins().toJson(), before);
      expect(service.loadCoins().balance, 485);
      expect(service.loadCoins().lost, 0);
    },
  );

  testWidgets('zero balance shows on Home and only Free is available', (
    tester,
  ) async {
    await (await SharedPreferences.getInstance()).setString(
      PreferencesService.coinStateKey,
      jsonEncode(const CoinStatistics(balance: 0).toJson()),
    );
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    expect(tester.widget<WalletPill>(find.byType(WalletPill)).balance, 0);
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();
    for (final stake in CoinEconomy.stakes) {
      final chip = tester.widget<ChoiceChip>(
        find.byKey(ValueKey('stake-$stake')),
      );
      expect(chip.onSelected != null, stake == 0);
    }
    await tester.tap(find.byKey(const ValueKey('start-staked-game')));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
    expect(service.loadCoins().balance, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('selecting then cancelling a stake does not deduct', (
    tester,
  ) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    expect(tester.widget<WalletPill>(find.byType(WalletPill)).balance, 500);
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stake-25')));
    await tester.pumpAndSettle();
    expect(service.loadCoins().balance, 500);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.loadCoins().balance, 500);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets(
    'Continue restores stake without selector or another deduction; result shows net',
    (tester) async {
      final engine = humanLeadEngine(winningHand: true);
      await service.commitStake(engine.gameId, 25);
      await (await SavedGameService.open()).save(
        SavedGame.capture(engine, engine.players.first.hand, stake: 25),
      );
      await tester.pumpWidget(const TienLenApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('continue-game-button')));
      await tester.pumpAndSettle();
      expect(find.byType(StakeSelector), findsNothing);
      expect(find.text('Stake: 25'), findsOneWidget);
      expect(service.loadCoins().balance, 475);
      final screen = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(screen.stake, 25);
      expect(screen.stakeCommitted, isTrue);
      expect(screen.engine!.gameId, engine.gameId);
      final hand = tester.widget<PlayerHand>(find.byType(PlayerHand));
      hand.onCardTap(hand.cards.single);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await tester.pumpAndSettle();
      expect(find.text('+75 Coins\nBalance: 575 Coins'), findsOneWidget);
      expect(service.loadCoins().balance, 575);
      expect((await SavedGameService.open()).hasSavedGame(), isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
