// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Thirteen South: Tiến Lên';

  @override
  String get play => 'Đánh';

  @override
  String get pass => 'Bỏ lượt';

  @override
  String get newGame => 'Ván mới';

  @override
  String get settings => 'Cài đặt';

  @override
  String get rules => 'Luật chơi';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get systemDefault => 'Theo hệ thống';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get you => 'Bạn';

  @override
  String get player => 'Người chơi';

  @override
  String computer(int number) {
    return 'Máy $number';
  }

  @override
  String get yourTurn => 'Lượt của bạn';

  @override
  String playerTurn(String player) {
    return 'Lượt của $player';
  }

  @override
  String get waiting => 'Đang chờ';

  @override
  String get cardsRemaining => 'Số lá còn lại';

  @override
  String get cards => 'lá';

  @override
  String get winner => 'Người thắng';

  @override
  String get gameOver => 'Kết thúc ván';

  @override
  String get passed => 'Đã bỏ lượt';

  @override
  String get invalidMove => 'Không thể đánh những lá bài này.';

  @override
  String get mustIncludeThreeSpades => 'Lượt mở đầu phải có 3♠.';

  @override
  String get moveDoesNotBeat => 'Lượt đánh này không chặn được bài trên bàn.';

  @override
  String get cannotPassWhileLeading => 'Bạn không thể bỏ lượt khi đang đi đầu.';

  @override
  String get notYourTurn => 'Chưa đến lượt của bạn.';

  @override
  String get cardNotInHand => 'Những lá bài này không có trong tay bạn.';

  @override
  String get youWin => 'Bạn thắng!';

  @override
  String playerWins(String player) {
    return '$player thắng.';
  }

  @override
  String get table => 'Bàn';

  @override
  String lead(String player) {
    return 'Đang giữ lượt: $player';
  }

  @override
  String get selectedCards => 'Bài đã chọn';

  @override
  String get leadAPlay => 'Hãy đánh bài';

  @override
  String get southernVietnameseCardGame => 'Trò chơi bài miền Nam';

  @override
  String get rulesGoalTitle => 'Mục tiêu';

  @override
  String get rulesGoalBody => 'Trở thành người đầu tiên đánh hết bài trên tay.';

  @override
  String get rulesCardOrderTitle => 'Thứ tự bài';

  @override
  String get rulesCardOrderBody =>
      'Thứ hạng từ 3 (thấp) đến A, sau đó là 2 (cao). Cùng hạng: bích, chuồn, rô, cơ.';

  @override
  String get rulesOpeningTitle => 'Lượt mở đầu';

  @override
  String get rulesOpeningBody =>
      'Người giữ 3♠ đi trước. Bộ bài đầu tiên phải có 3♠.';

  @override
  String get rulesCombinationsTitle => 'Các bộ bài hợp lệ';

  @override
  String get rulesCombinationsBody =>
      'Có thể đánh rác, đôi, sám, sảnh từ ba lá, tứ quý hoặc từ ba đôi thông. Lá 2 không nằm trong sảnh.';

  @override
  String get rulesPassingTitle => 'Bỏ lượt';

  @override
  String get rulesPassingBody =>
      'Sau khi bỏ lượt, bạn thường phải chờ đến khi vòng bài kết thúc. Người giữ bài cao nhất sẽ đi đầu.';

  @override
  String get rulesChoppingTitle => 'Chặt 2';

  @override
  String get rulesChoppingBody =>
      'Tứ quý hoặc ba đôi thông chặt một lá 2. Bốn đôi thông chặt đôi 2, năm đôi thông chặt ba lá 2. Người đã bỏ lượt vẫn có thể chặt khi đến lượt.';
}
