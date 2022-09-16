library obx;

import '../../functions.dart';
import '../rx_impl/rx_core.dart';

extension RxBoolExt on Rx<bool> {
  bool get isTrue => data;

  bool get isFalse => !isTrue;

  bool operator &(bool other) => observe(() => other && data);

  bool operator |(bool other) => observe(() => other || data);

  bool operator ^(bool other) => observe(() => !other == data);

  /// Toggles the bool [data] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() => call(!data);
}

extension RxnBoolExt on Rx<bool?> {
  bool? get isTrue => data;

  bool? get isFalse => data == null ? data : !data!;

  bool? operator &(bool other) =>
      observe(() => data == null ? null : other && data!);

  bool? operator |(bool other) =>
      observe(() => data == null ? null : other || data!);

  bool? operator ^(bool other) =>
      observe(() => data == null ? null : !other == data);

  /// Toggles the bool [data] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() {
    if (data != null) {
      call(!data!);
    }
  }
}
