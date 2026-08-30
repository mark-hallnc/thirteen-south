import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

class OpponentPanel extends StatelessWidget {
  const OpponentPanel({
    super.key,
    required this.name,
    required this.cardCount,
    required this.cardsLabel,
    required this.passedLabel,
    required this.isPassed,
    required this.isActive,
    this.compact = false,
  });

  final String name;
  final int cardCount;
  final String cardsLabel;
  final String passedLabel;
  final bool isPassed;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: compact ? 88 : 122,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF173E34).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: isActive ? 2 : 1,
          color: isActive ? const Color(0xFFA9D5BD) : Colors.white24,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 31,
            width: 48,
            child: Stack(
              children: [
                for (var index = 0; index < math.min(cardCount, 3); index++)
                  Positioned(
                    left: index * 8,
                    child: const CardBackWidget(width: 22),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$cardCount $cardsLabel',
            style: const TextStyle(color: Color(0xFFC5D7CE), fontSize: 11),
          ),
          if (isPassed)
            Text(
              passedLabel,
              style: const TextStyle(
                color: Color(0xFFFFC6C1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
    return Semantics(
      label: '$name, $cardCount $cardsLabel${isPassed ? ', $passedLabel' : ''}',
      container: true,
      child: panel,
    );
  }
}

class TableMoveArea extends StatelessWidget {
  const TableMoveArea({
    super.key,
    required this.cards,
    required this.emptyLabel,
    this.ownerLabel,
  });

  final List<PlayingCard> cards;
  final String emptyLabel;
  final String? ownerLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: SizedBox(
        key: ValueKey(Object.hashAll(cards)),
        width: 190,
        height: 132,
        child: cards.isEmpty
            ? Center(
                child: Text(
                  emptyLabel,
                  style: const TextStyle(
                    color: Color(0xFFB9CEC3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 92,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const cardWidth = 48.0;
                        final step = cards.length <= 1
                            ? 0.0
                            : math.min(
                                34.0,
                                (constraints.maxWidth - cardWidth) /
                                    (cards.length - 1),
                              );
                        final width = cardWidth + step * (cards.length - 1);
                        final start = (constraints.maxWidth - width) / 2;
                        return Stack(
                          children: [
                            for (var index = 0; index < cards.length; index++)
                              Positioned(
                                left: start + index * step,
                                top: 5,
                                child: PlayingCardWidget(
                                  card: cards[index],
                                  width: cardWidth,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (ownerLabel != null)
                    Text(
                      ownerLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
