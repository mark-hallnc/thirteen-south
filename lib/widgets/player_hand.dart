import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

class PlayerHand extends StatelessWidget {
  const PlayerHand({
    super.key,
    required this.cards,
    required this.selectedCards,
    required this.onCardTap,
    required this.enabled,
  });

  final List<PlayingCard> cards;
  final Set<PlayingCard> selectedCards;
  final ValueChanged<PlayingCard> onCardTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 350 ? 50.0 : 56.0;
        final cardHeight = cardWidth * 1.42;
        final count = cards.length;
        final naturalStep = cardWidth * .64;
        final fitStep = count <= 1
            ? 0.0
            : (constraints.maxWidth - cardWidth) / (count - 1);
        final step = math.min(naturalStep, math.max(16, fitStep));
        final handWidth = count <= 1
            ? cardWidth
            : cardWidth + step * (count - 1);
        final start = math.max(0.0, (constraints.maxWidth - handWidth) / 2);

        return SizedBox(
          height: cardHeight + 12,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < cards.length; index++)
                AnimatedPositioned(
                  key: ValueKey(cards[index]),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  left: start + index * step,
                  top: selectedCards.contains(cards[index]) ? 0 : 10,
                  child: PlayingCardWidget(
                    card: cards[index],
                    width: cardWidth,
                    selected: selectedCards.contains(cards[index]),
                    onTap: enabled ? () => onCardTap(cards[index]) : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
