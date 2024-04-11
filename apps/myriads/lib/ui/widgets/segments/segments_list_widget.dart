import 'package:myriads/api/firestore/firestore_client.dart';
import 'package:myriads/models/segment_info.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/utils/delayed_utils.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:flutter/cupertino.dart';

typedef SegmentSelectedCallback = void Function(SegmentInfo segmentInfo);
typedef SegmentDeletedCallback = void Function(SegmentInfo segmentInfo);

// ignore: must_be_immutable
class SegmentsListWidget extends StatefulWidget {

  // Public methods and properties

  SegmentsListWidget({
    required String domain,
    SegmentSelectedCallback? onSegmentSelected,
    SegmentDeletedCallback? onSegmentDeleted,
    Key? key
  })
    : _domain = domain
    , _onSegmentSelected = onSegmentSelected
    , _onSegmentDeleted = onSegmentDeleted
    , super(key: key);

  void reload() {
    DelayedUtils.waitForConditionAndExecute(
      condition: () {
        return _state != null;
      },
      callback: () {
        _state!.reload();
      }
    );
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _SegmentsListWidgetState(
      domain: _domain,
      onSegmentSelected: _onSegmentSelected,
      onSegmentDeleted: _onSegmentDeleted
    );
    return _state!;
  }

  // Internal fields

  final String _domain;
  final SegmentSelectedCallback? _onSegmentSelected;
  final SegmentDeletedCallback? _onSegmentDeleted;

  _SegmentsListWidgetState? _state;

}

class _SegmentsListWidgetState extends State<SegmentsListWidget> {

  // Public methods and properties

  _SegmentsListWidgetState({
    required String domain,
    required SegmentSelectedCallback? onSegmentSelected,
    required SegmentDeletedCallback? onSegmentDeleted
  })
    : _domain = domain
    , _onSegmentSelected = onSegmentSelected
    , _onSegmentDeleted = onSegmentDeleted {
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
      if (segmentInfo.id == null) {
        continue;
      }

      segments.add(const SizedBox(height: 12));
      segments.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
              child: Row(
                children: [
                  Expanded(
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
                  CupertinoButton(
                    onPressed: () {
                      _handleDeleteSegment(segmentInfo);
                    },
                    child: const Center(
                      child: Icon(CupertinoIcons.delete, color: AppTheme.textColorBody,)
                    ),
                  ),
                ],
              )
            ),
          )
        )
      );
    }

    segments.add(const SizedBox(height: 24));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments,
    );
  }

  void _handleDeleteSegment(SegmentInfo segmentInfo) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Are you sure you want to remove selected segment'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              isDestructiveAction: true,
              child: const Text('Remove'),
            ),
          ],
        );
      }
    ).then((value) {
      if (value != null && value && segmentInfo.id != null) {
        FirestoreClient.deleteSegment(domain: _domain, segmentId: segmentInfo.id!);

        reload();

        if (_onSegmentDeleted != null) {
          _onSegmentDeleted(segmentInfo);
        }
      }
    });
  }

  // Internal fields

  final String _domain;
  final SegmentSelectedCallback? _onSegmentSelected;
  final SegmentDeletedCallback? _onSegmentDeleted;
  
  bool _isLoading = false;
  List<SegmentInfo> _loadedSegments = [];

}
