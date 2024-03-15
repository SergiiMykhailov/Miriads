import 'dart:ui';

typedef BoolCallback = bool Function();

class DelayedUtils {

  static void waitForConditionAndExecute({
    required BoolCallback condition,
    required VoidCallback callback,
    int pollTimeoutInMilliseconds = 100,
    int fallbackTimeoutInMilliseconds = 10000
  }) async {
    int timeExpired = 0;

    while (!condition()) {
      await Future.delayed(Duration(milliseconds: pollTimeoutInMilliseconds));

      timeExpired += pollTimeoutInMilliseconds;
      if (timeExpired > pollTimeoutInMilliseconds) {
        return;
      }
    }

    callback();
  }

  // Internal methods

  DelayedUtils._();

}