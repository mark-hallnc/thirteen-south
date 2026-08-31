import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @easyDescription.
  ///
  /// In en, this message translates to:
  /// **'Relaxed opponents that often choose simple plays.'**
  String get easyDescription;

  /// No description provided for @normalDescription.
  ///
  /// In en, this message translates to:
  /// **'Balanced play with basic strategy.'**
  String get normalDescription;

  /// No description provided for @hardDescription.
  ///
  /// In en, this message translates to:
  /// **'More careful play with stronger strategic decisions.'**
  String get hardDescription;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games played'**
  String get gamesPlayed;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @resetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics'**
  String get resetStatistics;

  /// No description provided for @resetStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset statistics?'**
  String get resetStatisticsTitle;

  /// No description provided for @resetStatisticsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset all wins, losses, and streaks. Your language and difficulty will not change.'**
  String get resetStatisticsMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Thirteen South: Tiến Lên'**
  String get appTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @computer.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String computer(int number);

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @playerTurn.
  ///
  /// In en, this message translates to:
  /// **'{player}\'s turn'**
  String playerTurn(String player);

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @cardsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Cards remaining'**
  String get cardsRemaining;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cards;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @invalidMove.
  ///
  /// In en, this message translates to:
  /// **'Those cards cannot be played.'**
  String get invalidMove;

  /// No description provided for @mustIncludeThreeSpades.
  ///
  /// In en, this message translates to:
  /// **'The opening play must include 3♠.'**
  String get mustIncludeThreeSpades;

  /// No description provided for @moveDoesNotBeat.
  ///
  /// In en, this message translates to:
  /// **'That play does not beat the current cards.'**
  String get moveDoesNotBeat;

  /// No description provided for @cannotPassWhileLeading.
  ///
  /// In en, this message translates to:
  /// **'You cannot pass when you have the lead.'**
  String get cannotPassWhileLeading;

  /// No description provided for @notYourTurn.
  ///
  /// In en, this message translates to:
  /// **'It is not your turn.'**
  String get notYourTurn;

  /// No description provided for @cardNotInHand.
  ///
  /// In en, this message translates to:
  /// **'Those cards are not in your hand.'**
  String get cardNotInHand;

  /// No description provided for @youWin.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get youWin;

  /// No description provided for @playerWins.
  ///
  /// In en, this message translates to:
  /// **'{player} wins.'**
  String playerWins(String player);

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @lead.
  ///
  /// In en, this message translates to:
  /// **'Lead: {player}'**
  String lead(String player);

  /// No description provided for @selectedCards.
  ///
  /// In en, this message translates to:
  /// **'Selected cards'**
  String get selectedCards;

  /// No description provided for @leadAPlay.
  ///
  /// In en, this message translates to:
  /// **'Lead a play'**
  String get leadAPlay;

  /// No description provided for @southernVietnameseCardGame.
  ///
  /// In en, this message translates to:
  /// **'Southern Vietnamese card game'**
  String get southernVietnameseCardGame;

  /// No description provided for @rulesGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get rulesGoalTitle;

  /// No description provided for @rulesGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first player to play every card in your hand.'**
  String get rulesGoalBody;

  /// No description provided for @rulesCardOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Order'**
  String get rulesCardOrderTitle;

  /// No description provided for @rulesCardOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Ranks run from 3 (low) through A, then 2 (high). For equal ranks: spades, clubs, diamonds, hearts.'**
  String get rulesCardOrderBody;

  /// No description provided for @rulesOpeningTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening Play'**
  String get rulesOpeningTitle;

  /// No description provided for @rulesOpeningBody.
  ///
  /// In en, this message translates to:
  /// **'The player holding 3♠ starts. The first combination must contain 3♠.'**
  String get rulesOpeningBody;

  /// No description provided for @rulesCombinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Valid Combinations'**
  String get rulesCombinationsTitle;

  /// No description provided for @rulesCombinationsBody.
  ///
  /// In en, this message translates to:
  /// **'Play singles, pairs, triples, straights of at least three cards, four of a kind, or sequences of at least three consecutive pairs. A 2 cannot be part of a straight.'**
  String get rulesCombinationsBody;

  /// No description provided for @rulesPassingTitle.
  ///
  /// In en, this message translates to:
  /// **'Passing'**
  String get rulesPassingTitle;

  /// No description provided for @rulesPassingBody.
  ///
  /// In en, this message translates to:
  /// **'After passing, you normally sit out until the table clears. The unbeaten player then leads any valid combination.'**
  String get rulesPassingBody;

  /// No description provided for @rulesChoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Chopping 2s'**
  String get rulesChoppingTitle;

  /// No description provided for @rulesChoppingBody.
  ///
  /// In en, this message translates to:
  /// **'Four of a kind or three consecutive pairs can chop one 2. Four consecutive pairs chop two 2s, and five consecutive pairs chop three 2s. A passed player may still chop when their turn arrives.'**
  String get rulesChoppingBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
