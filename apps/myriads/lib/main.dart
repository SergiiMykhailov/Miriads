import 'package:myriads/api/firestore/firestore_utils.dart';
import 'package:myriads/ui/screens/home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import 'package:flutter/cupertino.dart';

void main() async {
  await FirestoreUtils.initializedSharedInstance();

  runApp(const MyriadsApp());
}

class MyriadsApp extends StatelessWidget {
  const MyriadsApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: "Myriads",
      theme: const CupertinoThemeData(
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Montserrat'),
          actionTextStyle: TextStyle(fontFamily: 'Montserrat'),
          tabLabelTextStyle: TextStyle(fontFamily: 'Montserrat'),
          navTitleTextStyle: TextStyle(fontFamily: 'Montserrat'),
          navLargeTitleTextStyle: TextStyle(fontFamily: 'Montserrat'),
          navActionTextStyle: TextStyle(fontFamily: 'Montserrat'),
          pickerTextStyle: TextStyle(fontFamily: 'Montserrat'),
          dateTimePickerTextStyle: TextStyle(fontFamily: 'Montserrat')
        )
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final userEmail = snapshot.data?.email;

          if (userEmail == null) {
            return SignInScreen(
              showAuthActionSwitch: false,
              providers: [
                GoogleProvider(
                  clientId: "26798202385-ge52o1qjr6g2mm0dmdgc7hrrp2e1da8c.apps.googleusercontent.com")
              ],
              subtitleBuilder: (context, action) {
                return Image.asset('lib/resources/images/logo_light.jpg');
              },
            );
          }

          return HomeScreen(userEmail: userEmail);
        },
      ),
    );
  }
}