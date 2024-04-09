import 'package:myriads/api/firestore/firestore_client.dart';
import 'package:myriads/api/moralis/moralis_client.dart';
import 'package:myriads/models/segment_info.dart';
import 'package:myriads/models/visitor_info.dart';
import 'package:myriads/models/wallet_info.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/copyable_text_widget.dart';
import 'package:myriads/utils/delayed_utils.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

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
    List<_SegmentItem> items = [];

    final segment = await FirestoreClient.loadSegment(domain: domain, segmentId: segmentId);
    if (segment == null) {
      return;
    }

    final segmentParameters = _buildSegmentParameters(segment);

    final domainVisitors = await FirestoreClient.loadAllDomainVisitors(domain);

    // Collect all wallets of all visitors into single list
    // so we load all balances and transactions per single batch.
    // After this we need to match balances and transactions back to visitors.
    final allVisitorsWallets = _extractAllWalletsFromVisitors(domainVisitors);
    final allVisitorsWalletsBalances = await MoralisClient.loadEthereumERC20WalletsBalance(walletsAddresses: allVisitorsWallets.toList());
    final allVisitorsWalletsTransactions = await MoralisClient.loadEthereumERC20WalletsTransactions(walletsAddresses: allVisitorsWallets.toList());

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfCurrentDayTimestamp = startOfDay.millisecondsSinceEpoch;

    for (final walletBalance in allVisitorsWalletsBalances) {
      final walletVisitor = _findVisitorOfWallet(walletBalance.address, domainVisitors);
      final visitorTransactionsInfo = _findVisitorTransactions(walletBalance.address, allVisitorsWalletsTransactions);

      if (!_checkSegmentWalletAge(segment, visitorTransactionsInfo, startOfCurrentDayTimestamp)) {
        continue;
      }

      final transactionsPerPeriodCount = _checkAndCalculateTransactionsPerPeriodCount(
        segment,
        visitorTransactionsInfo,
        startOfCurrentDayTimestamp
      );
      if (transactionsPerPeriodCount == null) {
        continue;
      }

      if (!_checkGoogleAnalyticsMarkers(segment, walletVisitor)) {
        continue;
      }

      items.add(
        _SegmentItem(
          userId: walletVisitor.id,
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

  static String _buildSegmentParameters(SegmentInfo segment) {
    String segmentParameters = '';

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
    segmentParameters += segment.utmSource != null
      ? ', UTM Source: \'${segment.utmSource}\''
      : ', UTM Source: Any';
    segmentParameters += segment.utmMedium != null
      ? ', UTM Medium: \'${segment.utmMedium}\''
      : ', UTM Medium: Any';
    segmentParameters += segment.utmCampaign != null
      ? ', UTM Campaign: \'${segment.utmCampaign}\''
      : ', UTM Campaign: Any';

    return segmentParameters;
  }

  static Set<String> _extractAllWalletsFromVisitors(List<VisitorInfo> visitors) {
    Set<String> result = {};

    for (final domainVisitor in visitors) {
      for (final sessionInfo in domainVisitor.sessions) {
        if (sessionInfo.walletId != null) {
          result.add(sessionInfo.walletId!);
        }
      }
    }

    return result;
  }

  static VisitorInfo _findVisitorOfWallet(String walletId, List<VisitorInfo> visitors) {
    final result = visitors.firstWhere((visitor) {
      for (final sessionInfo in visitor.sessions) {
        if (sessionInfo.walletId != null &&
          sessionInfo.walletId!.toLowerCase() == walletId.toLowerCase()) {
          return true;
        }
      }

      return false;
    });

    return result;
  }

  static WalletTransactionsInfo? _findVisitorTransactions(String walletId, List<WalletTransactionsInfo> walletsTransactions) {
    final result = walletsTransactions.firstWhereOrNull(
        (walletTransactionsInfo) => walletTransactionsInfo.address.toLowerCase() == walletId.toLowerCase()
    );

    return result;
  }

  static bool _checkSegmentWalletAge(
    SegmentInfo segment,
    WalletTransactionsInfo? visitorTransactionsInfo,
    int startOfCurrentDayTimestamp
  ) {
    // Transactions come in last-to-first order so the last one is the oldest one
    final firstTransaction = visitorTransactionsInfo != null && visitorTransactionsInfo.transactions.isNotEmpty
      ? visitorTransactionsInfo.transactions.last
      : null;

    if (segment.minWalletAgeInDays != null && segment.minWalletAgeInDays! > 0) {
      if (firstTransaction == null) {
        return false;
      }

      final latestFirstTransactionTimestamp =
        startOfCurrentDayTimestamp - segment.minWalletAgeInDays! * _Constants.millisecondsPerDay;

      if (firstTransaction.timestamp > latestFirstTransactionTimestamp) {
        return false;
      }
    }

    if (segment.maxWalletAgeInDays != null && segment.maxWalletAgeInDays! > 0) {
      if (firstTransaction == null) {
        return false;
      }

      final earliestFirstTransactionTimestamp =
        startOfCurrentDayTimestamp - segment.maxWalletAgeInDays! * _Constants.millisecondsPerDay;

      if (firstTransaction.timestamp < earliestFirstTransactionTimestamp) {
        return false;
      }
    }

    return true;
  }

  static int? _checkAndCalculateTransactionsPerPeriodCount(
    SegmentInfo segment,
    WalletTransactionsInfo? visitorTransactionsInfo,
    int startOfCurrentDayTimestamp
  ) {
    int transactionsPerPeriodCount = visitorTransactionsInfo != null
      ? visitorTransactionsInfo.transactions.length
      : 0;

    if (segment.transactionsCountPeriodInDays != null) {
      if (visitorTransactionsInfo == null) {
        return null;
      }

      final periodStartTimestamp = startOfCurrentDayTimestamp - _Constants.millisecondsPerDay * segment.transactionsCountPeriodInDays!;
      transactionsPerPeriodCount = 0;
      for (final currentTransaction in visitorTransactionsInfo.transactions) {
        if (currentTransaction.timestamp > periodStartTimestamp) {
          transactionsPerPeriodCount++;
        }
      }

      if (segment.minTransactionsCountPerPeriod != null && transactionsPerPeriodCount < segment.minTransactionsCountPerPeriod! ||
          segment.maxTransactionsCountPerPeriod != null && transactionsPerPeriodCount > segment.maxTransactionsCountPerPeriod!) {
        return null;
      }
    }

    return transactionsPerPeriodCount;
  }

  static bool _checkGoogleAnalyticsMarkers(
    SegmentInfo segment,
    VisitorInfo visitor
  ) {
    if (segment.utmSource != null && segment.utmSource!.isNotEmpty) {
      final sessionWithUtmSource = visitor.sessions.firstWhereOrNull((session) => session.utmSource == segment.utmSource!);
      if (sessionWithUtmSource == null) {
        return false;
      }
    }

    if (segment.utmMedium != null && segment.utmMedium!.isNotEmpty) {
      final sessionWithUtmSource = visitor.sessions.firstWhereOrNull((session) => session.utmMedium == segment.utmMedium!);
      if (sessionWithUtmSource == null) {
        return false;
      }
    }

    if (segment.utmCampaign != null && segment.utmCampaign!.isNotEmpty) {
      final sessionWithUtmSource = visitor.sessions.firstWhereOrNull((session) => session.utmCampaign == segment.utmCampaign!);
      if (sessionWithUtmSource == null) {
        return false;
      }
    }

    return true;
  }

  // Internal fields

  final VoidCallback _onDispose;
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
