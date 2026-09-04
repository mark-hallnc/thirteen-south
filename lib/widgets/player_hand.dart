import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

class PlayerHand extends StatefulWidget {
  const PlayerHand({
    super.key,
    required this.cards,
    required this.selectedCards,
    required this.onCardTap,
    required this.enabled,
    this.onReorder,
  });

  final List<PlayingCard> cards;
  final Set<PlayingCard> selectedCards;
  final ValueChanged<PlayingCard> onCardTap;
  final bool enabled;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  State<PlayerHand> createState() => _PlayerHandState();
}

class _PlayerHandState extends State<PlayerHand> {
  PlayingCard? _dragged;
  double _dragLeft = 0;
  double _lastPointerX = 0;

  @override
  void didUpdateWidget(PlayerHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.cards.contains(_dragged) || widget.onReorder == null) {
      _dragged = null;
    }
  }

  void _endDrag() => setState(() => _dragged = null);

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final selectedCards = widget.selectedCards;
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
              // Paint the dragged card last so it stays above its neighbors.
              for (final card in [
                ...cards.where((card) => card != _dragged),
                if (_dragged != null) _dragged!,
              ])
                AnimatedPositioned(
                  key: ValueKey(card),
                  duration: card == _dragged
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  left: card == _dragged
                      ? _dragLeft
                      : start + cards.indexOf(card) * step,
                  top: card == _dragged
                      ? -8
                      : selectedCards.contains(card) ? 0 : 10,
                  child: GestureDetector(
                    onHorizontalDragStart: widget.onReorder == null ? null : (details) {
                      setState(() {
                        _dragged = card;
                        _dragLeft = start + cards.indexOf(card) * step;
                        _lastPointerX = details.globalPosition.dx;
                      });
                    },
                    onHorizontalDragUpdate: widget.onReorder == null ? null : (details) {
                      if (_dragged != card) return;
                      setState(() {
                        _dragLeft = (_dragLeft + details.globalPosition.dx - _lastPointerX)
                            .clamp(start, start + (cards.length - 1) * step);
                        _lastPointerX = details.globalPosition.dx;
                      });
                      final oldIndex = cards.indexOf(card);
                      final newIndex = ((_dragLeft - start) / step)
                          .round().clamp(0, cards.length - 1);
                      if (oldIndex != newIndex) widget.onReorder!(oldIndex, newIndex);
                    },
                    onHorizontalDragEnd: widget.onReorder == null ? null : (_) => _endDrag(),
                    onHorizontalDragCancel: widget.onReorder == null ? null : _endDrag,
                    child: PlayingCardWidget(
                      card: card,
                      width: cardWidth,
                      selected: selectedCards.contains(card),
                      onTap: widget.enabled ? () => widget.onCardTap(card) : null,
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
