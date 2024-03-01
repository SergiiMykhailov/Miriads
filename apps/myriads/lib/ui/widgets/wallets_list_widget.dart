import 'package:flutter/cupertino.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/models/user_wallets_info.dart';

class WalletsListWidget extends StatefulWidget {

  // Public methods and properties

  WalletsListWidget({super.key});

  void reload(String domain) {
    _state.reload(domain);
  }

  // Overridden methods

  @override
  State<StatefulWidget> createState() {
    // ignore: no_logic_in_create_state
    return _state;
  }

  // Internal fields

  final _state = _WalletsListWidgetState();

}

class _WalletsListWidgetState extends State<WalletsListWidget> {

  // Public methods and properties

  void reload(String domain) {
    setState(() {
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
      return const CupertinoActivityIndicator();
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: CupertinoTextField(
        controller: TextEditingController(text: walletsText),
        readOnly: true,
        minLines: 1,
        maxLines: 100000,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          border: Border.all(color: CupertinoColors.systemGrey5),
          borderRadius: BorderRadius.circular(12.0),
        ),
      )
    );
  }

  void _reloadWallets() async {
    if (_domain == null) {
      return;
    }

    final loadedWallets = await FirestoreClient.loadAllUsersWallets(_domain!);

    setState(() {
      _isLoading = false;
      _loadedWallets = loadedWallets;
    });
  }

  // Internal fields

  String? _domain;
  bool _isLoading = false;
  List<UserWalletsInfo> _loadedWallets = [];

}