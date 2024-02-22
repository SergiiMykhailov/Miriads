import 'package:flutter/cupertino.dart';
import 'package:myriads/ui/screens/home_screen.dart';

void main() {
  runApp(const MyriadsApp());
}

class MyriadsApp extends StatelessWidget {
  const MyriadsApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: "Myriads",
      theme: CupertinoThemeData(
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
      home: HomeScreen(),
    );
  }
}