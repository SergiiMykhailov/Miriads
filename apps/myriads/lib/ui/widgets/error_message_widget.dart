import 'package:flutter/cupertino.dart';
import 'package:myriads/ui/theme/app_theme.dart';

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
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Container()),
          SizedBox(
            height: 130,
            child: Image.asset('lib/resources/images/logo_dark.jpg'),
          ),
          const SizedBox(height: 40),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 16
            )
          ),
          const SizedBox(height: 20),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 14
            )
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  // Internal fields

  final String _title;
  final String _message;

}