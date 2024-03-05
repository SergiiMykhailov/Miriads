import 'package:flutter/cupertino.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/ui/theme/app_theme.dart';
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
          child: Container(
            color: AppTheme.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('lib/resources/images/logo_dark.jpg'),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppTheme.separatorColor,
                  ),
                  const SizedBox(height: 16),
                  _makeButton(
                    title: 'Getting started',
                    isHighlighted: _selectedTab == _HomeScreenSelectedTab.gettingStarted,
                    onPressed: () {
                      _activateTab(_HomeScreenSelectedTab.gettingStarted);
                    }
                  ),
                  _makeButton(
                    title: 'Statistics',
                    isHighlighted: _selectedTab == _HomeScreenSelectedTab.statistics,
                    onPressed: () {
                      _activateTab(_HomeScreenSelectedTab.statistics);
                    }
                  )
                ]
              )
            ),
          ) ,
        ),
        Container(
          width: 1,
          color: AppTheme.separatorColor,
        ),
        Expanded(
          flex: 5,
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

  Widget _makeButton({
    required String title,
    required bool isHighlighted,
    required VoidCallback onPressed
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isHighlighted ? AppTheme.buttonHighlightColor : null,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: CupertinoButton(
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppTheme.textColorBody,
                      fontSize: 14
                    ),
                  )
                ],
              )
            ),
          )
        )
      ],
    );
  }

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
