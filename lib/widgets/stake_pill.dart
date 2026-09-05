import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

class StakePill extends StatelessWidget {
  const StakePill({super.key, required this.stake});
  final int stake;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: ShapeDecoration(
        color: theme.colorScheme.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Text(stake == 0 ? loc.freePlay : loc.stakeAmount(stake),
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
    );
  }
}
