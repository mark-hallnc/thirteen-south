import 'package:flutter/material.dart';
import 'package:tien_len/widgets/game_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/l10n/app_localizations.dart';
import 'package:tien_len/models/coin_statistics.dart';
import 'package:tien_len/services/preferences_service.dart';
import 'package:tien_len/services/saved_game_service.dart';
import 'package:tien_len/widgets/stake_selector.dart';
import 'dart:convert';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'wagers return immediately, close cancels, and fallback never refills',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      Future<int?> open(int balance) => showDialog<int>(
        context: context,
        builder: (_) => StakeSelector(balance: balance),
      );
      for (final stake in [10, 25, 50, 100]) {
        final result = open(stake);
        await tester.pumpAndSettle();
        expect(find.text('Choose Your Wager'), findsOneWidget);
        for (final removed in [
          'Play For',
          'Free Play',
          'Start Game',
          'Cancel',
          'Practice',
        ]) {
          expect(find.text(removed), findsNothing);
        }
        expect(find.byType(StakeCoinOption), findsNWidgets(4));
        expect(find.byType(LayoutBuilder), findsNothing);
        for (final amount in [10, 25, 50, 100]) {
          final choice = find.byKey(ValueKey('stake-$amount'));
          expect(
            tester.widget<StakeCoinOption>(choice).enabled,
            amount <= stake,
          );
          if (amount > stake) {
            await tester.tap(choice);
            await tester.pumpAndSettle();
            expect(find.byType(StakeSelector), findsOneWidget);
          }
        }
        await tester.tap(find.byKey(ValueKey('stake-$stake')));
        await tester.pumpAndSettle();
        expect(await result, stake);
        expect(find.byType(StakeSelector), findsNothing);
      }
      final cancelled = open(10);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('close-wager')));
      await tester.pumpAndSettle();
      expect(await cancelled, isNull);
      for (final balance in [0, 9]) {
        final result = open(balance);
        await tester.pumpAndSettle();
        expect(find.text('Not enough coins'), findsOneWidget);
        expect(find.byType(StakeCoinOption), findsNothing);
        await tester.tap(find.byKey(const ValueKey('earn-coins')));
        await tester.pumpAndSettle();
        expect(find.text('Coming soon'), findsOneWidget);
        expect(find.byType(GameDialog), findsNWidgets(2));
        await tester.tap(find.byKey(const ValueKey('close-coming-soon')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('practice-game')));
        await tester.pumpAndSettle();
        expect(await result, 0);
      }
    },
  );

  testWidgets(
    'direct wager flow commits once; Practice survives resume without rewards',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      late Future<SavedGame?> pending;
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);
      for (final stake in [10, 25, 50, 100, 0]) {
        if (stake == 0) {
          await prefs.setString(
            PreferencesService.coinStateKey,
            jsonEncode(const CoinStatistics(balance: 9).toJson()),
          );
        }
        final before = service.loadCoins().toJson();
        await tester.runAsync(() async {
          pending = selectNewGame(context);
        });
        await tester.pumpAndSettle();
        if (stake == 0) {
          await tester.tap(find.byKey(const ValueKey('earn-coins')));
          await tester.pumpAndSettle();
          expect(service.loadCoins().toJson(), before);
          await tester.tap(find.byKey(const ValueKey('close-coming-soon')));
          await tester.pumpAndSettle();
        }
        await tester.tap(
          find.byKey(ValueKey(stake == 0 ? 'practice-game' : 'stake-$stake')),
        );
        final game = await tester.runAsync(() => pending);
        await tester.pumpAndSettle();
        expect(game, isNotNull);
        expect(game!.stake, stake);
        expect(
          service.loadCoins().balance,
          (before['coin_balance'] as int) - stake,
        );
        if (stake == 0) {
          final restored = (await tester.runAsync(
            () => SavedGameService.open(),
          ))!.load()!;
          expect(restored.engine.gameId, game.engine.gameId);
          final freshService = PreferencesService(prefs);
          expect(freshService.isPracticeGame(restored.engine.gameId), isTrue);
          for (final won in [true, false]) {
            await tester.runAsync(
              () => freshService.settleGame(
                gameId: restored.engine.gameId,
                stake: 0,
                humanWon: won,
              ),
            );
            expect(freshService.loadCoins().toJson(), before);
          }
        }
      }
    },
  );
}
