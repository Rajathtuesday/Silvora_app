/// Password-strength check for the vault password. Not a full zxcvbn-style
/// entropy scorer (no such dependency exists in this app, and that's a much
/// bigger abstraction than what's actually needed) -- this hand-rolled check
/// directly targets the concrete weaknesses a length-only floor lets through:
/// a repeated word ("passwordpassword"), a single repeated character
/// ("aaaaaaaaaaaa"), a common weak password, or a short sequential run.
class PasswordStrength {
  static const int minLength = 12;

  static const _commonPasswords = <String>{
    'password', 'password1', 'password123', 'passwordpassword',
    '123456789012', 'qwertyuiop', 'qwertyqwerty', 'letmein123',
    'iloveyou123', 'admin12345', 'welcome123', 'changeme123',
    'trustno1trustno1', 'monkeymonkey', 'dragondragon',
  };

  /// Returns null if [password] passes, or a user-facing reason it doesn't.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }

    final lower = password.toLowerCase();

    if (_commonPasswords.contains(lower) || _isRepeatedSubstring(lower)) {
      return 'This password is too predictable. Avoid repeating a word or common phrase.';
    }

    if (lower.split('').toSet().length < 6) {
      return 'Password needs more variety -- too few distinct characters.';
    }

    if (_hasLongSequentialRun(lower)) {
      return 'Password is too predictable -- avoid sequential characters like "abcd" or "1234".';
    }

    return null;
  }

  /// Catches "passwordpassword" (a short unit repeated to fill the length),
  /// not just an identical-character run.
  static bool _isRepeatedSubstring(String s) {
    for (int unitLen = 1; unitLen <= s.length ~/ 2; unitLen++) {
      if (s.length % unitLen != 0) continue;
      final unit = s.substring(0, unitLen);
      if (unit * (s.length ~/ unitLen) == s) return true;
    }
    return false;
  }

  /// Catches 4+ character ascending/descending runs, e.g. "abcd" or "4321".
  static bool _hasLongSequentialRun(String s) {
    int ascRun = 1, descRun = 1;
    for (int i = 1; i < s.length; i++) {
      final diff = s.codeUnitAt(i) - s.codeUnitAt(i - 1);
      ascRun = diff == 1 ? ascRun + 1 : 1;
      descRun = diff == -1 ? descRun + 1 : 1;
      if (ascRun >= 4 || descRun >= 4) return true;
    }
    return false;
  }
}
