import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/widgets/wallet_pill.dart';
import 'package:tien_len/widgets/stake_pill.dart';
import 'package:tien_len/widgets/stake_selector.dart';

import 'ui_test.dart' show humanLeadEngine, localizedGame;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home wallet is in the header, with wallets on Rules and Settings', (tester) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    expect(find.text('500 Coins'), findsNothing);
    expect(find.byKey(const ValueKey('home-coin-balance')), findsNothing);
    expect(find.descendant(of: find.byType(AppBar), matching: find.byType(WalletPill)), findsOneWidget);
    for (final screen in ['Rules', 'Settings']) {
      await tester.tap(find.text(screen));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppBar), matching: find.byType(WalletPill)), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    final image = tester.widget<Image>(find.descendant(
      of: find.byType(WalletPill), matching: find.byType(Image)));
    expect((image.image as AssetImage).assetName, 'assets/coins/single_coin.png');
  });

  testWidgets('Game top status contains a wallet and separate stake pill', (tester) async {
    await tester.pumpWidget(localizedGame(humanLeadEngine()));
    await tester.pumpAndSettle();
    expect(find.byType(WalletPill), findsOneWidget);
    expect(find.byType(StakePill), findsOneWidget);
    expect(find.descendant(of: find.byType(StakePill), matching: find.text('Free Play')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('stake panel has a coin header, balanced options and unchanged selection', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    int? selected;
    final context = tester.element(find.byType(WalletPill));
    showDialog<int>(context: context, builder: (_) => const StakeSelector(balance: 25))
        .then((value) => selected = value);
    await tester.pumpAndSettle();
    expect(find.text('Choose your stake'), findsOneWidget);
    expect(find.text('Balance: 25 Coins'), findsNothing);
    final panel = find.byType(StakeSelector);
    expect(tester.takeException(), isNull);
    expect(find.descendant(of: panel, matching: find.byType(Dialog)), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.byType(AlertDialog)), findsNothing);
    expect(find.descendant(of: panel, matching: find.byType(LayoutBuilder)), findsNothing);
    expect(find.descendant(of: panel, matching: find.byType(IntrinsicWidth)), findsNothing);
    expect(find.descendant(of: panel, matching: find.byType(IntrinsicHeight)), findsNothing);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('stake-0'))).selected, isTrue);
    expect(find.descendant(of: panel, matching: find.byType(Image)), findsNWidgets(2));
    for (final stake in [0, 10, 25, 50, 100]) {
      final chip = tester.widget<ChoiceChip>(find.byKey(ValueKey('stake-$stake')));
      expect(chip.onSelected != null, stake <= 25);
    }
    expect(tester.getTopLeft(find.byKey(const ValueKey('stake-50'))).dy,
      tester.getTopLeft(find.byKey(const ValueKey('stake-100'))).dy);
    await tester.tap(find.byKey(const ValueKey('stake-25')));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('stake-25'))).selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('start-staked-game')));
    await tester.pumpAndSettle();
    expect(selected, 25);
    expect(tester.takeException(), isNull);
  });
}
