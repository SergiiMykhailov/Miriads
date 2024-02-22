extension StringExtensions on String {

  // Works only with single character. Otherwise return source string.
  String trimTrailingCharacter(String trailingCharacter) {
    if (this.isEmpty || trailingCharacter.length != 1) {
      return this;
    }

    int lastEntryIndex = length - 1;
    while (lastEntryIndex >= 0 && this[lastEntryIndex] == trailingCharacter) {
      lastEntryIndex--;
    }

    if (lastEntryIndex == 0) {
      return '';
    }

    final result = substring(0, lastEntryIndex + 1);
    return result;
  }
}