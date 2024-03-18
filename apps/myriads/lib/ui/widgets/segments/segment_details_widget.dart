import 'package:collection/collection.dart';
import 'package:myriads/api/firestore/firestore_client.dart';
import 'package:myriads/api/moralis/moralis_client.dart';
import 'package:myriads/models/wallet_info.dart';
import 'package:myriads/ui/theme/app_theme.dart';

import 'package:flutter/cupertino.dart';
import 'package:myriads/ui/widgets/copyable_text_widget.dart';
import 'package:myriads/utils/delayed_utils.dart';
import 'package:myriads/utils/widget_extensions.dart';

// ignore: must_be_immutable
class SegmentDetailsWidget extends StatefulWidget {

  // Public methods and properties

  SegmentDetailsWidget({super.key});

  void reload({
    required String domain,
    required String segmentId
  }) {
    DelayedUtils.waitForConditionAndExecute(
      condition: () { return _state != null; },
      callback: () {
        _state!.reload(domain: domain, segmentId: segmentId);
      }
    );
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _SegmentDetailsWidgetState(
      onDispose: () => _state = null
    );
    return _state!;
  }

  // Internal fields

  _SegmentDetailsWidgetState? _state;

}

class _SegmentDetailsWidgetState extends State<SegmentDetailsWidget> {

  // Public methods and properties

  _SegmentDetailsWidgetState({
    required VoidCallback onDispose
  })
    : _onDispose = onDispose;

  void reload({
    required String domain,
    required String segmentId
  }) {
    updateState( () {
      _loadedSegmentItems = null;
    });

    _reloadSegment(domain: domain, segmentId: segmentId);
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    if (_loadedSegmentItems == null) {
      return const CupertinoActivityIndicator(color: AppTheme.textColorBody);
    }

    return _buildItems();
  }

  @override
  void dispose() {
    _onDispose();

    super.dispose();
  }

  // Internal methods

  Widget _buildItems() {
    var text = '';

    if (_loadedSegmentItems != null) {
      for (final segmentItem in _loadedSegmentItems!) {
        var adjustedUserId = segmentItem.userId;
        if (adjustedUserId.startsWith('ga_')) {
          adjustedUserId = adjustedUserId.substring(3);
        }
        adjustedUserId = adjustedUserId.replaceAll('_', '.');

        text += '$adjustedUserId, ${segmentItem.walletAddress}, ${segmentItem
          .walletBalance}, ${segmentItem.transactionsCount}\n';
      }
    }

    return Container(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            _title!,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 20
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _description!,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 14
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Segment parameters: $_segmentParameters',
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 10
            ),
          ),
          const SizedBox(height: 36),
          _loadedSegmentItems == null || _loadedSegmentItems!.isEmpty
            ? const Center(
                child: Text(
                  'There are no items matching your criteria',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: AppTheme.textColorBody,
                    fontSize: 16
                  ),
                ),
              )
            : CopyableTextWidget(title: 'User ID, Wallet Address, Balance (ETH), Transactions Count', text: text)
        ],
      )
    );
  }

  void _reloadSegment({
    required String domain,
    required String segmentId
  }) async {
    _loadedSegmentItems = null;
    String segmentParameters = '';

    List<_SegmentItem> items = [];

    final segment = await FirestoreClient.loadSegment(domain: domain, segmentId: segmentId);
    if (segment == null) {
      return;
    }

    segmentParameters += segment.minWalletAgeInDays != null
      ? 'wallet age from: \'${segment.minWalletAgeInDays}\''
      : 'wallet age from: Any';
    segmentParameters += segment.maxWalletAgeInDays != null
      ? ', wallet age to: \'${segment.maxWalletAgeInDays}\''
      : ', wallet age to: Any';
    segmentParameters += segment.transactionsCountPeriodInDays != null
      ? ', transactions count period (days): \'${segment.transactionsCountPeriodInDays}\''
      : ', transactions count period (days): Any';
    segmentParameters += segment.minTransactionsCountPerPeriod != null
      ? ', min transactions count per period: \'${segment.minTransactionsCountPerPeriod}\''
      : ', min transactions count per period: Any';
    segmentParameters += segment.maxTransactionsCountPerPeriod != null
      ? ', max transactions count per period: \'${segment.maxTransactionsCountPerPeriod}\''
      : ', max transactions count per period: Any';

    final userWallets = await FirestoreClient.loadAllUsersWallets(domain);
    List<String> walletsAddresses = [];
    for (final userWalletInfo in userWallets) {
      walletsAddresses.addAll(userWalletInfo.wallets);
    }

    final walletsBalances = await MoralisClient.loadEthereumERC20WalletsBalance(walletsAddresses: walletsAddresses);
    final walletsTransactions = await MoralisClient.loadEthereumERC20WalletsTransactions(walletsAddresses: walletsAddresses);

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfCurrentDayTimestamp = startOfDay.millisecondsSinceEpoch;

    for (final walletBalance in walletsBalances) {
      final matchingWalletTransactions = walletsTransactions.firstWhereOrNull(
        (element) => element.address.toLowerCase() == walletBalance.address.toLowerCase()
      );
      final userId = userWallets.firstWhere((element) => element.wallets.contains(walletBalance.address)).userId;

      if (matchingWalletTransactions == null || matchingWalletTransactions.transactions.isEmpty) {
        items.add(_SegmentItem(
          userId: userId,
          walletAddress: walletBalance.address,
          walletBalance: walletBalance.nativeBalance,
          transactionsCount: 0
        ));
        continue;
      }

      // Transactions come in last-to-first order so the last one is the oldest one
      final firstTransaction = matchingWalletTransactions.transactions.last;

      if (segment.minWalletAgeInDays != null) {
        final latestFirstTransactionTimestamp =
          startOfCurrentDayTimestamp - segment.minWalletAgeInDays! * _Constants.millisecondsPerDay;

        if (firstTransaction.timestamp > latestFirstTransactionTimestamp) {
          continue;
        }
      }

      if (segment.maxWalletAgeInDays != null) {
        final earliestFirstTransactionTimestamp =
          startOfCurrentDayTimestamp - segment.maxWalletAgeInDays! * _Constants.millisecondsPerDay;

        if (firstTransaction.timestamp < earliestFirstTransactionTimestamp) {
          continue;
        }
      }

      int transactionsPerPeriodCount = matchingWalletTransactions.transactions.length;

      if (segment.transactionsCountPeriodInDays != null) {
        final periodStartTimestamp = startOfCurrentDayTimestamp - _Constants.millisecondsPerDay * segment.transactionsCountPeriodInDays!;
        transactionsPerPeriodCount = 0;
        for (final currentTransaction in matchingWalletTransactions.transactions) {
          if (currentTransaction.timestamp > periodStartTimestamp) {
            transactionsPerPeriodCount++;
          }
        }

        if (segment.minTransactionsCountPerPeriod != null && transactionsPerPeriodCount < segment.minTransactionsCountPerPeriod! ||
            segment.maxTransactionsCountPerPeriod != null && transactionsPerPeriodCount > segment.maxTransactionsCountPerPeriod!) {
          continue;
        }
      }

      items.add(
        _SegmentItem(
          userId: userId,
          walletAddress: walletBalance.address,
          walletBalance: walletBalance.nativeBalance,
          transactionsCount: transactionsPerPeriodCount
        )
      );
    }

    updateState(() {
      _title = segment.title;
      _description = segment.description;
      _loadedSegmentItems = items;
      _segmentParameters = segmentParameters;
    });
  }

  // Internal fields

  VoidCallback _onDispose;
  String? _title;
  String? _description;
  List<_SegmentItem>? _loadedSegmentItems;
  String _segmentParameters = '';

}

class _SegmentItem {

  // Public methods and properties

  final String userId;
  final String walletAddress;
  final String walletBalance;
  final int transactionsCount;

  _SegmentItem({
    required this.userId,
    required this.walletAddress,
    required this.walletBalance,
    required this.transactionsCount
  });

}

class _Constants {

  static const int millisecondsPerDay = 60 * 60 * 24 * 1000;

}
