import 'package:myriads/api/firestore/parsing_utils.dart';
import 'package:myriads/models/wallet_info.dart';

import 'package:moralis/EVM/chains/chains.dart';
import 'package:moralis/moralis.dart';

class MoralisClient {

  static Future<List<WalletBalanceInfo>> loadEthereumERC20WalletsBalance({
    required List<String> walletsAddresses
  }) async {
    final moralisClient = _initializedMoralisInstance();

    final balances = await moralisClient.evmApi.balance.getNativeBalanceMulti(
      chain: EvmChain.ethereum,
      addresses: walletsAddresses
    );

    if (balances == null) {
      return [];
    }

    List<WalletBalanceInfo> result = [];

    for (final balance in balances) {
      if (balance is Map<String, dynamic>) {
        final address = tryGetValueFromMap<String>(balance, _Keys.address);
        final nativeBalance = tryGetValueFromMap<String>(balance, _Keys.formattedBalance);

        if (address != null && nativeBalance != null) {
          result.add(WalletBalanceInfo(address: address, nativeBalance: nativeBalance));
        }
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

class _Keys {
  static const address = 'address';
  static const formattedBalance = 'balance_formatted';

  // Internal methods
  _Keys._();
}