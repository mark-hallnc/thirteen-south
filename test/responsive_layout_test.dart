import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/models/playing_card.dart';
import 'package:tien_len/widgets/home_hero_graphic.dart';
import 'package:tien_len/widgets/player_hand.dart';
import 'package:tien_len/widgets/playing_card_widget.dart';
import 'package:tien_len/widgets/game_table_widgets.dart';
import 'package:tien_len/widgets/wallet_pill.dart';
import 'ui_test.dart' show localizedGame;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  void viewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(800, 600),
    const Size(1024, 1366),
  ]) {
    testWidgets('full screen Home and table at $size', (tester) async {
      viewport(tester, size);
      await tester.pumpWidget(const TienLenApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-header-panel')), findsNothing);
      expect(find.byType(HomeHeroGraphic), findsOneWidget);
      expect(find.byType(WalletPill), findsOneWidget);
      for (final label in ['New Game', 'Rules', 'Settings']) {
        expect(find.text(label), findsOneWidget);
      }
      if (size.width == 320) {
        final button = find.byKey(const ValueKey('new-game-button'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('Wager'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('close-wager')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      final engine = GameEngine()..startNewGame();
      await tester.pumpWidget(
        localizedGame(engine, aiDelay: const Duration(hours: 1)),
      );
      await tester.pump();
      expect(find.byType(OpponentPanel), findsNWidgets(3));
      expect(find.byType(WalletPill), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.textContaining('Thirteen South'), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      final walletRect = tester.getRect(find.byType(WalletPill));
      final settingsRect = tester.getRect(find.byTooltip('Settings'));
      final restartRect = tester.getRect(find.byTooltip('New Game'));
      expect(settingsRect.right, lessThan(restartRect.left));
      expect(restartRect.right, lessThan(walletRect.left));
      expect(walletRect.right, closeTo(size.width - 8, .01));
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byTooltip('New Game'), findsOneWidget);
      expect(find.byType(PlayerHand), findsOneWidget);
      expect(find.byKey(const ValueKey('human-hand-tray')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('game-felt-background'))),
        size,
      );
      expect(find.byKey(const ValueKey('game-stake')), findsNothing);
      expect(find.text('Free Play'), findsNothing);
      final gameId = engine.gameId;
      final handBefore = List<PlayingCard>.of(engine.players.first.hand);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Leave game?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New Game'));
      await tester.pumpAndSettle();
      expect(find.text('Your saved game will be replaced.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(engine.gameId, gameId);
      expect(engine.players.first.hand, handBefore);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('13 readable overlapped cards and reorder at $size', (
      tester,
    ) async {
      viewport(tester, size);
      final cards = [
        for (final rank in CardRank.values) PlayingCard(rank, CardSuit.spades),
      ];
      final selected = <PlayingCard>{};
      final last = cards.last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: StatefulBuilder(
                  builder: (context, update) => PlayerHand(
                    cards: cards,
                    selectedCards: selected,
                    enabled: true,
                    onCardTap: (card) => update(() {
                      selected.contains(card)
                          ? selected.remove(card)
                          : selected.add(card);
                    }),
                    onReorder: (oldIndex, newIndex) => update(() {
                      cards.insert(newIndex, cards.removeAt(oldIndex));
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final handRect = tester.getRect(find.byType(PlayerHand));
      final cardWidgets = tester.widgetList<PlayingCardWidget>(
        find.byType(PlayingCardWidget),
      );
      final minimum = size.shortestSide >= 900
          ? 100
          : size.shortestSide >= 600
          ? 80
          : 62;
      expect(cardWidgets.every((card) => card.width >= minimum), isTrue);
      for (final card in cards) {
        final rect = tester.getRect(find.byKey(ValueKey(card)));
        expect(rect.left, greaterThanOrEqualTo(handRect.left));
        expect(rect.right, lessThanOrEqualTo(handRect.right + .01));
      }
      final firstX = tester.getTopLeft(find.byKey(ValueKey(cards.first))).dx;
      final secondX = tester.getTopLeft(find.byKey(ValueKey(cards[1]))).dx;
      expect(secondX - firstX, greaterThanOrEqualTo(19));
      await tester.drag(find.byKey(ValueKey(last)), Offset(-size.width / 3, 0));
      await tester.pumpAndSettle();
      expect(cards.indexOf(last), lessThan(12));
      expect(selected, isEmpty);
      await tester.tapAt(
        tester.getTopLeft(find.byKey(ValueKey(last))) + const Offset(8, 20),
      );
      await tester.pumpAndSettle();
      expect(selected, contains(last));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('center trick scales on phone and tablet', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1024, 1366),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width - 224,
                child: const TableMoveArea(
                  cards: [PlayingCard(CardRank.ace, CardSuit.hearts)],
                  emptyLabel: '',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final width = tester
          .widget<PlayingCardWidget>(find.byType(PlayingCardWidget))
          .width;
      expect(
        width,
        size.shortestSide >= 900
            ? 132
            : size.shortestSide >= 600
            ? 112
            : 82,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
