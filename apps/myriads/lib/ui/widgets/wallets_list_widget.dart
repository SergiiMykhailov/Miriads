import 'package:flutter/cupertino.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/models/user_wallets_info.dart';
import 'package:myriads/ui/widgets/copyable_text_widget.dart';
import 'package:myriads/utils/widget_extensions.dart';

// ignore: must_be_immutable
class WalletsListWidget extends StatefulWidget {

  // Public methods and properties

  WalletsListWidget({super.key});

  void reload(String domain) {
    _domain = domain;

    if (_state != null) {
      _state!.reload(domain);
    }
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
      _loadedWallets = [];

      _reloadWallets();
    });
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return _buildWalletsList();
  }

  // Internal methods

  Widget _buildWalletsList() {
    var walletsText = '';

    for (final userWalletsInfo in _loadedWallets) {
      final currentUserWalletsText = userWalletsInfo.wallets.join(', ');

      var adjustedUserId = userWalletsInfo.userId;
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

    final loadedWallets = await FirestoreClient.loadAllUsersWallets(_domain!);

    updateState(() {
      _isLoading = false;
      _loadedWallets = loadedWallets;
    });
  }

  // Internal fields

  String? _domain;
  bool _isLoading = false;
  List<UserWalletsInfo> _loadedWallets = [];

}