import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/l10n/app_localizations.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/services/saved_game_service.dart';
import 'package:tien_len/widgets/game_dialog.dart';
import 'package:tien_len/widgets/player_hand.dart';
import 'ui_test.dart' show humanLeadEngine, localizedGame;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'game modal fits light and dark phones and preserves action results',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SizedBox()),
          ),
        );
        final context = tester.element(find.byType(Scaffold));
        for (final confirm in [false, true]) {
          final result = showDialog<bool>(
            context: context,
            builder: (context) => GameDialog(
              title: 'Start New Game',
              message: 'Your saved game will be replaced.',
              icon: Icons.refresh_rounded,
              secondaryAction: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              primaryAction: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start New Game'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.byType(IntrinsicWidth), findsNothing);
          expect(find.byType(IntrinsicHeight), findsNothing);
          expect(find.byType(LayoutBuilder), findsNothing);
          expect(
            tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
            GameModalStyle(context).surface,
          );
          await tester.tap(
            find.widgetWithText(
              confirm ? FilledButton : TextButton,
              confirm ? 'Start New Game' : 'Cancel',
            ),
          );
          await tester.pumpAndSettle();
          expect(await result, confirm);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('Home replacement and Settings reset use GameDialog', (
    tester,
  ) async {
    final engine = humanLeadEngine();
    await tester.runAsync(() async {
      await (await SavedGameService.open()).save(
        SavedGame.capture(engine, engine.players.first.hand),
      );
    });
    await tester.pumpWidget(const TienLenApp());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('new-game-button')));
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(GameDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final reset = find.byKey(const ValueKey('reset-statistics-button'));
    await tester.scrollUntilVisible(reset, 300);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(tester.widget<GameDialog>(find.byType(GameDialog)).warning, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'invalid move notice replaces itself and dismisses; game over stays custom',
    (tester) async {
      final engine = humanLeadEngine();
      await tester.pumpWidget(
        localizedGame(engine, aiDelay: const Duration(hours: 1)),
      );
      await tester.pump();
      tester
          .widget<PlayerHand>(find.byType(PlayerHand))
          .onCardTap(engine.players.first.hand.last);
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('play-button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('game-notice')), findsOneWidget);
        expect(find.text('The opening play must include 3♠.'), findsOneWidget);
        expect(engine.players.first.hand, hasLength(2));
      }
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const ValueKey('game-notice')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      final winner = humanLeadEngine(winningHand: true);
      winner.playCards(winner.players.first.id, [
        winner.players.first.hand.first,
      ]);
      await tester.pumpWidget(localizedGame(winner));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('You win!'), findsOneWidget);
      expect(find.byType(GameDialog), findsNothing);
      expect(find.byType(GameDialogEmblem), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
