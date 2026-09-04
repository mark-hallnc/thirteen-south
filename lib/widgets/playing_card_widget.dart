import 'package:flutter/material.dart';

import '../models/playing_card.dart';

class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.card,
    this.width = 58,
    this.selected = false,
    this.onTap,
  });

  final PlayingCard card;
  final double width;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    final radius = width * .12;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: card.shortName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('card-${card.rank.name}-${card.suit.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: selected
                  ? Border.all(
                      width: 2.2,
                      color: Theme.of(context).colorScheme.tertiary,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? .22 : .13),
                  blurRadius: selected ? 7 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                width: width,
                height: height,
                child: Image.asset(
                  card.assetPath,
                  width: width,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardBackWidget extends StatelessWidget {
  const CardBackWidget({super.key, this.width = 30});

  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * .12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/cards_png/back.png',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
