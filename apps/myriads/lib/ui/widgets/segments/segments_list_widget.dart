import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class SegmentsListWidget extends StatefulWidget {

  // Public methods and properties

  SegmentsListWidget({
    required String domain,
    Key? key
  })
    : _domain = domain
    , super(key: key);

  void reload() {
    _state?.reload();
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _SegmentsListWidgetState(domain: _domain);
    return _state!;
  }

  // Internal fields

  final String _domain;
  _SegmentsListWidgetState? _state;

}

class _SegmentsListWidgetState extends State<SegmentsListWidget> {

  // Public methods and properties

  _SegmentsListWidgetState({
    required String domain
  })
    : _domain = domain;

  void reload() {

  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: CupertinoColors.systemBlue,
    );
  }

  // Internal fields

  final String _domain;

}
