import 'package:flutter/cupertino.dart';

class ErrorMessageWidget extends StatelessWidget {

  // Public methods and properties

  const ErrorMessageWidget({
    required String title,
    required String message,
    Key? key
  })
    : _title = title
    , _message = message
    , super(key: key);

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.white,
      padding: const EdgeInsets.all(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Container()),
          Text(_title),
          const SizedBox(height: 40),
          Text(_message),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  // Internal fields

  final String _title;
  final String _message;

}