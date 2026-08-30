import 'player.dart';
import '../game/move.dart';

class GameState {
  GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.currentTableMove,
    this.currentMovePlayerIndex,
    Set<String>? passedPlayerIds,
    this.openingRuleActive = true,
    this.isActive = false,
    this.winner,
  }) {
    this.passedPlayerIds.addAll(passedPlayerIds ?? const <String>{});
  }

  final List<Player> players;
  int currentPlayerIndex;
  Move? currentTableMove;
  int? currentMovePlayerIndex;
  final Set<String> passedPlayerIds = <String>{};
  bool openingRuleActive;
  bool isActive;
  Player? winner;

  Player get currentPlayer => players[currentPlayerIndex];
  Player? get currentMovePlayer =>
      currentMovePlayerIndex == null ? null : players[currentMovePlayerIndex!];

  bool hasPassed(String playerId) => passedPlayerIds.contains(playerId);
}
