class WalletBalanceInfo {

  // Public methods and properties

  final String address;
  final double? totalNetWorthInUSD;

  WalletBalanceInfo({
    required this.address,
    required this.totalNetWorthInUSD
  });

}

class TransactionInfo {

  // Public methods and properties

  final int timestamp;
  final double amount;

  TransactionInfo({
    required this.timestamp,
    required this.amount
  });

}

class WalletTransactionsInfo {

  // Public methods and properties

  final String address;
  final List<TransactionInfo> transactions;

  WalletTransactionsInfo({
    required this.address,
    required this.transactions
  });

}