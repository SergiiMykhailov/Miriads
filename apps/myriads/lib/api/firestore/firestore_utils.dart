import 'firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

class FirestoreUtils {

  // Public methods and properties

  FirestoreUtils._();

  static Future<FirebaseFirestore> initializedSharedInstance() async {
    if (!_isFirebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform
      );

      _isFirebaseInitialized = true;
    }

    return FirebaseFirestore.instance;
  }

  // Internal fields

  static var _isFirebaseInitialized = false;

}