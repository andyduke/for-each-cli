extension StringTrim on String {
  /*
  String trimTrailingChars(String pattern) {
    var i = length;
    while (startsWith(pattern, i - pattern.length)) {
      i -= pattern.length;
    }
    return substring(0, i);
  }

  String trimLeadingChars(String pattern) {
    var i = 0;
    while (startsWith(pattern, i)) {
      i += pattern.length;
    }
    return substring(i);
  }

  String trimChars(String pattern) {
    return trimLeadingChars(pattern).trimTrailingChars(pattern);
  }
  */

  String trimChar(String pattern) {
    var start = 0;
    var end = length;

    if (startsWith(pattern, 0)) {
      start++;
      if (startsWith(pattern, length - pattern.length)) end--;
    }

    return substring(start, end);
  }
}
