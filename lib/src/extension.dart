import 'package:flutter/foundation.dart';
import 'rx.dart';

extension RxT<T> on T {
  /// Observable of the specified type
  Rx<T> get obs => Rx<T>(this);

  /// Observable of the nullbale type
  Rx<T?> get nobs => Rx<T?>(this);

  /// Indistinct observable of the specified type
  Rx<T> get iobs => Rx<T>(this, distinct: false);

  /// Indistinct observable of the nullable type
  Rx<T?> get inobs => Rx<T?>(this, distinct: false);
}

extension ListenableTransform<T> on ValueListenable<T> {
  toRx({bool distinct = true}) {
    Rx.fromListenable(this, distinct: distinct);
  }
}

extension StreamTransform<T> on Stream<T> {
  toRx({bool distinct = true}) {
    Rx.fromStream(this, distinct: distinct);
  }
}
