import 'package:flutter/cupertino.dart';
import 'package:myriads/ui/theme/app_theme.dart';

class TextInputField extends StatelessWidget {

  // Public methods and properties

  TextInputField({
    String placeholder = '',
    Key? key
  })
    : _placeholder = placeholder
    , super(key: key);

  // Overridden methods

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.textColorBody.withOpacity(0.5),
          width: 1.0,
        )
      ),
      child: CupertinoTextField(
        controller: _controller,
        placeholder: _placeholder,
        placeholderStyle: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppTheme.textColorBody.withOpacity(0.35),
        ),
        minLines: 1,
        maxLines: 100000,
        decoration: const BoxDecoration(
          color: null
        ),
        style: const TextStyle(
          color: AppTheme.textColorBody,
          fontSize: 14
        ),
      ),
    );
  }

  // Internal fields

  final String _placeholder;
  final TextEditingController _controller = TextEditingController();

}