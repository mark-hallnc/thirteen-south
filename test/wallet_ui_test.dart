import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/widgets/wallet_pill.dart';

import 'ui_test.dart' show humanLeadEngine, localizedGame;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Home wallet is in the header, with wallets on Rules and Settings',
    (tester) async {
      await tester.pumpWidget(const TienLenApp());
      await tester.pumpAndSettle();
      expect(find.text('500 Coins'), findsNothing);
      expect(find.byKey(const ValueKey('home-coin-balance')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(WalletPill),
        ),
        findsOneWidget,
      );
      for (final screen in ['Rules', 'Settings']) {
        await tester.ensureVisible(find.text(screen));
        await tester.tap(find.text(screen));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byType(WalletPill),
          ),
          findsOneWidget,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(WalletPill),
          matching: find.byType(Image),
        ),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/coins/single_coin.png',
      );
    },
  );

  testWidgets('Game top status contains a wallet without stake display', (
    tester,
  ) async {
    await tester.pumpWidget(localizedGame(humanLeadEngine()));
    await tester.pumpAndSettle();
    expect(find.byType(WalletPill), findsOneWidget);
    expect(find.byKey(const ValueKey('game-stake')), findsNothing);
    expect(find.text('Free Play'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('game-top-controls')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
