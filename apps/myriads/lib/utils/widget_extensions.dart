import 'package:flutter/cupertino.dart';

extension WidgetStateExtension on State<StatefulWidget> {

  void updateState(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
    else {
      fn();
    }
  }

}