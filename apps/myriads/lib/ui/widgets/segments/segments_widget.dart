import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/segments/create_segment_widget.dart';
import 'package:myriads/ui/widgets/segments/segment_details_widget.dart';
import 'package:myriads/ui/widgets/segments/segments_list_widget.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:flutter/cupertino.dart';

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

enum _SegmentsWidgetViewState {
  displayingSegmentsList,
  displayingSegmentDetails,
  creatingSegment
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
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _makeActionButton()
            ],
          )
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24, bottom: 24, top: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: AppTheme.secondaryBackgroundColor,
                width: 1.0,
              )
            ),
            child: _buildContent(),
          )
        )
      ],
    );
  }

  // Internal methods

  Widget _makeActionButton() {
    final iconData = _viewState == _SegmentsWidgetViewState.displayingSegmentsList
      ? CupertinoIcons.add
      : CupertinoIcons.back;
    final title = _viewState == _SegmentsWidgetViewState.displayingSegmentsList
      ? 'Create segment'
      : 'To list';
    final decoration = _viewState == _SegmentsWidgetViewState.displayingSegmentsList
      ? BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(12.0),
        )
      : null;
    final textColor = _viewState == _SegmentsWidgetViewState.displayingSegmentsList
      ? CupertinoColors.black
      : AppTheme.accentColor;

    return Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: decoration,
      child: CupertinoButton(
        onPressed: _handleActionButtonPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              iconData,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500
              ),
            )
          ],
        )
      ),
    );
  }

  Widget _buildContent() {
    if (_domain == null) {
      return Container();
    }

    _createSegmentWidget = _createSegmentWidget ?? CreateSegmentWidget(
      domain: _domain!,
      onCreated: () {
        updateState(() {
          _segmentsListWidget?.reload();
          _viewState = _SegmentsWidgetViewState.displayingSegmentsList;
        });
      },
    );
    _segmentsListWidget = _segmentsListWidget ?? SegmentsListWidget(domain: _domain!);
    _segmentDetailsWidget = _segmentDetailsWidget ?? SegmentDetailsWidget();

    return Stack(
      children: [
        Visibility(
          visible: _viewState == _SegmentsWidgetViewState.displayingSegmentsList,
          child: _segmentsListWidget!
        ),
        Visibility(
          visible: _viewState == _SegmentsWidgetViewState.displayingSegmentDetails,
          child: _segmentDetailsWidget!
        ),
        Visibility(
          visible: _viewState == _SegmentsWidgetViewState.creatingSegment,
          child: _createSegmentWidget!
        )
      ],
    );
  }

  void _handleActionButtonPressed() {
    final targetState = _viewState == _SegmentsWidgetViewState.displayingSegmentsList
      ? _SegmentsWidgetViewState.creatingSegment
      : _SegmentsWidgetViewState.displayingSegmentsList;

    updateState(() {
      _viewState = targetState;
    });
  }

  // Internal fields

  String? _domain;
  _SegmentsWidgetViewState _viewState = _SegmentsWidgetViewState.displayingSegmentsList;

  CreateSegmentWidget? _createSegmentWidget;
  SegmentDetailsWidget? _segmentDetailsWidget;
  SegmentsListWidget? _segmentsListWidget;

}