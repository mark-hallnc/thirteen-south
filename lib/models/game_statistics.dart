class GameStatistics {
  const GameStatistics({
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
  });

  final int gamesPlayed;
  final int wins;
  final int losses;
  final int currentWinStreak;
  final int bestWinStreak;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  GameStatistics recordResult({required bool humanWon}) {
    final streak = humanWon ? currentWinStreak + 1 : 0;
    return GameStatistics(
      gamesPlayed: gamesPlayed + 1,
      wins: wins + (humanWon ? 1 : 0),
      losses: losses + (humanWon ? 0 : 1),
      currentWinStreak: streak,
      bestWinStreak: streak > bestWinStreak ? streak : bestWinStreak,
    );
  }
}
