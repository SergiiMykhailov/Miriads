import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class SegmentDetailsWidget extends StatefulWidget {

  // Public methods and properties

  SegmentDetailsWidget({super.key});

  void reload({
    required String domain,
    required String segmentId
  }) {
    _state?.reload(domain: domain, segmentId: segmentId);
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _SegmentDetailsWidgetState();
    return _state!;
  }

  // Internal fields

  _SegmentDetailsWidgetState? _state;

}

class _SegmentDetailsWidgetState extends State<SegmentDetailsWidget> {

  // Public methods and properties

  void reload({
    required String domain,
    required String segmentId
  }) {

  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: CupertinoColors.systemGreen,
    );
  }

  // Internal fields

}
