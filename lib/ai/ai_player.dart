import '../game/move.dart';
import '../game/move_validator.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import 'legal_move_generator.dart';

class AiPlayer {
  AiPlayer({LegalMoveGenerator? generator, MoveValidator? validator})
    : _generator = generator ?? LegalMoveGenerator(),
      _validator = validator ?? MoveValidator();

  final LegalMoveGenerator _generator;
  final MoveValidator _validator;

  Move? chooseMove(
    Player player, {
    Move? currentMove,
    bool mustContainThreeSpades = false,
    bool allowOnlyChop = false,
  }) {
    final moves = _generator.generate(player.hand).where((move) {
      if (mustContainThreeSpades && !move.cards.contains(_threeSpades)) {
        return false;
      }
      if (currentMove == null) return _validator.canLead(move).isValid;
      if (allowOnlyChop && !_validator.isChopAgainstTwos(move, currentMove)) {
        return false;
      }
      return _validator.canBeat(candidate: move, current: currentMove).isValid;
    }).toList();
    if (moves.isEmpty) return null;
    // Generator order sheds useful multi-card plays first, then low ordinary
    // cards, while putting 2s and bombs last. When responding this chooses the
    // lowest successful move and therefore conserves expensive cards.
    return moves.first;
  }

  static const PlayingCard _threeSpades = PlayingCard(
    CardRank.three,
    CardSuit.spades,
  );
}
