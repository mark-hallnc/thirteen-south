import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';
import '../widgets/wallet_pill.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sections = [
      (loc.rulesGoalTitle, loc.rulesGoalBody, Icons.flag_outlined),
      (
        loc.rulesCardOrderTitle,
        loc.rulesCardOrderBody,
        Icons.swap_vert_rounded,
      ),
      (loc.rulesOpeningTitle, loc.rulesOpeningBody, Icons.play_circle_outline),
      (
        loc.rulesCombinationsTitle,
        loc.rulesCombinationsBody,
        Icons.style_outlined,
      ),
      (loc.rulesPassingTitle, loc.rulesPassingBody, Icons.skip_next_rounded),
      (
        loc.rulesChoppingTitle,
        loc.rulesChoppingBody,
        Icons.content_cut_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.rules), bottom: const WalletStatusRow()),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final section = sections[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      section.$3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.$1,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            section.$2,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.45,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
