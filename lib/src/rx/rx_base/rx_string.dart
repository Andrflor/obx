library obx;

import '../../functions.dart';
import '../rx_impl/rx_core.dart';

extension RxStringExt on Rx<String> {
  /// The character (as a single-code-unit [String]) at the given [index].
  ///
  /// The returned string represents exactly one UTF-16 code unit, which may be
  /// half of a surrogate pair. A single member of a surrogate pair is an
  /// invalid UTF-16 string:
  /// ```dart
  /// var clef = '\u{1D11E}';
  /// // These represent invalid UTF-16 strings.
  /// clef[0].codeUnits;      // [0xD834]
  /// clef[1].codeUnits;      // [0xDD1E]
  /// ```
  /// This method is equivalent to
  /// `String.fromCharCode(this.codeUnitAt(index))`.
  String operator [](int index) => (observe(() => data[index]));

  /// Creates a new string by concatenating this string with [other].
  ///
  /// Example:
  /// ```dart
  /// const string = 'dart' + 'lang'; // 'dartlang'
  /// ```
  String operator +(String val) => (observe(() => data + val));

  /// Compares this string to [other].
  ///
  /// Returns a negative value if `this` is ordered before `other`,
  /// a positive value if `this` is ordered after `other`,
  /// or zero if `this` and `other` are equivalent.
  ///
  /// The ordering is the same as the ordering of the code units at the first
  /// position where the two strings differ.
  /// If one string is a prefix of the other,
  /// then the shorter string is ordered before the longer string.
  /// If the strings have exactly the same content, they are equivalent with
  /// regard to the ordering.
  /// Ordering does not check for Unicode equivalence.
  /// The comparison is case sensitive.
  /// ```dart
  /// var relation = 'Dart'.compareTo('Go');
  /// print(relation); // < 0
  /// relation = 'Go'.compareTo('Forward');
  /// print(relation); // > 0
  /// relation = 'Forward'.compareTo('Forward');
  /// print(relation); // 0
  /// ```
  int compareTo(String other) => data.compareTo(other);

  /// Returns true if this string ends with [other]. For example:
  ///
  ///     'Dart'.endsWith('t'); // true
  bool endsWith(String other) => observe(() => data.endsWith(other));

  /// The length of the string.
  ///
  /// Returns the number of UTF-16 code units in this string. The number
  /// of [runes] might be fewer if the string contains characters outside
  /// the Basic Multilingual Plane (plane 0):
  /// ```dart
  /// 'Dart'.length;          // 4
  /// 'Dart'.runes.length;    // 4
  ///
  /// var clef = '\u{1D11E}';
  /// clef.length;            // 2
  /// clef.runes.length;      // 1
  /// ```
  int get length => observe(() => data.length);

  /// Returns true if this string starts with a match of [pattern].
  bool startsWith(Pattern pattern, [int index = 0]) =>
      observe(() => data.startsWith(pattern, index));

  /// Returns the position of the first match of [pattern] in this string
  int indexOf(Pattern pattern, [int start = 0]) =>
      observe(() => data.indexOf(pattern, start));

  /// Returns the starting position of the last match [pattern] in this string,
  /// searching backward starting at [start], inclusive:
  int lastIndexOf(Pattern pattern, [int? start]) =>
      observe(() => data.lastIndexOf(pattern, start));

  /// Returns true if this string is empty.
  bool get isEmpty => observe(() => data.isEmpty);

  /// Returns true if this string is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Returns the substring of this string that extends from [startIndex],
  /// inclusive, to [endIndex], exclusive
  String substring(int startIndex, [int? endIndex]) =>
      observe(() => data.substring(startIndex, endIndex));

  /// Returns the string without any leading and trailing whitespace.
  String trim() => observe(() => data.trim());

  /// Returns the string without any leading whitespace.
  ///
  /// As [trim], but only removes leading whitespace.
  String trimLeft() => observe(() => data.trimLeft());

  /// Returns the string without any trailing whitespace.
  ///
  /// As [trim], but only removes trailing whitespace.
  String trimRight() => observe(() => data.trimRight());

  /// Pads this string on the left if it is shorter than [width].
  ///
  /// Return a new string that prepends [padding] onto this string
  /// one time for each position the length is less than [width].
  String padLeft(int width, [String padding = ' ']) =>
      observe(() => data.padLeft(width, padding));

  /// Pads this string on the right if it is shorter than [width].

  /// Return a new string that appends [padding] after this string
  /// one time for each position the length is less than [width].
  String padRight(int width, [String padding = ' ']) =>
      observe(() => data.padRight(width, padding));

  /// Returns true if this string contains a match of [other]:
  bool contains(Pattern other, [int startIndex = 0]) =>
      observe(() => data.contains(other, startIndex));

  /// Replaces all substrings that match [from] with [replace].
  String replaceAll(Pattern from, String replace) =>
      observe(() => data.replaceAll(from, replace));

  /// Replace the first occurrence of [from] in this string.
  ///
  /// ```dart
  /// const string = 'Dart is fun';
  /// print(string.replaceFirstMapped(
  ///     'fun', (m) => 'open source')); // Dart is open source
  ///
  /// print(string.replaceFirstMapped(
  ///     RegExp(r'\w(\w*)'), (m) => '<${m[0]}-${m[1]}>')); // <Dart-art> is fun
  /// ```
  ///
  /// Returns a new string, which is this string
  /// except that the first match of [from], starting from [startIndex],
  /// is replaced by the result of calling [replace] with the match object.
  ///
  /// The [startIndex] must be non-negative and no greater than [length].
  String replaceFirstMapped(Pattern from, String Function(Match match) replace,
          [int startIndex = 0]) =>
      observe(() => data.replaceFirstMapped(from, replace, startIndex));

  /// Splits the string at matches of [pattern] and returns a list
  /// of substrings.
  List<String> split(Pattern pattern) => observe(() => data.split(pattern));

  /// Replace all substrings that match [from] by a computed string.
  ///
  /// Creates a new string in which the non-overlapping substrings that match
  /// [from] (the ones iterated by `from.allMatches(thisString)`) are replaced
  /// by the result of calling [replace] on the corresponding [Match] object.
  ///
  /// This can be used to replace matches with new content that depends on the
  /// match, unlike [replaceAll] where the replacement string is always the same.
  ///
  /// The [replace] function is called with the [Match] generated
  /// by the pattern, and its result is used as replacement.
  ///
  /// The function defined below converts each word in a string to simplified
  /// 'pig latin' using [replaceAllMapped]:
  /// ```dart
  /// String pigLatin(String words) => words.replaceAllMapped(
  ///     RegExp(r'\b(\w*?)([aeiou]\w*)', caseSensitive: false),
  ///     (Match m) => "${m[2]}${m[1]}${m[1]!.isEmpty ? 'way' : 'ay'}");
  ///
  /// final result = pigLatin('I have a secret now!');
  /// print(result); // 'Iway avehay away ecretsay ownay!'
  /// ```
  String replaceAllMapped(Pattern from, String Function(Match match) replace) =>
      observe(() => data.replaceAllMapped(from, replace));

  /// Replaces the substring from [start] to [end] with [replacement].
  ///
  /// Creates a new string equivalent to:
  /// ```dart
  /// this.substring(0, start) + replacement + this.substring(end)
  /// ```
  /// Example:
  /// ```dart
  /// const string = 'Dart is fun';
  /// final result = string.replaceRange(8, null, 'open source');
  /// print(result); // Dart is open source
  /// ```
  /// The [start] and [end] indices must specify a valid range of this string.
  /// That is `0 <= start <= end <= this.length`.
  /// If [end] is `null`, it defaults to [length].
  String replaceRange(int start, int? end, String replacement) =>
      observe(() => data.replaceRange(start, end, replacement));

  /// Splits the string, converts its parts, and combines them into a new
  /// string.
  ///
  /// The [pattern] is used to split the string
  /// into parts and separating matches.
  /// Each match of [Pattern.allMatches] of [pattern] on this string is
  /// used as a match, and the substrings between the end of one match
  /// (or the start of the string) and the start of the next match (or the
  /// end of the string) is treated as a non-matched part.
  /// (There is no omission of leading or trailing empty matchs, like
  /// in [split], all matches and parts between the are included.)
  ///
  /// Each match is converted to a string by calling [onMatch]. If [onMatch]
  /// is omitted, the matched substring is used.
  ///
  /// Each non-matched part is converted to a string by a call to [onNonMatch].
  /// If [onNonMatch] is omitted, the non-matching substring itself is used.
  ///
  /// Then all the converted parts are concatenated into the resulting string.
  /// ```dart
  /// final result = 'Eats shoots leaves'.splitMapJoin(RegExp(r'shoots'),
  ///     onMatch: (m) => '${m[0]}', // (or no onMatch at all)
  ///     onNonMatch: (n) => '*');
  /// print(result); // *shoots*
  /// ```
  String splitMapJoin(Pattern pattern,
          {String Function(Match)? onMatch,
          String Function(String)? onNonMatch}) =>
      observe(() =>
          data.splitMapJoin(pattern, onMatch: onMatch, onNonMatch: onNonMatch));

  /// Returns an unmodifiable list of the UTF-16 code units of this string.
  List<int> get codeUnits => data.codeUnits;

  /// Returns an [Iterable] of Unicode code-points of this string.
  ///
  /// If the string contains surrogate pairs, they are combined and returned
  /// as one integer by this iterator. Unmatched surrogate halves are treated
  /// like valid 16-bit code-units.
  Runes get runes => data.runes;

  /// Converts all characters in this string to lower case.
  /// If the string is already in all lower case, this method returns `this`.
  String toLowerCase() => observe(() => data.toLowerCase());

  /// Converts all characters in this string to upper case.
  /// If the string is already in all upper case, this method returns `this`.
  String toUpperCase() => observe(() => data.toUpperCase());

  /// Matches this pattern against the string repeatedly.
  ///
  /// If [start] is provided, matching will start at that index.
  ///
  /// The returned iterable lazily finds non-overlapping matches
  /// of the pattern in the [string].
  /// If a user only requests the first match,
  /// this function should not compute all possible matches.
  ///
  /// The matches are found by repeatedly finding the first match
  /// of the pattern in the string, initially starting from [start],
  /// and then from the end of the previous match (but always
  /// at least one position later than the *start* of the previous
  /// match, in case the pattern matches an empty substring).
  /// ```dart
  /// RegExp exp = RegExp(r'(\w+)');
  /// var str = 'Dash is a bird';
  /// Iterable<Match> matches = exp.allMatches(str, 8);
  /// for (final Match m in matches) {
  ///   String match = m[0]!;
  ///   print(match);
  /// }
  /// ```
  /// The output of the example is:
  /// ```
  /// a
  /// bird
  /// ```
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      data.allMatches(string, start);

  ///
  /// Returns a match if the pattern matches a substring of [string]
  /// starting at [start], and `null` if the pattern doesn't match
  /// at that point.
  ///
  /// The [start] must be non-negative and no greater than `string.length`.
  /// ```dart
  /// final string = 'Dash is a bird';
  ///
  /// var regExp = RegExp(r'bird');
  /// var match = regExp.matchAsPrefix(string, 10); // Match found.
  ///
  /// regExp = RegExp(r'bird');
  /// match = regExp.matchAsPrefix(string); // null
  /// ```
  Match? matchAsPrefix(String string, [int start = 0]) =>
      data.matchAsPrefix(string, start);
}

extension RxnStringExt on Rx<String?> {
  /// The character (as a single-code-unit [String]) at the given [index].
  ///
  /// The returned string represents exactly one UTF-16 code unit, which may be
  /// half of a surrogate pair. A single member of a surrogate pair is an
  /// invalid UTF-16 string:
  /// ```dart
  /// var clef = '\u{1D11E}';
  /// // These represent invalid UTF-16 strings.
  /// clef[0].codeUnits;      // [0xD834]
  /// clef[1].codeUnits;      // [0xDD1E]
  /// ```
  /// This method is equivalent to
  /// `String.fromCharCode(this.codeUnitAt(index))`.
  String? operator [](int index) => (observe(() => data?[index]));

  /// Creates a new string by concatenating this string with [other].
  ///
  /// Example:
  /// ```dart
  /// const string = 'dart' + 'lang'; // 'dartlang'
  /// ```
  String operator +(String val) =>
      (observe(() => data == null ? val : data! + val));

  /// Compares this string to [other].
  ///
  /// Returns a negative value if `this` is ordered before `other`,
  /// a positive value if `this` is ordered after `other`,
  /// or zero if `this` and `other` are equivalent.
  ///
  /// The ordering is the same as the ordering of the code units at the first
  /// position where the two strings differ.
  /// If one string is a prefix of the other,
  /// then the shorter string is ordered before the longer string.
  /// If the strings have exactly the same content, they are equivalent with
  /// regard to the ordering.
  /// Ordering does not check for Unicode equivalence.
  /// The comparison is case sensitive.
  /// ```dart
  /// var relation = 'Dart'.compareTo('Go');
  /// print(relation); // < 0
  /// relation = 'Go'.compareTo('Forward');
  /// print(relation); // > 0
  /// relation = 'Forward'.compareTo('Forward');
  /// print(relation); // 0
  /// ```
  int? compareTo(String other) => observe(() => data?.compareTo(other));

  /// The length of the string.
  ///
  /// Returns the number of UTF-16 code units in this string. The number
  /// of [runes] might be fewer if the string contains characters outside
  /// the Basic Multilingual Plane (plane 0):
  /// ```dart
  /// 'Dart'.length;          // 4
  /// 'Dart'.runes.length;    // 4
  ///
  /// var clef = '\u{1D11E}';
  /// clef.length;            // 2
  /// clef.runes.length;      // 1
  /// ```
  int? get length => observe(() => data?.length);

  /// Returns true if this string ends with [other]. For example:
  ///
  ///     'Dart'.endsWith('t'); // true
  bool? endsWith(String other) => observe(() => data?.endsWith(other));

  /// Returns true if this string starts with a match of [pattern].
  bool? startsWith(Pattern pattern, [int index = 0]) =>
      observe(() => data?.startsWith(pattern, index));

  /// Returns the position of the first match of [pattern] in this string
  int? indexOf(Pattern pattern, [int start = 0]) =>
      observe(() => data?.indexOf(pattern, start));

  /// Returns the starting position of the last match [pattern] in this string,
  /// searching backward starting at [start], inclusive:
  int? lastIndexOf(Pattern pattern, [int? start]) =>
      observe(() => data?.lastIndexOf(pattern, start));

  /// Returns true if this string is empty.
  bool? get isEmpty => observe(() => data?.isEmpty);

  /// Returns true if this string is not empty.
  bool? get isNotEmpty => observe(() => data?.isNotEmpty);

  /// Returns the substring of this string that extends from [startIndex],
  /// inclusive, to [endIndex], exclusive
  String? substring(int startIndex, [int? endIndex]) =>
      observe(() => data?.substring(startIndex, endIndex));

  /// Returns the string without any leading and trailing whitespace.
  String? trim() => observe(() => data?.trim());

  /// Returns the string without any leading whitespace.
  ///
  /// As [trim], but only removes leading whitespace.
  String? trimLeft() => observe(() => data?.trimLeft());

  /// Returns the string without any trailing whitespace.
  ///
  /// As [trim], but only removes trailing whitespace.
  String? trimRight() => observe(() => data?.trimRight());

  /// Pads this string on the left if it is shorter than [width].
  ///
  /// Return a new string that prepends [padding] onto this string
  /// one time for each position the length is less than [width].
  String? padLeft(int width, [String padding = ' ']) =>
      observe(() => data?.padLeft(width, padding));

  /// Pads this string on the right if it is shorter than [width].

  /// Return a new string that appends [padding] after this string
  /// one time for each position the length is less than [width].
  String? padRight(int width, [String padding = ' ']) =>
      observe(() => data?.padRight(width, padding));

  /// Returns true if this string contains a match of [other]:
  bool? contains(Pattern other, [int startIndex = 0]) =>
      observe(() => data?.contains(other, startIndex));

  /// Replaces all substrings that match [from] with [replace].
  String? replaceAll(Pattern from, String replace) =>
      observe(() => data?.replaceAll(from, replace));

  /// Replace the first occurrence of [from] in this string.
  ///
  /// ```dart
  /// const string = 'Dart is fun';
  /// print(string.replaceFirstMapped(
  ///     'fun', (m) => 'open source')); // Dart is open source
  ///
  /// print(string.replaceFirstMapped(
  ///     RegExp(r'\w(\w*)'), (m) => '<${m[0]}-${m[1]}>')); // <Dart-art> is fun
  /// ```
  ///
  /// Returns a new string, which is this string
  /// except that the first match of [from], starting from [startIndex],
  /// is replaced by the result of calling [replace] with the match object.
  ///
  /// The [startIndex] must be non-negative and no greater than [length].
  String? replaceFirstMapped(Pattern from, String Function(Match match) replace,
          [int startIndex = 0]) =>
      observe(() => data?.replaceFirstMapped(from, replace, startIndex));

  /// Splits the string at matches of [pattern] and returns a list
  /// of substrings.
  List<String>? split(Pattern pattern) => observe(() => data?.split(pattern));

  /// Replace all substrings that match [from] by a computed string.
  ///
  /// Creates a new string in which the non-overlapping substrings that match
  /// [from] (the ones iterated by `from.allMatches(thisString)`) are replaced
  /// by the result of calling [replace] on the corresponding [Match] object.
  ///
  /// This can be used to replace matches with new content that depends on the
  /// match, unlike [replaceAll] where the replacement string is always the same.
  ///
  /// The [replace] function is called with the [Match] generated
  /// by the pattern, and its result is used as replacement.
  ///
  /// The function defined below converts each word in a string to simplified
  /// 'pig latin' using [replaceAllMapped]:
  /// ```dart
  /// String pigLatin(String words) => words.replaceAllMapped(
  ///     RegExp(r'\b(\w*?)([aeiou]\w*)', caseSensitive: false),
  ///     (Match m) => "${m[2]}${m[1]}${m[1]!.isEmpty ? 'way' : 'ay'}");
  ///
  /// final result = pigLatin('I have a secret now!');
  /// print(result); // 'Iway avehay away ecretsay ownay!'
  /// ```
  String? replaceAllMapped(
          Pattern from, String Function(Match match) replace) =>
      observe(() => data?.replaceAllMapped(from, replace));

  /// Replaces the substring from [start] to [end] with [replacement].
  ///
  /// Creates a new string equivalent to:
  /// ```dart
  /// this.substring(0, start) + replacement + this.substring(end)
  /// ```
  /// Example:
  /// ```dart
  /// const string = 'Dart is fun';
  /// final result = string.replaceRange(8, null, 'open source');
  /// print(result); // Dart is open source
  /// ```
  /// The [start] and [end] indices must specify a valid range of this string.
  /// That is `0 <= start <= end <= this.length`.
  /// If [end] is `null`, it defaults to [length].
  String? replaceRange(int start, int? end, String replacement) =>
      observe(() => data?.replaceRange(start, end, replacement));

  /// Splits the string, converts its parts, and combines them into a new
  /// string.
  ///
  /// The [pattern] is used to split the string
  /// into parts and separating matches.
  /// Each match of [Pattern.allMatches] of [pattern] on this string is
  /// used as a match, and the substrings between the end of one match
  /// (or the start of the string) and the start of the next match (or the
  /// end of the string) is treated as a non-matched part.
  /// (There is no omission of leading or trailing empty matchs, like
  /// in [split], all matches and parts between the are included.)
  ///
  /// Each match is converted to a string by calling [onMatch]. If [onMatch]
  /// is omitted, the matched substring is used.
  ///
  /// Each non-matched part is converted to a string by a call to [onNonMatch].
  /// If [onNonMatch] is omitted, the non-matching substring itself is used.
  ///
  /// Then all the converted parts are concatenated into the resulting string.
  /// ```dart
  /// final result = 'Eats shoots leaves'.splitMapJoin(RegExp(r'shoots'),
  ///     onMatch: (m) => '${m[0]}', // (or no onMatch at all)
  ///     onNonMatch: (n) => '*');
  /// print(result); // *shoots*
  /// ```
  String? splitMapJoin(Pattern pattern,
          {String Function(Match)? onMatch,
          String Function(String)? onNonMatch}) =>
      observe(() => data?.splitMapJoin(pattern,
          onMatch: onMatch, onNonMatch: onNonMatch));

  /// Returns an unmodifiable list of the UTF-16 code units of this string.
  List<int>? get codeUnits => data?.codeUnits;

  /// Returns an [Iterable] of Unicode code-points of this string.
  ///
  /// If the string contains surrogate pairs, they are combined and returned
  /// as one integer by this iterator. Unmatched surrogate halves are treated
  /// like valid 16-bit code-units.
  Runes? get runes => data?.runes;

  /// Converts all characters in this string to lower case.
  /// If the string is already in all lower case, this method returns `this`.
  String? toLowerCase() => observe(() => data?.toLowerCase());

  /// Converts all characters in this string to upper case.
  /// If the string is already in all upper case, this method returns `this`.
  String? toUpperCase() => observe(() => data?.toUpperCase());

  /// Matches this pattern against the string repeatedly.
  ///
  /// If [start] is provided, matching will start at that index.
  ///
  /// The returned iterable lazily finds non-overlapping matches
  /// of the pattern in the [string].
  /// If a user only requests the first match,
  /// this function should not compute all possible matches.
  ///
  /// The matches are found by repeatedly finding the first match
  /// of the pattern in the string, initially starting from [start],
  /// and then from the end of the previous match (but always
  /// at least one position later than the *start* of the previous
  /// match, in case the pattern matches an empty substring).
  /// ```dart
  /// RegExp exp = RegExp(r'(\w+)');
  /// var str = 'Dash is a bird';
  /// Iterable<Match> matches = exp.allMatches(str, 8);
  /// for (final Match m in matches) {
  ///   String match = m[0]!;
  ///   print(match);
  /// }
  /// ```
  /// The output of the example is:
  /// ```
  /// a
  /// bird
  /// ```
  Iterable<Match>? allMatches(String string, [int start = 0]) =>
      data?.allMatches(string, start);

  ///
  /// Returns a match if the pattern matches a substring of [string]
  /// starting at [start], and `null` if the pattern doesn't match
  /// at that point.
  ///
  /// The [start] must be non-negative and no greater than `string.length`.
  /// ```dart
  /// final string = 'Dash is a bird';
  ///
  /// var regExp = RegExp(r'bird');
  /// var match = regExp.matchAsPrefix(string, 10); // Match found.
  ///
  /// regExp = RegExp(r'bird');
  /// match = regExp.matchAsPrefix(string); // null
  /// ```
  Match? matchAsPrefix(String string, [int start = 0]) =>
      data?.matchAsPrefix(string, start);
}
