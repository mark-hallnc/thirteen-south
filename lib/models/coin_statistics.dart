class CoinStatistics {
  const CoinStatistics({
    this.balance = 500,
    this.highestBalance = 500,
    this.won = 0,
    this.lost = 0,
  });

  final int balance;
  final int highestBalance;
  final int won;
  final int lost;

  Map<String, dynamic> toJson() => {
    'coin_balance': balance,
    'highest_coin_balance': highestBalance,
    'coins_won': won,
    'coins_lost': lost,
  };

  factory CoinStatistics.fromJson(Map<String, dynamic> json) => CoinStatistics(
    balance: json['coin_balance'] as int? ?? 500,
    highestBalance: json['highest_coin_balance'] as int? ?? 500,
    won: json['coins_won'] as int? ?? 0,
    lost: json['coins_lost'] as int? ?? 0,
  );
}

class CoinEconomy {
  static const stakes = [0, 10, 25, 50, 100];

  static int payout(int stake, bool humanWon) =>
      humanWon ? (stake == 0 ? 10 : stake * 4) : 0;

  static int netChange(int stake, bool humanWon) =>
      payout(stake, humanWon) - stake;
}
