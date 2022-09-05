import 'dart:async';

import 'rx_core.dart';

typedef Rxn<T> = Rx<T?>;

typedef RxBool = Rx<bool>;
typedef RxInt = Rx<int>;
typedef RxNum = Rx<num>;
typedef RxDouble = Rx<double>;
typedef RxString = Rx<String>;
typedef RxIter<T> = Rx<Iterable<T>>;
typedef RxList<T> = Rx<List<T>>;
typedef RxSet<T> = Rx<Set<T>>;
typedef RxMap<K, V> = Rx<Map<K, V>>;
typedef RxMapEntry<K, V> = Rx<MapEntry<K, V>>;

typedef RxnBool = Rxn<bool>;
typedef RxnInt = Rxn<int>;
typedef RxnNum = Rxn<num>;
typedef RxnDouble = Rxn<double>;
typedef RxnString = Rxn<String>;
typedef RxnIter<T> = Rxn<Iterable<T>>;
typedef RxnList<T> = Rxn<List>;
typedef RxnSet<T> = Rxn<Set>;
typedef RxnMap<K, V> = Rxn<Map<K, V>>;
typedef RxnMapEntry<K, V> = Rxn<MapEntry<K, V>>;

typedef Worker<T> = StreamSubscription<T> Function(void Function(T)?,
    {bool? cancelOnError, void Function()? onDone, Function? onError});

typedef StreamTransformation<S, T> = Stream<S> Function(Stream<T> stream);
typedef StreamFilter<T> = StreamTransformation<T, T>;
