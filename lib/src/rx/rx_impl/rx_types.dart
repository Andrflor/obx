import 'dart:async';

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

typedef Worker<T> = StreamSubscription<T> Function(void Function(T)?,
    {bool? cancelOnError, void Function()? onDone, Function? onError});

typedef StreamTransformation<S, T> = Stream<S> Function(Stream<T> stream);
typedef StreamFilter<T> = StreamTransformation<T, T>;

// TODO: maybe add operators from collection in RxIterable?
// TODO: check how Obx would detect internal object change
// TODO: check all docuementation to be good
// TODO: write the README.md
