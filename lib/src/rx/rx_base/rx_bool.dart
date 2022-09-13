library obx;

import '../../functions.dart';
import '../rx_impl/rx_core.dart';

extension RxBoolExt on Rx<bool> {
  bool get isTrue => value;

  bool get isFalse => !isTrue;

  bool operator &(bool other) => observe(() => other && value);

  bool operator |(bool other) => observe(() => other || value);

  bool operator ^(bool other) => observe(() => !other == value);

  /// Toggles the bool [value] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() => call(!value);
}

extension RxnBoolExt on Rx<bool?> {
  bool? get isTrue => value;

  bool? get isFalse => value == null ? value : !value!;

  bool? operator &(bool other) =>
      observe(() => value == null ? null : other && value!);

  bool? operator |(bool other) =>
      observe(() => value == null ? null : other || value!);

  bool? operator ^(bool other) =>
      observe(() => value == null ? null : !other == value);

  /// Toggles the bool [value] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() {
    if (value != null) {
      call(!value!);
    }
  }
}
