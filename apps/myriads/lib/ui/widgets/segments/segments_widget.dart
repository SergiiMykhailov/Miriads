import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myriads/ui/theme/app_theme.dart';

// ignore: must_be_immutable
class SegmentsWidget extends StatefulWidget {

  // Public methods and properties

  SegmentsWidget({super.key});

  void reload(String domain) {
    _domain = domain;

    _state?.reload(_domain);
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _SegmentsWidgetState(domain: _domain);
    return _state!;
  }

  // Internal fields

  _SegmentsWidgetState? _state;
  String _domain = '';
}

class _SegmentsWidgetState extends State<SegmentsWidget> {

  // Public methods and properties

  _SegmentsWidgetState({
    required String domain
  })
    : _domain = domain {
    if (_domain != null && _domain!.isNotEmpty) {
      reload(_domain!);
    }
  }

  void reload(String domain) {
    _domain = domain;
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: CupertinoButton(
                  onPressed: _handleCreateSegment,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.add,
                        color: CupertinoColors.black,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Create segment',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                        ),
                      )
                    ],
                  )
                ),
              )
            ],
          )
        )
      ],
    );
  }

  // Internal methods

  void _handleCreateSegment() {

  }

  // Internal fields

  String? _domain;

}