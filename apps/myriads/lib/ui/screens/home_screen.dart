import 'package:flutter/cupertino.dart';
import 'package:myriads/firestore/firestore_client.dart';
import 'package:myriads/ui/widgets/wallets_list_widget.dart';

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
    Widget contentLayer = Column(
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
        _walletsListWidget
      ],
    );

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
        Container(
          color: CupertinoColors.white,
          child: Center(child: Text('No domain found for user with email: $_userEmail')),
        )
      );
    }

    return Container(
      color: CupertinoColors.white,
      child: Stack(children: layers),
    );
  }

  // Internal methods

  void _reload() async {
    final userInfo = await FirestoreClient.loadUserInfo(_userEmail);

    setState(() {
      _isLoading = false;
      _domain = userInfo?.domain;

      if (_domain != null) {
        _walletsListWidget.reload(_domain!);
      }
    });
  }

  // Internal fields

  final _walletsListWidget = WalletsListWidget();
  final String _userEmail;
  bool _isLoading = true;
  String? _domain;
}
