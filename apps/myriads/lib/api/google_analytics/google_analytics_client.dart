import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/analytics/v3.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

typedef GoogleAnalyticsClientInitializationCallback = void Function(AnalyticsApi?);
typedef GoogleAnalyticsStringListCallback = void Function(List<String>);

class GoogleAnalyticsClient {

  // Public methods and properties

  static void loadAllUsersForCampaign({
    required String campaignName,
    required GoogleAnalyticsStringListCallback callback
  }) async {
    _ensureApiInitializedAndExecute((AnalyticsApi? analyticsApi) {
      List<String> result = [];

      if (analyticsApi == null) {
        return callback(result);
      }

      callback(result);
    });
  }

  // Internal methods

  static void _ensureApiInitializedAndExecute(
    GoogleAnalyticsClientInitializationCallback callback
  ) async {
    if (_sharedApiInstance != null) {
      return callback(_sharedApiInstance);
    }

    _googleSignIn.onCurrentUserChanged
      .listen((GoogleSignInAccount? account) async {
      // In mobile, being authenticated means being authorized...
      bool isAuthorized = account != null;
      // However, on web...
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.canAccessScopes(_scopes);

        if (!isAuthorized) {
          isAuthorized = await _googleSignIn.requestScopes(_scopes);

          if (isAuthorized) {
            final client = await _googleSignIn.authenticatedClient();

            if (client != null) {
              _sharedApiInstance = AnalyticsApi(client);
            }
          }
        }

        callback(_sharedApiInstance);
      }
    });

    _googleSignIn.signInSilently();
  }

  // Internal methods

  GoogleAnalyticsClient._();

  static AnalyticsApi? _sharedApiInstance;
  static const _scopes = [AnalyticsApi.analyticsScope];
  static final _googleSignIn = GoogleSignIn(
    clientId: '26798202385-ge52o1qjr6g2mm0dmdgc7hrrp2e1da8c.apps.googleusercontent.com',
    scopes: _scopes,
  );

}