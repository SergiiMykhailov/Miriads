import 'package:flutter/cupertino.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/ui/widgets/error_message_widget.dart';
import 'package:myriads/ui/widgets/getting_started_widget.dart';
import 'package:myriads/ui/widgets/wallets_list_widget.dart';
import 'package:myriads/utils/widget_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required String userEmail
  })
    : _userEmail = userEmail;

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<HomeScreen> createState() => _HomeScreenState(userEmail: _userEmail);

  // Internal fields

  final String _userEmail;
}

enum _HomeScreenSelectedTab { gettingStarted, statistics }

class _HomeScreenState extends State<HomeScreen> {

  // Public methods and properties

  _HomeScreenState({
    required String userEmail
  })
    : _userEmail = userEmail {
    _reload();
  }

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    final contentLayer = _buildContentLayer(context);

    List<Widget> layers = [contentLayer];
    if (_isLoading) {
      layers.add(
        Container(
          color: CupertinoColors.white,
          child: const CupertinoActivityIndicator(),
        )
      );
    }
    else if (_domain == null) {
      layers.add(
        ErrorMessageWidget(
          title: 'Login failure',
          message: 'User with email \'$_userEmail\' exists\nbut there is no associated domain'
        )
      );
    }

    return Container(
      color: CupertinoColors.white,
      child: Stack(children: layers),
    );
  }

  Widget _buildContentLayer(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
            child: Column(
              children: [
                CupertinoButton(
                  child: const Text('Getting started'),
                  onPressed: () {
                    _activateTab(_HomeScreenSelectedTab.gettingStarted);
                  }
                ),
                CupertinoButton(
                  child: const Text('Statistics'),
                  onPressed: () {
                    _activateTab(_HomeScreenSelectedTab.statistics);
                  }
                )
              ]
            )
          ) ,
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Domain: ${_domain != null ? _domain! : ''}'),
                  ],
                ),
              ),
              Container(height: 1, color: CupertinoColors.systemGrey5),
              Expanded(
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      Visibility(
                        visible: _selectedTab == _HomeScreenSelectedTab.gettingStarted,
                        child: _gettingStartedWidget
                      ),
                      Visibility(
                        visible: _selectedTab == _HomeScreenSelectedTab.statistics,
                        child: _walletsListWidget
                      )
                    ],
                  )
                )
              )
            ],
          ),
        )
      ]
    );
  }

  // Internal methods

  void _reload() async {
    final userInfo = await FirestoreClient.loadUserInfo(_userEmail);

    updateState(() {
      _isLoading = false;
      _domain = userInfo?.domain;

      if (_domain != null) {
        _walletsListWidget.reload(_domain!);
      }
    });
  }

  void _activateTab(_HomeScreenSelectedTab tab) {
    updateState(() {
      _selectedTab = tab;
    });
  }

  // Internal fields

  final _walletsListWidget = WalletsListWidget();
  final _gettingStartedWidget = const GettingStartedWidget();
  final String _userEmail;
  bool _isLoading = true;
  String? _domain;
  _HomeScreenSelectedTab _selectedTab = _HomeScreenSelectedTab.gettingStarted;
}
