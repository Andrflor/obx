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
}

// TODO: find a way to make this not holding dynamic values
extension ListenableTransformer<T extends ValueListenable<E>, E> on T {
  /// Observable of the specified type
  Rx<E> get obs => value.obs..bind(this);

  // Make an rx from that value
  Rx<E> toRx() => Rx<E>.indistinct(value)..bind(this);
}

// TODO: find a way to proper make this work on class that extends Stream
extension StreamTransform<E> on Stream<E> {
  /// Observable of the specified type
  Rx<E> get obs => Rx<E>()..bind(this);

  Rx<E> toRx([E? initial]) => Rx<E>.indistinct(initial)..bind(this);
}

/// This is used to provide consistent api
extension RxDupe<E> on Rx<E> {
  /// Observable of the specified type
  Rx<E> get obs => dupe();
}

// TODO: find a way to have Embed with rxdart only if the user use it
// TODO: maybe add operators from collection in RxIterable?
// TODO: check how Obx would detect internal object change
// TODO: check all docuementation to be good
// TODO: write the README.md
