import 'package:myriads/firestore/parsing_utils.dart';
import 'package:myriads/utils/string_extensions.dart';

import 'firestore_keys.dart';
import 'firestore_utils.dart';

import 'package:myriads/models/user_wallets_info.dart';

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

        final wallet_id = tryGetValueFromMap<String>(sessionData, FirestoreKeys.walletId);
        if (wallet_id != null && !wallets.contains(wallet_id)) {
          wallets.insert(0, wallet_id);
        }
      }

      if (wallets.isNotEmpty) {
        result.add(UserWalletsInfo(userId: userId, wallets: wallets));
      }
    }

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
}