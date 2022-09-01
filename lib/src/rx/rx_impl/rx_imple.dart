
mixin RxObjectMixin<T> on RxImpl<T> {
  @override
  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  String get string => value.toString();

  @override
  String toString() => value.toString();

  /// Returns the json representation of `value`.
  dynamic toJson() => value;

  /// Updates the [value] and adds it to the stream, updating the observer
  /// Widget. Indistinct will always update whereas distinct (default) will only
  /// update when new value differs from the previous
  @override
  set value(T val) {
    if (isDisposed) return;
    super.value = val;
  }
}
