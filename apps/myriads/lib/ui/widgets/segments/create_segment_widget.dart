import 'package:flutter/cupertino.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/dropdown_text_items_picker.dart';
import 'package:myriads/ui/widgets/text_input_field.dart';

// ignore: must_be_immutable
class CreateSegmentWidget extends StatefulWidget {

  // Public methods and properties

  const CreateSegmentWidget({
    required String domain,
    Key? key
  })
    : _domain = domain
    , super(key: key);

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => _CreateSegmentWidgetState(domain: _domain);

  // Internal fields

  final String _domain;

}

class _CreateSegmentWidgetState extends State<CreateSegmentWidget> {

  // Public methods and properties

  _CreateSegmentWidgetState({
    required String domain
  })
    : _domain = domain;

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(children: [Expanded(child: _nameInput)]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _descriptionInput)]),
          const SizedBox(height: 56),
          const Text(
            'Wallet age:',
            style: TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 16
            )
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'From:',
                style: TextStyle(
                  color: AppTheme.textColorBody,
                  fontSize: 14
                )
              ),
              const SizedBox(width: 16),
              DropDownItemsPicker(
                items: _availablePeriodsInDays.values,
                onItemSelected: (int selectedIndex) {
                  _selectedWalletAgeFromIndex = selectedIndex;
                },
              ),
              const SizedBox(width: 64),
              const Text(
                'To:',
                style: TextStyle(
                  color: AppTheme.textColorBody,
                  fontSize: 14
                )
              ),
              const SizedBox(width: 16),
              DropDownItemsPicker(
                items: _availablePeriodsInDays.values,
                onItemSelected: (int selectedIndex) {
                  _selectedWalletAgeToIndex = selectedIndex;
                },
              ),
            ]
          ),
          const SizedBox(height: 56),
          const Text(
            'Transactions count:',
            style: TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 16
            )
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Period:',
                style: TextStyle(
                  color: AppTheme.textColorBody,
                  fontSize: 14
                )
              ),
              const SizedBox(width: 16),
              DropDownItemsPicker(
                items: _availablePeriodsInDays.values,
                onItemSelected: (int selectedIndex) {
                  _selectedTransactionsCountPeriodIndex = selectedIndex;
                },
              ),
              const SizedBox(width: 64),
              const Text(
                'From:',
                style: TextStyle(
                  color: AppTheme.textColorBody,
                  fontSize: 14
                )
              ),
              const SizedBox(width: 16),
              DropDownItemsPicker(
                items: _availableTransactionsCount.values,
                onItemSelected: (int selectedIndex) {
                  _selectedTransactionsCountFromIndex = selectedIndex;
                },
              ),
              const SizedBox(width: 64),
              const Text(
                'To:',
                style: TextStyle(
                  color: AppTheme.textColorBody,
                  fontSize: 14
                )
              ),
              const SizedBox(width: 16),
              DropDownItemsPicker(
                items: _availableTransactionsCount.values,
                onItemSelected: (int selectedIndex) {
                  _selectedTransactionsCountToIndex = selectedIndex;
                },
              ),
            ]
          ),
          const SizedBox(height: 96),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: CupertinoButton(
                  onPressed: _handleCreateButtonPressed,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.add,
                        color: CupertinoColors.black,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Create',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                        ),
                      )
                    ],
                  )
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
          const SizedBox(height: 24,)
        ],
      ),
    );
  }

  // Internal methods

  void _handleCreateButtonPressed() {

  }

  // Internal fields

  final String _domain;
  final _nameInput = TextInputField(placeholder: 'Segment name');
  final _descriptionInput = TextInputField(placeholder: 'Segment description');
  int _selectedWalletAgeFromIndex = 0;
  int _selectedWalletAgeToIndex = 0;
  int _selectedTransactionsCountPeriodIndex = 0;
  int _selectedTransactionsCountFromIndex = 0;
  int _selectedTransactionsCountToIndex = 0;

  final _availablePeriodsInDays = {
    -1 : 'Any',  // Corresponds to wallet age without time limitation
    7 : '7 days',
    30 : '1 month',
    90 : '3 months',
    180 : '6 months',
    365 : '1 year',
    730 : '2 years',
    1825 : '5 years'
  };

  final _availableTransactionsCount = {
    -1 : 'Any',
    10 : '10',
    100 : '100',
    1000 : '1000',
    10000 : '10 000',
    100000 : '100 000',
    1000000 : '1 000 000'
  };

}
