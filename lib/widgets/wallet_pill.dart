import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../preferences_scope.dart';

class WalletPill extends StatelessWidget {
  const WalletPill({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: AppLocalizations.of(context)!.coinAmount(balance),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/coins/single_coin.png', width: 26, height: 26),
            const SizedBox(width: 8),
            Text(
              '$balance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shared header row keeps wallets out of title and navigation space.
class WalletStatusRow extends StatelessWidget implements PreferredSizeWidget {
  const WalletStatusRow({super.key, this.trailing});

  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: WalletPill(
              balance: PreferencesScope.maybeOf(context)?.coinBalance ?? 500,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(child: trailing!),
        ],
      ],
    ),
  );
}
