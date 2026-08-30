import 'dart:math';

import '../models/playing_card.dart';

class Deck {
  Deck({Random? random}) : _random = random ?? Random() {
    _cards.addAll(_buildDeck());
  }

  final Random _random;
  final List<PlayingCard> _cards = <PlayingCard>[];

  List<PlayingCard> get cards => List.unmodifiable(_cards);

  void reset() {
    _cards
      ..clear()
      ..addAll(_buildDeck());
    if (_cards.length != 52 || _cards.toSet().length != 52) {
      throw StateError('A Tiến Lên deck must contain 52 unique cards.');
    }
  }

  void shuffle() {
    _cards.shuffle(_random);
  }

  PlayingCard? dealOne() {
    if (_cards.isEmpty) {
      return null;
    }
    return _cards.removeLast();
  }

  List<List<PlayingCard>> dealFourPlayers() {
    final hands = List<List<PlayingCard>>.generate(4, (_) => <PlayingCard>[]);

    for (var round = 0; round < 13; round++) {
      for (var playerIndex = 0; playerIndex < 4; playerIndex++) {
        final card = dealOne();
        if (card == null) {
          break;
        }
        hands[playerIndex].add(card);
      }
    }

    for (final hand in hands) {
      hand.sort();
    }

    return hands;
  }

  List<PlayingCard> _buildDeck() {
    final deck = <PlayingCard>[];
    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        deck.add(PlayingCard(rank, suit));
      }
    }
    return deck;
  }
}
