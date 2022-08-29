import 'package:flutter/foundation.dart';
import 'rx_core.dart';

typedef Emitter = RxNull;

//ignore: prefer_void_to_null
typedef RxNull = Rx<Null>;
typedef RxBool = Rx<bool>;
typedef RxInt = Rx<int>;
typedef RxNum = Rx<num>;
typedef RxDouble = Rx<double>;
typedef RxString = Rx<String>;
typedef RxIter<T> = Rx<Iterable<T>>;
typedef RxList<T> = Rx<List<T>>;
typedef RxSet<T> = Rx<Set<T>>;
typedef RxMap<K, V> = Rx<Map<K, V>>;

typedef RxnBool = Rx<bool?>;
typedef RxnInt = Rx<int?>;
typedef RxnNum = Rx<num?>;
typedef RxnDouble = Rx<double?>;
typedef RxnString = Rx<String?>;
typedef RxnIter<T> = Rx<Iterable<T>?>;
typedef RxnList<T> = Rx<List?>;
typedef RxnSet<T> = Rx<Set?>;
typedef RxnMap<K, V> = Rx<Map<K, V>?>;

extension RxT<T> on T {
  /// Observable of the specified type
  Rx<T> get obs => Rx<T>(this);

  /// Observable of the nullbale type
  Rx<T?> get nobs => Rx<T?>(this);

  /// Indistinct observable of the specified type
  Rx<T> get iobs => Rx<T>.indistinct(this);

  /// Indistinct observable of the nullable type
  Rx<T?> get inobs => Rx<T?>.indistinct(this);
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
