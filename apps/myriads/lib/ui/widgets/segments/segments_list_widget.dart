import 'package:flutter/material.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/models/segment_info.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:flutter/cupertino.dart';

typedef SegmentSelectedCallback = void Function(SegmentInfo segmentInfo);

// ignore: must_be_immutable
class SegmentsListWidget extends StatefulWidget {

  // Public methods and properties

  SegmentsListWidget({
    required String domain,
    SegmentSelectedCallback? onSegmentSelected,
    Key? key
  })
    : _domain = domain
    , _onSegmentSelected = onSegmentSelected
    , super(key: key);

  void reload() {
    _state?.reload();
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _SegmentsListWidgetState(
      domain: _domain,
      onSegmentSelected: _onSegmentSelected
    );
    return _state!;
  }

  // Internal fields

  final String _domain;
  final SegmentSelectedCallback? _onSegmentSelected;

  _SegmentsListWidgetState? _state;

}

class _SegmentsListWidgetState extends State<SegmentsListWidget> {

  // Public methods and properties

  _SegmentsListWidgetState({
    required String domain,
    required SegmentSelectedCallback? onSegmentSelected
  })
    : _domain = domain
    , _onSegmentSelected = onSegmentSelected {
    reload();
  }

  void reload() {
    updateState( () {
      _isLoading = true;
      
      _reloadSegments();
    });
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    final content = _isLoading 
      ? const CupertinoActivityIndicator(color: AppTheme.textColorBody)
      : _buildContent();
    
    return SizedBox(
      width: double.infinity,
      child: content,
    );
  }
  
  // Internal methods
  
  void _reloadSegments() async {
    _loadedSegments = await FirestoreClient.loadAllSegments(domain: _domain);
    
    updateState(() { 
      _isLoading = false;
    });
  }
  
  Widget _buildContent() {
    if (_loadedSegments.isEmpty) {
      return const Center(
        child: Text(
          'There are no segments yet',
          textAlign: TextAlign.start,
          style: TextStyle(
            color: AppTheme.textColorBody,
            fontSize: 16
          ),
        ),
      );
    }

    List<Widget> segments = [];

    for (final segmentInfo in _loadedSegments) {
      segments.add(const SizedBox(height: 12));
      segments.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackgroundColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: CupertinoButton(
              alignment: Alignment.centerLeft,
              onPressed: () {
                if (_onSegmentSelected != null) {
                  _onSegmentSelected(segmentInfo);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segmentInfo.title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppTheme.textColorBody,
                      fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    segmentInfo.description,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppTheme.textColorBody,
                      fontSize: 12
                    ),
                  )
                ],
              )
            ),
          )
        )
      );
    }

    segments.add(const SizedBox(height: 12));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments,
    );
  }

  // Internal fields

  final String _domain;
  final SegmentSelectedCallback? _onSegmentSelected;
  
  bool _isLoading = false;
  List<SegmentInfo> _loadedSegments = [];

}
