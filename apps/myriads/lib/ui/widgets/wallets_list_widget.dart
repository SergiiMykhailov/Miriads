import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      walletsText += currentUserWalletsText + ',';
      walletsText += '\n\n';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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