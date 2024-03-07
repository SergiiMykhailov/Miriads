import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class CreateSegmentWidget extends StatefulWidget {

  // Public methods and properties

  const CreateSegmentWidget({
    required String domain,
    Key? key
  })
    : _domain = domain
    , super(key: key);

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => _CreateSegmentWidgetState(domain: _domain);

  // Internal fields

  final String _domain;

}

class _CreateSegmentWidgetState extends State<CreateSegmentWidget> {

  // Public methods and properties

  _CreateSegmentWidgetState({
    required String domain
  })
    : _domain = domain;

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: CupertinoColors.systemRed,
    );
  }

  // Internal fields

  final String _domain;

}
