// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
}
