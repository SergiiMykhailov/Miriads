import 'package:myriads/api/firestore/firestore_client.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/copyable_text_widget.dart';
import 'package:myriads/utils/delayed_utils.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class WalletsListWidget extends StatefulWidget {

  // Public methods and properties

  WalletsListWidget({super.key});

  void reload(String domain) {
    _domain = domain;

    DelayedUtils.waitForConditionAndExecute(
      condition: () { return _state != null; },
      callback: () { _state!.reload(_domain); }
    );
  }

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    _state = _WalletsListWidgetState(domain: _domain);
    return _state!;
  }

  // Internal fields

  _WalletsListWidgetState? _state;
  String _domain = '';
}

class _WalletsListWidgetState extends State<WalletsListWidget> {

  // Public methods and properties

  _WalletsListWidgetState({
    required String domain
  })
    : _domain = domain {
    if (_domain != null && _domain!.isNotEmpty) {
      reload(_domain!);
    }
  }

  void reload(String domain) {
    updateState(() {
      _domain = domain;
      _isLoading = true;
      _loadedVisitorIdToWalletsListMap = {};

      _reloadWallets();
    });
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(color: AppTheme.textColorBody));
    }

    return _buildWalletsList();
  }

  // Internal methods

  Widget _buildWalletsList() {
    var walletsText = '';

    for (final visitorWalletsInfo in _loadedVisitorIdToWalletsListMap.entries) {
      final visitorId = visitorWalletsInfo.key;
      final visitorWallets = visitorWalletsInfo.value;

      final currentUserWalletsText = visitorWallets.join(', ');

      var adjustedUserId = visitorId;
      if (adjustedUserId.startsWith('ga_')) {
        adjustedUserId = adjustedUserId.substring(3);
      }
      adjustedUserId = adjustedUserId.replaceAll('_', '.');

      walletsText += '$adjustedUserId, $currentUserWalletsText\n';
    }

    return CopyableTextWidget(title: '', text: walletsText);
  }

  void _reloadWallets() async {
    if (_domain == null) {
      return;
    }

    final domainVisitors = await FirestoreClient.loadAllDomainVisitors(_domain!);
    Map<String, Set<String>> visitorIdToWalletsListMap = {};

    for (final domainVisitor in domainVisitors) {
      Set<String> visitorWallets = {};

      for (final visitorSession in domainVisitor.sessions) {
        if (visitorSession.walletId != null) {
          visitorWallets.add(visitorSession.walletId!);
        }
      }

      visitorIdToWalletsListMap[domainVisitor.id] = visitorWallets;
    }

    updateState(() {
      _isLoading = false;
      _loadedVisitorIdToWalletsListMap = visitorIdToWalletsListMap;
    });
  }

  // Internal fields

  String? _domain;
  bool _isLoading = false;
  Map<String, Set<String>> _loadedVisitorIdToWalletsListMap = {};

}