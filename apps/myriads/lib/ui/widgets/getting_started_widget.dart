import 'package:flutter/cupertino.dart';

class GettingStartedWidget extends StatefulWidget {

  // Public methods and properties

  const GettingStartedWidget({super.key});

  // Overridden methods

  @override
  State<StatefulWidget> createState() => _GettingStartedWidgetState();

}

class _GettingStartedWidgetState extends State<GettingStartedWidget> {

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    List<Widget> layers = [];

    if (_isLoading) {
      layers.add(
        const CupertinoActivityIndicator()
      );
    }

    return Container(
      color: CupertinoColors.systemYellow,
      child: Stack(children: layers),
    );
  }

  // Internal methods

  // Internal fields

  bool _isLoading = true;

}