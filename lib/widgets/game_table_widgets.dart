import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

enum OpponentPosition { top, left, right }

class OpponentHand extends StatelessWidget {
  const OpponentHand({
    super.key,
    required this.opponentId,
    required this.cardCount,
    required this.position,
  });

  final String opponentId;
  final int cardCount;
  final OpponentPosition position;

  @override
  Widget build(BuildContext context) {
    final isTop = position == OpponentPosition.top;
    final cardWidth = isTop ? 52.0 : 50.0;
    final cardHeight = cardWidth * 1.42;
    final laidOutWidth = isTop ? cardWidth : cardHeight;
    final laidOutHeight = isTop ? cardHeight : cardWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableExtent = isTop
            ? constraints.maxWidth
            : constraints.maxHeight;
        final cardExtent = isTop ? laidOutWidth : laidOutHeight;
        final step = cardCount <= 1
            ? 0.0
            : math.max(
                3.5,
                math.min(
                  isTop ? 20.0 : 10.0,
                  (availableExtent - cardExtent) / (cardCount - 1),
                ),
              );
        final fanExtent = cardCount == 0
            ? 0.0
            : math.min(availableExtent, cardExtent + step * (cardCount - 1));

        return SizedBox(
          width: isTop ? fanExtent : laidOutWidth,
          height: isTop ? laidOutHeight : fanExtent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < cardCount; index++)
                Positioned(
                  left: isTop ? index * step : 0,
                  top: isTop ? 0 : index * step,
                  child: isTop
                      ? CardBackWidget(
                          key: ValueKey(
                            'opponent-$opponentId-card-back-$index',
                          ),
                          width: cardWidth,
                        )
                      : RotatedBox(
                          key: ValueKey(
                            'opponent-$opponentId-card-rotation-$index',
                          ),
                          quarterTurns: position == OpponentPosition.left
                              ? 3
                              : 1,
                          child: CardBackWidget(
                            key: ValueKey(
                              'opponent-$opponentId-card-back-$index',
                            ),
                            width: cardWidth,
                          ),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class OpponentPanel extends StatelessWidget {
  const OpponentPanel({
    super.key,
    required this.opponentId,
    required this.name,
    required this.cardCount,
    required this.cardsLabel,
    required this.passedLabel,
    required this.isPassed,
    required this.isActive,
    required this.position,
  });

  final String opponentId;
  final String name;
  final int cardCount;
  final String cardsLabel;
  final String passedLabel;
  final bool isPassed;
  final bool isActive;
  final OpponentPosition position;

  @override
  Widget build(BuildContext context) {
    final isTop = position == OpponentPosition.top;
    Widget label() => AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isTop ? 116 : 72,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF173E34).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          width: isActive ? 2 : 1,
          color: isActive ? const Color(0xFFA9D5BD) : Colors.white24,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$cardCount $cardsLabel',
            key: ValueKey('opponent-$opponentId-card-count'),
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

    final panel = isTop
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 74,
                child: OpponentHand(
                  opponentId: opponentId,
                  cardCount: cardCount,
                  position: position,
                ),
              ),
              const SizedBox(height: 4),
              label(),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 76,
                height: 165,
                child: OpponentHand(
                  opponentId: opponentId,
                  cardCount: cardCount,
                  position: position,
                ),
              ),
              const SizedBox(height: 4),
              label(),
            ],
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
    return LayoutBuilder(
      builder: (context, outerConstraints) => AnimatedSwitcher(
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
          width: outerConstraints.maxWidth,
          height: 145,
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
                      width: outerConstraints.maxWidth,
                      height: 112,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth < 200
                              ? 72.0
                              : 76.0;
                          final step = cards.length <= 1
                              ? 0.0
                              : math.min(
                                  cardWidth * .62,
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
                                  top: 3,
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
                    if (ownerLabel != null) ...[
                      const SizedBox(height: 7),
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
                  ],
                ),
        ),
      ),
    );
  }
}
