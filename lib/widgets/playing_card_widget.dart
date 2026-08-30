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
    final isRed =
        card.suit == CardSuit.hearts || card.suit == CardSuit.diamonds;
    final suitColor = isRed ? const Color(0xFFB3261E) : const Color(0xFF202421);
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
              color: const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                width: selected ? 2.2 : 1,
                color: selected
                    ? Theme.of(context).colorScheme.tertiary
                    : const Color(0xFFCBD0CB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: selected ? .22 : .13),
                  blurRadius: selected ? 7 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(width * .1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.rankDisplay,
                    style: TextStyle(
                      height: .95,
                      fontSize: width * .28,
                      fontWeight: FontWeight.w800,
                      color: suitColor,
                    ),
                  ),
                  Text(
                    card.suitDisplay,
                    style: TextStyle(
                      height: 1,
                      fontSize: width * .26,
                      color: suitColor,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      card.suitDisplay,
                      style: TextStyle(fontSize: width * .32, color: suitColor),
                    ),
                  ),
                ],
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
        color: const Color(0xFF244D58),
        borderRadius: BorderRadius.circular(width * .12),
        border: Border.all(color: const Color(0xFFD6DED9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(width * .14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * .06),
          border: Border.all(color: Colors.white.withValues(alpha: .48)),
        ),
        child: Center(
          child: Transform.rotate(
            angle: .78,
            child: Container(
              width: width * .22,
              height: width * .22,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: .58)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
