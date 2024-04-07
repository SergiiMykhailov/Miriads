import 'package:flutter/cupertino.dart';
import 'package:myriads/api/firestore/firestore_client.dart';
import 'package:myriads/models/segment_info.dart';
import 'package:myriads/ui/theme/app_theme.dart';
import 'package:myriads/ui/widgets/text_input_field.dart';
import 'package:myriads/utils/widget_extensions.dart';

// ignore: must_be_immutable
class CreateSegmentWidget extends StatefulWidget {

  // Public methods and properties

  const CreateSegmentWidget({
    required String domain,
    VoidCallback? onCreated,
    Key? key
  })
    : _domain = domain
    , _onCreated = onCreated
    , super(key: key);

  // Overridden methods

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => _CreateSegmentWidgetState(
    domain: _domain,
    onCreated: _onCreated
  );

  // Internal fields

  final String _domain;
  final VoidCallback? _onCreated;

}

class _CreateSegmentWidgetState extends State<CreateSegmentWidget> {

  // Public methods and properties

  _CreateSegmentWidgetState({
    required String domain,
    required VoidCallback? onCreated
  })
    : _domain = domain
    , _onCreated = onCreated;

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(children: [Expanded(child: _titleInput)]),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _minWalletAgeInput),
              const SizedBox(width: 16),
              Expanded(child: _maxWalletAgeInput)
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _transactionsCountPeriodInput),
              const SizedBox(width: 64),
              Expanded(child: _minTransactionsCountPerPeriodInput),
              const SizedBox(width: 64),
              Expanded(child: _maxTransactionsCountPerPeriodInput),
            ]
          ),
          const SizedBox(height: 56),
          const Text(
            'Google Analytics:',
            style: TextStyle(
              color: AppTheme.textColorBody,
              fontSize: 16
            )
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _utmSourceInput),
              const SizedBox(width: 64),
              Expanded(child: _utmMediumInput),
              const SizedBox(width: 64),
              Expanded(child: _utmCampaignInput),
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
                  onPressed: _isCreating ? null : _handleCreateButtonPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.add,
                        color: CupertinoColors.black,
                      ),
                      const SizedBox(width: 8),
                      _isCreating
                        ? const CupertinoActivityIndicator(color: CupertinoColors.black)
                        : const Text(
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

  void _handleCreateButtonPressed() async {
    updateState(() {
      _isCreating = true;
    });

    final title = _titleInput.text;
    final description = _descriptionInput.text;
    int? minWalletAgeInDays = int.tryParse(_minWalletAgeInput.text);
    int? maxWalletAgeInDays = int.tryParse(_maxWalletAgeInput.text);
    int? transactionsCountPeriod = int.tryParse(_transactionsCountPeriodInput.text);
    int? minTransactionsCountPerPeriod = int.tryParse(_minTransactionsCountPerPeriodInput.text);
    int? maxTransactionsCountPerPeriod = int.tryParse(_maxTransactionsCountPerPeriodInput.text);
    String? utmSource = _utmSourceInput.text;
    utmSource = utmSource.isNotEmpty ? utmSource : null;
    String? utmMedium = _utmMediumInput.text;
    utmMedium = utmMedium.isNotEmpty ? utmMedium : null;
    String? utmCampaign = _utmCampaignInput.text;
    utmCampaign = utmCampaign.isNotEmpty ? utmCampaign : null;

    final segmentInfo = SegmentInfo(
      title: title,
      description: description,
      minWalletAgeInDays: minWalletAgeInDays,
      maxWalletAgeInDays: maxWalletAgeInDays,
      transactionsCountPeriodInDays: transactionsCountPeriod,
      minTransactionsCountPerPeriod: minTransactionsCountPerPeriod,
      maxTransactionsCountPerPeriod: maxTransactionsCountPerPeriod,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign
    );

    await FirestoreClient.registerSegment(
      domain: _domain,
      segmentInfo: segmentInfo
    );

    updateState(() {
      _isCreating = false;

      if (_onCreated != null) {
        _onCreated();
      }
    });
  }

  // Internal fields

  final String _domain;
  final VoidCallback? _onCreated;

  final _titleInput = TextInputField(placeholder: 'Segment name');
  final _descriptionInput = TextInputField(placeholder: 'Segment description');
  final _minWalletAgeInput = TextInputField(placeholder: 'Min wallet age (days)');
  final _maxWalletAgeInput = TextInputField(placeholder: 'Max wallet age (days)');
  final _transactionsCountPeriodInput = TextInputField(placeholder: 'Transactions count period (days)');
  final _minTransactionsCountPerPeriodInput = TextInputField(placeholder: 'Min transactions count');
  final _maxTransactionsCountPerPeriodInput = TextInputField(placeholder: 'Max transactions count');
  final _utmSourceInput = TextInputField(placeholder: 'UTM Source');
  final _utmMediumInput = TextInputField(placeholder: 'UTM Medium');
  final _utmCampaignInput = TextInputField(placeholder: 'UTM Campaign');
  bool _isCreating = false;
}
