import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/utils/widget_extensions.dart';

import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

class DropDownItemsPicker extends StatefulWidget {

  // Public methods and properties

  const DropDownItemsPicker({
    required Iterable<String> items,
    required ValueChanged<int> onItemSelected,
    Key? key
  })
    : _items = items
    , _onItemSelected = onItemSelected
    , super(key: key);

  // Overridden methods

  @override
  State<StatefulWidget> createState() {
    // ignore: no_logic_in_create_state
    return _DropDownItemsPickerState(
      items: _items,
      onItemSelected: _onItemSelected
    );
  }

  // Internal fields

  final Iterable<String> _items;
  final ValueChanged<int> _onItemSelected;

}

class _DropDownItemsPickerState extends State<DropDownItemsPicker> {

  // Public methods and properties

  _DropDownItemsPickerState({
    required Iterable<String> items,
    required ValueChanged<int> onItemSelected
  })
    : _items = items
    , _onItemSelected = onItemSelected;

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    final Iterable<String> itemsToUse = _items.isNotEmpty
      ? _items
      : ['No items specified'];
    final title = itemsToUse.elementAt(_selectedItemIndex);

    return PullDownButton(
      itemBuilder: (context) {
        List<PullDownMenuEntry> result = [];

        for (int itemIndex = 0; itemIndex < itemsToUse.length; itemIndex++) {
          result.add(
            PullDownMenuItem(
              title: itemsToUse.elementAt(itemIndex),
              onTap: () {
                updateState(() {
                  _selectedItemIndex = itemIndex;
                  _onItemSelected(itemIndex);
                });
              },
            )
          );
        }

        return result;
      },
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textColorBody,
                fontSize: 14
              )
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.only(top: 4),
              child: const Icon(
                CupertinoIcons.arrowtriangle_down_fill,
                color: AppTheme.textColorBody,
                size: 12,
              ),
            )
          ],
        ),
      ),
    );
  }

  // Internal fields

  final Iterable<String> _items;
  final ValueChanged<int> _onItemSelected;
  int _selectedItemIndex = 0;

}