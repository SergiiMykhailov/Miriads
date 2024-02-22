import 'package:flutter/cupertino.dart';
import 'package:myriads/ui/widgets/wallets_list_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.white,
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Container()),
                SizedBox(
                  width: 300,
                  child: CupertinoTextField(
                    placeholder: 'Specify your domain',
                    textAlign: TextAlign.center,
                    onChanged: (String updatedValue) {
                      _domain = updatedValue;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    _walletsListWidget.reload(_domain);
                  }
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          Container(height: 1, color: CupertinoColors.systemGrey5),
          _walletsListWidget
        ],
      ),
    );
  }

  // Internal fields

  final _walletsListWidget = WalletsListWidget();
  String _domain = '';
}
