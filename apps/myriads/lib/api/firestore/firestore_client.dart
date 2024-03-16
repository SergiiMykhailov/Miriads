import 'dart:async';

import 'package:myriads/models/segment_info.dart';
import 'package:myriads/models/user_wallets_info.dart';
import 'package:myriads/models/user_info.dart';
import 'package:myriads/api/firestore/parsing_utils.dart';
import 'package:myriads/utils/string_extensions.dart';

import 'firestore_keys.dart';
import 'firestore_utils.dart';

class FirestoreClient {

  // Public methods and properties

  FirestoreClient._();

  static Future<List<UserWalletsInfo>> loadAllUsersWallets(String domain) async {
    final adjustedDomain = _adjustDomain(domain);

    List<UserWalletsInfo> result = [];

    final firestore = await FirestoreUtils.initializedSharedInstance();
    final domainVisitorsSnapshot = await firestore
      .collection(FirestoreKeys.domains)
      .doc(adjustedDomain)
      .collection(FirestoreKeys.visitors)
      .get();

    for (final visitorDocument in domainVisitorsSnapshot.docs) {
      final userId = visitorDocument.id;

      List<String> wallets = [];
      final sessionsSnapshot = await visitorDocument
        .reference.collection(FirestoreKeys.sessions).get();
      for (final sessionDocument in sessionsSnapshot.docs) {
        final sessionData = sessionDocument.data();

        final walletId = tryGetValueFromMap<String>(sessionData, FirestoreKeys.walletId);
        if (walletId != null && !wallets.contains(walletId)) {
          wallets.insert(0, walletId);
        }
      }

      if (wallets.isNotEmpty) {
        result.add(UserWalletsInfo(userId: userId, wallets: wallets));
      }
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

    validateParameterAndAddToData(int? parameter, String parameterName) {
      if (parameter != null) {
        data.addAll({ parameterName : parameter });
      }
    }

    validateParameterAndAddToData(segmentInfo.minWalletAgeInDays, FirestoreKeys.minWalletAgeInDays);
    validateParameterAndAddToData(segmentInfo.maxWalletAgeInDays, FirestoreKeys.maxWalletAgeInDays);
    validateParameterAndAddToData(segmentInfo.transactionsCountPeriodInDays, FirestoreKeys.transactionsCountPeriodInDays);
    validateParameterAndAddToData(segmentInfo.minTransactionsCountPerPeriod, FirestoreKeys.minTransactionsCountPerPeriod);
    validateParameterAndAddToData(segmentInfo.maxTransactionsCountPerPeriod, FirestoreKeys.maxTransactionsCountPerPeriod);

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

    if (title != null && description != null) {
      return SegmentInfo(
        title: title,
        description: description,
        id: segmentId,
        minWalletAgeInDays: minWalletAgeInDays,
        maxWalletAgeInDays: maxWalletAgeInDays,
        transactionsCountPeriodInDays: transactionsCountPeriodInDays,
        minTransactionsCountPerPeriod: minTransactionsCountPerPeriod,
        maxTransactionsCountPerPeriod: maxTransactionsCountPerPeriod
      );
    }

    return null;
  }
}