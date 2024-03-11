import 'package:myriads/models/user_wallets_info.dart';
import 'package:myriads/models/user_info.dart';
import 'package:myriads/firestore/parsing_utils.dart';
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

  static Future<void> registerSegment({
    required String domain,
    required String title,
    required String description,
    int? minWalletAgeInDays,
    int? maxWalletAgeInDays,
    int? transactionsCountPeriodInDays,
    int? minTransactionsCountPerPeriod,
    int? maxTransactionsCountPerPeriod
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
      FirestoreKeys.title : title,
      FirestoreKeys.description : description
    };

    validateParameterAndAddToData(int? parameter, String parameterName) {
      if (parameter != null) {
        data.addAll({ parameterName : parameter });
      }
    }

    validateParameterAndAddToData(minWalletAgeInDays, FirestoreKeys.minWalletAgeInDays);
    validateParameterAndAddToData(maxWalletAgeInDays, FirestoreKeys.maxWalletAgeInDays);
    validateParameterAndAddToData(transactionsCountPeriodInDays, FirestoreKeys.transactionsCountPeriodInDays);
    validateParameterAndAddToData(minTransactionsCountPerPeriod, FirestoreKeys.minTransactionsCountPerPeriod);
    validateParameterAndAddToData(maxTransactionsCountPerPeriod, FirestoreKeys.maxTransactionsCountPerPeriod);

    await segmentDocument.set(data);

    await Future.delayed(const Duration(seconds: 3));
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
}