import 'package:flutter/foundation.dart';
import 'rx_core.dart';

typedef Emitter = RxNull;
typedef Rxn<T> = Rx<T?>;

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

typedef RxnBool = Rxn<bool>;
typedef RxnInt = Rxn<int>;
typedef RxnNum = Rxn<num>;
typedef RxnDouble = Rxn<double>;
typedef RxnString = Rxn<String>;
typedef RxnIter<T> = Rxn<Iterable<T>>;
typedef RxnList<T> = Rxn<List>;
typedef RxnSet<T> = Rxn<Set>;
typedef RxnMap<K, V> = Rxn<Map<K, V>>;

// TODO: find a way to make this not holding dynamic values
extension ListenableTransformer<T extends ValueListenable<E>, E> on T {
  /// Observable of the specified type
  // Make an rx from that value
  Rx<E> toRx() => Rx<E>.indistinct(value)..bind(this);
  Rxn<E> toRxn() => Rxn<E>.indistinct(value)..bind(this);
}

// TODO: find a way to proper make this work on class that extends Stream
extension StreamTransform<E> on Stream<E> {
  /// Observable of the specified type

  Rx<E> toRx([E? initial]) => Rx<E>.indistinct(initial)..bind(this);
  Rxn<E> toRxn([E? initial]) => Rxn<E>.indistinct(initial)..bind(this);
}


// TODO: find a way to have Embed with rxdart only if the user use it
// TODO: maybe add operators from collection in RxIterable?
// TODO: check how Obx would detect internal object change
// TODO: check all docuementation to be good
// TODO: write the README.md
