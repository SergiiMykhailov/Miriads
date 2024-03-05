import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/error_message_widget.dart';
import 'package:myriads/ui/widgets/copyable_text_widget.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

class GettingStartedWidget extends StatefulWidget {

  // Public methods and properties

  const GettingStartedWidget({super.key});

  // Overridden methods

  @override
  State<StatefulWidget> createState() => _GettingStartedWidgetState();

}

class _GettingStartedWidgetState extends State<GettingStartedWidget> {

  // Public methods and properties

  _GettingStartedWidgetState() {
    _reloadContent();
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    List<Widget> layers = [];

    if (_isLoading) {
      layers.add(
        const CupertinoActivityIndicator(color: AppTheme.textColorBody)
      );
    }
    else if (_content == null) {
      layers.add(
        const ErrorMessageWidget(
          title: 'Failed to load setup instructions',
          message: 'Content not found'
        )
      );
    }
    else {
      layers.add(
        CopyableTextWidget(
          title: 'Copy-paste code below to your HTML page',
          text: _content!
        )
      );
    }

    return Stack(children: layers);
  }

  // Internal methods

  void _reloadContent() async {
    updateState( () async {
      _isLoading = true;
      _content = null;

      final response = await http.get(Uri.parse(_Constants.contentUrl));
      updateState(() {
        _content = response.statusCode == 200 ? response.body : null;
        _isLoading = false;
      });
    });
  }

  // Internal fields

  bool _isLoading = true;
  String? _content;

}

class _Constants {

  static const contentUrl = 'https://raw.githubusercontent.com/SergiiMykhailov/Myriads/master/Tracker/tracker.html';

}