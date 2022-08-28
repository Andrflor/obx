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

extension ListenableTransforme<T> on ValueNotifier<T> {
  /// Observable of the specified type
  Rx<T> get obs => value.obs..bind(this);

  /// Observable of the nullbale type
  Rx<T?> get nobs => value.nobs..bind(this);

  /// Indistinct observable of the specified type
  Rx<T> get iobs => value.iobs..bind(this);

  /// Indistinct observable of the nullable type
  Rx<T?> get inobs => value.inobs..bind(this);

  // Make an rx from that value
  Rx<T> toRx(T initial) => initial.obs..bind(this);
}

extension StreamTransform<T> on Stream<T> {
  /// Observable of the specified type
  Rx<T?> get obs => nobs;

  /// Observable of the nullbale type
  Rx<T?> get nobs => null.nobs..bind(this);

  /// Indistinct observable of the specified type
  Rx<T?> get iobs => inobs;

  /// Indistinct observable of the nullable type
  Rx<T?> get inobs => null.inobs..bind(this);

  Rx<T> toRx(T initial) => initial.obs..bind(this);
}
