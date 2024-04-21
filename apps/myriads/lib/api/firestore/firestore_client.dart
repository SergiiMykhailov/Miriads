import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myriads/models/segment_info.dart';
import 'package:myriads/models/user_info.dart';
import 'package:myriads/api/firestore/parsing_utils.dart';
import 'package:myriads/models/visitor_info.dart';
import 'package:myriads/models/wallet_info.dart';
import 'package:myriads/utils/string_extensions.dart';

import 'firestore_keys.dart';
import 'firestore_utils.dart';

class FirestoreClient {

  // Public methods and properties

  FirestoreClient._();

  static Future<List<VisitorInfo>> loadAllDomainVisitors(String domain) async {
    final adjustedDomain = _adjustDomain(domain);

    List<VisitorInfo> result = [];

    final firestore = await FirestoreUtils.initializedSharedInstance();
    final domainVisitorsSnapshot = await firestore
      .collection(FirestoreKeys.domains)
      .doc(adjustedDomain)
      .collection(FirestoreKeys.visitors)
      .get();

    for (final visitorDocument in domainVisitorsSnapshot.docs) {
      final visitorId = visitorDocument.id;

      final visitorInfo = await _visitorInfoFromDocument(visitorDocument, visitorId);
      result.add(visitorInfo);
    }

    return result;
  }

  static Future<UserInfo?> loadUserInfo(String userEmail) async {
    final firestore = await FirestoreUtils.initializedSharedInstance();
    final userDocument = await firestore
      .collection(FirestoreKeys.users)
      .doc(userEmail)
      .get();

    final userDocumentData = userDocument.data();
    if (userDocumentData != null) {
      final userInfo = _userInfoFromUserDocumentData(userDocumentData, userEmail);
      return userInfo;
    }

    return null;
  }

  static Future<String> registerSegment({
    required String domain,
    required SegmentInfo segmentInfo
  }) async {
    final adjustedDomain = _adjustDomain(domain);
    final segmentId = DateTime.now().millisecondsSinceEpoch.toString();

    final firestore = await FirestoreUtils.initializedSharedInstance();
    final segmentDocument = firestore
      .collection(FirestoreKeys.domains)
      .doc(adjustedDomain)
      .collection(FirestoreKeys.segments)
      .doc(segmentId);

    Map<String, dynamic> data = {
      FirestoreKeys.title : segmentInfo.title,
      FirestoreKeys.description : segmentInfo.description
    };

    validateParameterAndAddToData(dynamic parameter, String parameterName) {
      if (parameter != null) {
        data.addAll({ parameterName : parameter });
      }
    }

    validateParameterAndAddToData(segmentInfo.minWalletAgeInDays, FirestoreKeys.minWalletAgeInDays);
    validateParameterAndAddToData(segmentInfo.maxWalletAgeInDays, FirestoreKeys.maxWalletAgeInDays);
    validateParameterAndAddToData(segmentInfo.transactionsCountPeriodInDays, FirestoreKeys.transactionsCountPeriodInDays);
    validateParameterAndAddToData(segmentInfo.minTransactionsCountPerPeriod, FirestoreKeys.minTransactionsCountPerPeriod);
    validateParameterAndAddToData(segmentInfo.maxTransactionsCountPerPeriod, FirestoreKeys.maxTransactionsCountPerPeriod);
    validateParameterAndAddToData(segmentInfo.utmSource, FirestoreKeys.utmSource);
    validateParameterAndAddToData(segmentInfo.utmMedium, FirestoreKeys.utmMedium);
    validateParameterAndAddToData(segmentInfo.utmCampaign, FirestoreKeys.utmCampaign);
    validateParameterAndAddToData(segmentInfo.minPortfolioBalanceInUSD, FirestoreKeys.minPortfolioBalanceInUSDT);
    validateParameterAndAddToData(segmentInfo.maxPortfolioBalanceInUSD, FirestoreKeys.maxPortfolioBalanceInUSDT);

    await segmentDocument.set(data);

    return segmentId;
  }

  static Future<List<SegmentInfo>> loadAllSegments({
    required String domain
  }) async {
    List<SegmentInfo> result = [];

    final adjustedDomain = _adjustDomain(domain);
    final firestore = await FirestoreUtils.initializedSharedInstance();
    final segmentsSnapshot = await firestore
      .collection(FirestoreKeys.domains)
      .doc(adjustedDomain)
      .collection(FirestoreKeys.segments)
      .get();

    for (final segmentDocument in segmentsSnapshot.docs) {
      final segmentId = segmentDocument.id;

      final segmentData = segmentDocument.data();
      final segment = _segmentInfoFromDocumentData(segmentData, segmentId);
      if (segment != null) {
        result.add(segment);
      }
    }

    return result;
  }

  static Future<SegmentInfo?> loadSegment({
    required String domain,
    required String segmentId
  }) async {
    final adjustedDomain = _adjustDomain(domain);
    final firestore = await FirestoreUtils.initializedSharedInstance();
    final segmentDocument = await firestore
      .collection(FirestoreKeys.domains)
      .doc(adjustedDomain)
      .collection(FirestoreKeys.segments)
      .doc(segmentId)
      .get();

    final segmentData = segmentDocument.data();
    if (segmentData == null) {
      return null;
    }

    final result = _segmentInfoFromDocumentData(segmentData, segmentId);
    return result;
  }

  static Future<void> deleteSegment({
    required String domain,
    required String segmentId
  }) async {
    final adjustedDomain = _adjustDomain(domain);
    final firestore = await FirestoreUtils.initializedSharedInstance();
    await firestore
      .collection(FirestoreKeys.domains)
      .doc(adjustedDomain)
      .collection(FirestoreKeys.segments)
      .doc(segmentId)
      .delete();
  }

  static Future<List<WalletBalanceInfo>> loadWalletsNetWorthInUsd({
    required List<String> walletsAddresses
  }) async {
    List<WalletBalanceInfo> result = [];

    final firestore = await FirestoreUtils.initializedSharedInstance();

    for (final wallet in walletsAddresses) {
      final balanceHistorySnapshot = await firestore
        .collection(FirestoreKeys.wallets)
        .doc(wallet)
        .collection(FirestoreKeys.balanceHistory)
        .get();

      double? walletNetWorthInUsd;
      final lastBalanceHistoryRecord = balanceHistorySnapshot.docs.lastOrNull;
      if (lastBalanceHistoryRecord != null) {
        final balanceHistoryRecordData = lastBalanceHistoryRecord.data();

        walletNetWorthInUsd = tryGetNumericFromMap(balanceHistoryRecordData, FirestoreKeys.totalNetWorthInUsd);
      }

      result.add(WalletBalanceInfo(address: wallet, totalNetWorthInUSD: walletNetWorthInUsd));
    }

    return result;
  }

  static Future<List<WalletTransactionsInfo>> loadWalletsTransactions({
    required List<String> walletsAddresses
  }) async {
    List<WalletTransactionsInfo> result = [];

    final firestore = await FirestoreUtils.initializedSharedInstance();

    for (final wallet in walletsAddresses) {
      final transactionsSnapshot = await firestore
        .collection(FirestoreKeys.wallets)
        .doc(wallet)
        .collection(FirestoreKeys.transactions)
        .get();

      List<TransactionInfo> transactions = [];
      for (final transactionDocument in transactionsSnapshot.docs) {
        final transactionData = transactionDocument.data();
        final transactionInfo = _transactionInfoFromDocumentData(transactionData);

        if (transactionInfo != null) {
          transactions.add(transactionInfo);
        }
      }

      result.add(WalletTransactionsInfo(address: wallet, transactions: transactions));
    }

    return result;
  }

  static double weiToEth(double wei) {
    return wei / 10e18;
  }

  // Internal methods

  static String _adjustDomain(String domain) {
    var adjustedDomain = domain.replaceFirst('https://', '');
    adjustedDomain = adjustedDomain.replaceFirst('http://', '');
    adjustedDomain = adjustedDomain.trimTrailingCharacter('/');
    adjustedDomain = adjustedDomain.replaceAll('.', '_');

    return adjustedDomain;
  }

  static UserInfo? _userInfoFromUserDocumentData(
    Map<String, dynamic> userDocumentData,
    String userEmail
  ) {
    final domain = tryGetValueFromMap<String>(userDocumentData, FirestoreKeys.domain);
    if (domain != null) {
      return UserInfo(email: userEmail, domain: domain);
    }

    return null;
  }

  static Future<VisitorInfo> _visitorInfoFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> visitorDocument,
    String visitorId
  ) async {
    List<VisitorSessionInfo> sessions = [];

    final sessionsSnapshot = await visitorDocument
      .reference.collection(FirestoreKeys.sessions).get();
    for (final sessionDocument in sessionsSnapshot.docs) {
      final sessionId = sessionDocument.id;
      final sessionData = sessionDocument.data();
      final sessionInfo = _sessionInfoFromSessionData(sessionData, sessionId);

      sessions.add(sessionInfo);
    }

    return VisitorInfo(id: visitorId, sessions: sessions);
  }

  static VisitorSessionInfo _sessionInfoFromSessionData(
    Map<String, dynamic> sessionData,
    String sessionId
  ) {
    final walletId = tryGetValueFromMap<String>(sessionData, FirestoreKeys.walletId);
    final utmSource = tryGetValueFromMap<String>(sessionData, FirestoreKeys.utmSource);
    final utmMedium = tryGetValueFromMap<String>(sessionData, FirestoreKeys.utmMedium);
    final utmCampaign = tryGetValueFromMap<String>(sessionData, FirestoreKeys.utmCampaign);

    return VisitorSessionInfo(
      id: sessionId,
      walletId: walletId,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign
    );
  }

  static SegmentInfo? _segmentInfoFromDocumentData(
    Map<String, dynamic> segmentDocumentData,
    String segmentId
  ) {
    final title = tryGetValueFromMap<String>(segmentDocumentData, FirestoreKeys.title);
    final description = tryGetValueFromMap<String>(segmentDocumentData, FirestoreKeys.description);
    final minWalletAgeInDays = tryGetValueFromMap<int>(segmentDocumentData, FirestoreKeys.minWalletAgeInDays);
    final maxWalletAgeInDays = tryGetValueFromMap<int>(segmentDocumentData, FirestoreKeys.maxWalletAgeInDays);
    final transactionsCountPeriodInDays = tryGetValueFromMap<int>(segmentDocumentData, FirestoreKeys.transactionsCountPeriodInDays);
    final minTransactionsCountPerPeriod = tryGetValueFromMap<int>(segmentDocumentData, FirestoreKeys.minTransactionsCountPerPeriod);
    final maxTransactionsCountPerPeriod = tryGetValueFromMap<int>(segmentDocumentData, FirestoreKeys.maxTransactionsCountPerPeriod);
    final utmSource = tryGetValueFromMap<String>(segmentDocumentData, FirestoreKeys.utmSource);
    final utmMedium = tryGetValueFromMap<String>(segmentDocumentData, FirestoreKeys.utmMedium);
    final utmCampaign = tryGetValueFromMap<String>(segmentDocumentData, FirestoreKeys.utmCampaign);
    final minPortfolioBalanceInUSDT = tryGetValueFromMap<double>(segmentDocumentData, FirestoreKeys.minPortfolioBalanceInUSDT);
    final maxPortfolioBalanceInUSDT = tryGetValueFromMap<double>(segmentDocumentData, FirestoreKeys.maxPortfolioBalanceInUSDT);

    if (title != null && description != null) {
      return SegmentInfo(
        title: title,
        description: description,
        id: segmentId,
        minWalletAgeInDays: minWalletAgeInDays,
        maxWalletAgeInDays: maxWalletAgeInDays,
        transactionsCountPeriodInDays: transactionsCountPeriodInDays,
        minTransactionsCountPerPeriod: minTransactionsCountPerPeriod,
        maxTransactionsCountPerPeriod: maxTransactionsCountPerPeriod,
        utmSource: utmSource,
        utmMedium: utmMedium,
        utmCampaign: utmCampaign,
        minPortfolioBalanceInUSD: minPortfolioBalanceInUSDT,
        maxPortfolioBalanceInUSD: maxPortfolioBalanceInUSDT
      );
    }

    return null;
  }

  static TransactionInfo? _transactionInfoFromDocumentData(Map<String, dynamic> transactionDocumentData) {
    final hash = tryGetValueFromMap<String>(transactionDocumentData, FirestoreKeys.hash);

    int? timestamp;
    final timestampValue = tryGetValueFromMap<String>(transactionDocumentData, FirestoreKeys.blockTimestamp);
    if (timestampValue != null) {
      timestamp = DateTime.tryParse(timestampValue)?.millisecondsSinceEpoch;
    }

    double? value;
    final transactionValue = tryGetNumericFromMap(transactionDocumentData, FirestoreKeys.value);
    if (transactionValue != null) {
      value = _weiToEth(transactionValue);
    }

    if (hash != null && timestamp != null && value != null) {
      return TransactionInfo(id: hash, timestamp: timestamp, amount: value);
    }

    return null;
  }

  static double _weiToEth(double wei) {
    return wei / 10e18;
  }
}