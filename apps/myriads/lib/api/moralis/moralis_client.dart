import 'package:myriads/models/wallet_info.dart';

import 'package:moralis/EVM/chains/chains.dart';
import 'package:moralis/moralis.dart';

class MoralisClient {

  static Future<List<WalletBalanceInfo>> loadWalletsNetWorthInUsd({
    required List<String> walletsAddresses
  }) async {
    final moralisClient = _initializedMoralisInstance();

    List<WalletBalanceInfo> result = [];

    for (final walletAddress in walletsAddresses) {
      final walletBalance = await moralisClient.evmApi.balance.loadWalletNetWorthInUSD(
        address: walletAddress
      );

      if (walletBalance != null) {
        result.add(WalletBalanceInfo(
          address: walletAddress,
          totalNetWorthInUSD: walletBalance
        ));
      }
    }

    return result;
  }

  static Future<List<WalletTransactionsInfo>> loadEthereumERC20WalletsTransactions({
    required List<String> walletsAddresses
  }) async {
    List<WalletTransactionsInfo> result = [];

    final moralisClient = _initializedMoralisInstance();
    for (final walletAddress in walletsAddresses) {
      final walletTransactions = await moralisClient.evmApi.transaction.getTransactionByWallet(
        address: walletAddress,
        chain: EvmChain.ethereum
      );

      List<TransactionInfo> transactions = [];

      for (final moralisTransaction in walletTransactions) {
        if (moralisTransaction.value == null || moralisTransaction.blockTimestamp == null) {
          continue;
        }

        try {
          final blockDate = DateTime.parse(moralisTransaction.blockTimestamp!);
          final blockTimestamp = blockDate.millisecondsSinceEpoch;

          final transactionAmountString = moralisTransaction.value;
          if (transactionAmountString == null) {
            continue;
          }

          final transactionAmountInWei = double.parse(transactionAmountString);
          final transactionAmountInEth = weiToEth(transactionAmountInWei);

          transactions.add(TransactionInfo(timestamp: blockTimestamp, amount: transactionAmountInEth));
        }
        catch (exception) {
          continue;
        }
      }

      result.add(WalletTransactionsInfo(address: walletAddress, transactions: transactions));
    }

    return result;
  }

  static double weiToEth(double wei) {
    return wei / 10e18;
  }

  // Internal methods

  static Moralis _initializedMoralisInstance() {
    if (_sharedInstance == null) {
      Moralis.setApiKey(apikey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJub25jZSI6IjI2OWIwMzI1LWViMjctNDA5Ni1iY2VjLTYxMGQ4YmJmYjRiYyIsIm9yZ0lkIjoiMzgyNDQyIiwidXNlcklkIjoiMzkyOTY0IiwidHlwZUlkIjoiMDU5MWQ5NzItZGU3OC00ZjNjLTllMTYtNzU4OGQ1NTJjMjg2IiwidHlwZSI6IlBST0pFQ1QiLCJpYXQiOjE3MTAyNDkzNjcsImV4cCI6NDg2NjAwOTM2N30.u0OgFrKWer9nuFq2cimZZfv4CNgeqeYlZxCEpWDHrSM');
      _sharedInstance = Moralis();
    }

    return _sharedInstance!;
  }

  // Internal methods

  MoralisClient._();
  static Moralis? _sharedInstance;
}