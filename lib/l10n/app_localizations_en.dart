// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get playFor => 'Play For';

  @override
  String get coins => 'Coins';

  @override
  String get balance => 'Balance';

  @override
  String get free => 'Free';

  @override
  String get freePlay => 'Free Play';

  @override
  String get stake => 'Stake';

  @override
  String get coinBalance => 'Coin balance';

  @override
  String get highestBalance => 'Highest balance';

  @override
  String get coinsWon => 'Coins won';

  @override
  String get coinsLost => 'Coins lost';

  @override
  String get noCoinChange => 'No coin change';

  @override
  String get startGame => 'Start Game';

  @override
  String coinAmount(Object amount) {
    return '$amount Coins';
  }

  @override
  String coinBalanceAmount(int amount) {
    return 'Balance: $amount Coins';
  }

  @override
  String stakeAmount(int amount) {
    return 'Stake: $amount';
  }

  @override
  String get leaveGameTitle => 'Leave game?';

  @override
  String get leaveGameMessage => 'You can continue this game later.';

  @override
  String get continueGame => 'Continue Game';

  @override
  String get startNewGameTitle => 'Start new game?';

  @override
  String get replaceSavedGameMessage => 'Your saved game will be replaced.';

  @override
  String get startNewGame => 'Start New Game';

  @override
  String get leave => 'Leave';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get normal => 'Normal';

  @override
  String get hard => 'Hard';

  @override
  String get easyDescription =>
      'Relaxed opponents that often choose simple plays.';

  @override
  String get normalDescription => 'Balanced play with basic strategy.';

  @override
  String get hardDescription =>
      'More careful play with stronger strategic decisions.';

  @override
  String get statistics => 'Statistics';

  @override
  String get gamesPlayed => 'Games played';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get winRate => 'Win rate';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get bestStreak => 'Best streak';

  @override
  String get resetStatistics => 'Reset Statistics';

  @override
  String get resetStatisticsTitle => 'Reset statistics?';

  @override
  String get resetStatisticsMessage =>
      'This will reset all wins, losses, and streaks. Your language and difficulty will not change.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get appTitle => 'Thirteen South: Tiến Lên';

  @override
  String get play => 'Play';

  @override
  String get pass => 'Pass';

  @override
  String get newGame => 'New Game';

  @override
  String get settings => 'Settings';

  @override
  String get rules => 'Rules';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get you => 'You';

  @override
  String get player => 'Player';

  @override
  String computer(int number) {
    return 'Player $number';
  }

  @override
  String get yourTurn => 'Your turn';

  @override
  String playerTurn(String player) {
    return '$player\'s turn';
  }

  @override
  String get waiting => 'Waiting';

  @override
  String get cardsRemaining => 'Cards remaining';

  @override
  String get cards => 'cards';

  @override
  String get winner => 'Winner';

  @override
  String get gameOver => 'Game Over';

  @override
  String get passed => 'Passed';

  @override
  String get invalidMove => 'Those cards cannot be played.';

  @override
  String get mustIncludeThreeSpades => 'The opening play must include 3♠.';

  @override
  String get moveDoesNotBeat => 'That play does not beat the current cards.';

  @override
  String get cannotPassWhileLeading =>
      'You cannot pass when you have the lead.';

  @override
  String get notYourTurn => 'It is not your turn.';

  @override
  String get cardNotInHand => 'Those cards are not in your hand.';

  @override
  String get youWin => 'You win!';

  @override
  String playerWins(String player) {
    return '$player wins.';
  }

  @override
  String get table => 'Table';

  @override
  String lead(String player) {
    return 'Lead: $player';
  }

  @override
  String get selectedCards => 'Selected cards';

  @override
  String get leadAPlay => 'Lead a play';

  @override
  String get southernVietnameseCardGame => 'Southern Vietnamese card game';

  @override
  String get rulesGoalTitle => 'Goal';

  @override
  String get rulesGoalBody =>
      'Be the first player to play every card in your hand.';

  @override
  String get rulesCardOrderTitle => 'Card Order';

  @override
  String get rulesCardOrderBody =>
      'Ranks run from 3 (low) through A, then 2 (high). For equal ranks: spades, clubs, diamonds, hearts.';

  @override
  String get rulesOpeningTitle => 'Opening Play';

  @override
  String get rulesOpeningBody =>
      'The player holding 3♠ starts. The first combination must contain 3♠.';

  @override
  String get rulesCombinationsTitle => 'Valid Combinations';

  @override
  String get rulesCombinationsBody =>
      'Play singles, pairs, triples, straights of at least three cards, four of a kind, or sequences of at least three consecutive pairs. A 2 cannot be part of a straight.';

  @override
  String get rulesPassingTitle => 'Passing';

  @override
  String get rulesPassingBody =>
      'After passing, you normally sit out until the table clears. The unbeaten player then leads any valid combination.';

  @override
  String get rulesChoppingTitle => 'Chopping 2s';

  @override
  String get rulesChoppingBody =>
      'Four of a kind or three consecutive pairs can chop one 2. Four consecutive pairs chop two 2s, and five consecutive pairs chop three 2s. A passed player may still chop when their turn arrives.';

  @override
  String get sound => 'Sound';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get soundEffectsDescription => 'Play sounds during games';
}
