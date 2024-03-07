import 'package:flutter/material.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/error_message_widget.dart';
import 'package:myriads/ui/widgets/getting_started_widget.dart';
import 'package:myriads/ui/widgets/segments/segments_widget.dart';
import 'package:myriads/ui/widgets/wallets_list_widget.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:flutter/cupertino.dart';

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

enum _HomeScreenSelectedTab { gettingStarted, statistics, segments }

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
          color: AppTheme.backgroundColor,
          child: const CupertinoActivityIndicator(color: AppTheme.textColorBody),
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

    return Stack(children: layers);
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
                  SizedBox(
                    height: 130,
                    child: Image.asset('lib/resources/images/logo_dark.jpg'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppTheme.separatorColor,
                  ),
                  const SizedBox(height: 16),
                  _makeButton(
                    title: 'Getting started',
                    iconData: Icons.start,
                    isHighlighted: _selectedTab == _HomeScreenSelectedTab.gettingStarted,
                    onPressed: () {
                      _activateTab(_HomeScreenSelectedTab.gettingStarted);
                    }
                  ),
                  _makeButton(
                    title: 'Statistics',
                    iconData: Icons.list,
                    isHighlighted: _selectedTab == _HomeScreenSelectedTab.statistics,
                    onPressed: () {
                      _activateTab(_HomeScreenSelectedTab.statistics);
                    }
                  ),
                  _makeButton(
                    title: 'Segments',
                    iconData: Icons.filter_list,
                    isHighlighted: _selectedTab == _HomeScreenSelectedTab.segments,
                    onPressed: () {
                      _activateTab(_HomeScreenSelectedTab.segments);
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
          child: Stack(
            children: [
              _makeContentPanelBackground(),
              _makeContentPanels()
            ],
          ),
        )
      ]
    );
  }

  // Internal methods

  Widget _makeContentPanelBackground() {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: Image.asset(
            'lib/resources/images/content_header_gradient.jpg',
            fit: BoxFit.fill,
          ),
        ),
        Expanded(
          child: Container(
            color: AppTheme.backgroundColor,
          )
        )
      ],
    );
  }

  Widget _makeContentPanel({
    required Widget panelWidget,
    required bool isVisible
  }) {
    return Visibility(
      visible: isVisible,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: panelWidget,
        ),
      )
    );
  }

  Widget _makeContentPanels() {
    return SingleChildScrollView(
      child: Stack(
        children: [
          _makeContentPanel(
            panelWidget: _gettingStartedWidget,
            isVisible: _selectedTab == _HomeScreenSelectedTab.gettingStarted
          ),
          _makeContentPanel(
            panelWidget: _walletsListWidget,
            isVisible: _selectedTab == _HomeScreenSelectedTab.statistics
          ),
          _makeContentPanel(
            panelWidget: _segmentsWidget,
            isVisible: _selectedTab == _HomeScreenSelectedTab.segments
          )
        ],
      )
    );
  }

  Widget _makeButton({
    required String title,
    required IconData iconData,
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
              color: isHighlighted ? AppTheme.secondaryBackgroundColor : null,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: CupertinoButton(
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(iconData, color: AppTheme.textColorBody),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppTheme.textColorBody,
                      fontSize: 16
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
  final _segmentsWidget = SegmentsWidget();
  final String _userEmail;
  bool _isLoading = true;
  String? _domain;
  _HomeScreenSelectedTab _selectedTab = _HomeScreenSelectedTab.gettingStarted;
}
