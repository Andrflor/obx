import '../rx_impl/rx_core.dart';

extension RxBoolExt on Rx<bool> {
  bool get isTrue => value;

  bool get isFalse => !isTrue;

  bool operator &(bool other) => observe((e) => other && e);

  bool operator |(bool other) => observe((e) => other || e);

  bool operator ^(bool other) => observe((e) => !other == e);

  /// Toggles the bool [value] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() => call(!value);
}

extension RxnBoolExt on Rx<bool?> {
  bool? get isTrue => value;

  bool? get isFalse => static == null ? value : !value!;

  bool? operator &(bool other) => observe((e) => e == null ? null : other && e);

  bool? operator |(bool other) => observe((e) => e == null ? null : other || e);

  bool? operator ^(bool other) =>
      observe((e) => e == null ? null : !other == e);

  /// Toggles the bool [value] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() {
    if (value != null) {
      call(!value!);
    }
  }
}
