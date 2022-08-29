import '../rx_impl/rx_core.dart';

extension RxIterableExt<T extends Iterable<E>, E> on Rx<T> {
  Iterator<E> get iterator => value.iterator;

  Iterable<S> cast<S>() => value.cast<S>();
  Rx<Iterable<S>> rxCast<S>() =>
      pipe((e) => e.map((event) => event.cast<S>()), init: (e) => e.cast<S>());

  int get length => value.length;
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;

  E get first => value.first;
  E get last => value.last;
  E get single => value.single;

  bool contains(Object? element) => value.contains(element);
  void forEach(void Function(E element) action) => value.forEach(action);

  Iterable<E> where(bool Function(E e) test) => value.where(test);

  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.singleWhere(test, orElse: orElse);
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.firstWhere(test, orElse: orElse);
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.lastWhere(test, orElse: orElse);
  E elementAt(int index) => value.elementAt(index);

  Iterable<S> map<S>(S Function(E e) toElement) => value.map<S>(toElement);
  Iterable<S> whereType<S>() => value.whereType<S>();
  Iterable<S> expand<S>(Iterable<S> Function(E element) toElements) =>
      value.expand<S>(toElements);

  E reduce(E Function(E value, E element) combine) => value.reduce(combine);
  S fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      value.fold<S>(initialValue, combine);

  String join([String separator = ""]) => value.join(separator);
  bool every(bool Function(E element) test) => value.every(test);
  bool any(bool Function(E element) test) => value.any(test);

  Iterable<E> take(int count) => value.take(count);
  Iterable<E> takeWhile(bool Function(E element) test) => value.takeWhile(test);

  Iterable<E> skip(int count) => value.skip(count);
  Iterable<E> skipWhile(bool Function(E element) test) => value.skipWhile(test);

  Set<E> toSet() => value.toSet();
  Rx<Set<E>> toRxSet() =>
      pipe((e) => e.map((e) => e.toSet()), init: (e) => e.toSet());

  List<E> toList({bool growable = true}) => value.toList(growable: growable);
  Rx<List<E>> toRxList({bool growable = true}) =>
      pipe((e) => e.map((e) => e.toList(growable: growable)),
          init: (e) => e.toList(growable: growable));
}

extension RxnIterableExt<T extends Iterable<E>?, E> on Rx<T> {
  Iterator<E>? get iterator => value?.iterator;

  Iterable<S>? cast<S>() => value?.cast<S>();
  Rx<Iterable<S>?> rxCast<S>() =>
      pipe((e) => e.map((event) => event?.cast<S>()),
          init: (e) => e?.cast<S>());

  int? get length => value?.length;
  bool? get isEmpty => value?.isEmpty;
  bool? get isNotEmpty => value?.isNotEmpty;

  E? get first => value?.first;
  E? get last => value?.last;
  E? get single => value?.single;

  bool? contains(Object? element) => value?.contains(element);
  void forEach(void Function(E element) action) => value?.forEach(action);

  Iterable<E>? where(bool Function(E e) test) => value?.where(test);

  E? singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value?.singleWhere(test, orElse: orElse);
  E? firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value?.firstWhere(test, orElse: orElse);
  E? lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value?.lastWhere(test, orElse: orElse);
  E? elementAt(int index) => value?.elementAt(index);

  Iterable<S>? map<S>(S Function(E e) toElement) => value?.map<S>(toElement);
  Iterable<S>? whereType<S>() => value?.whereType<S>();
  Iterable<S>? expand<S>(Iterable<S> Function(E element) toElements) =>
      value?.expand<S>(toElements);

  E? reduce(E Function(E value, E element) combine) => value?.reduce(combine);
  S fold<S>(S initialvalue, S Function(S previousvalue, E element) combine) =>
      value?.fold<S>(initialvalue, combine) ?? initialvalue;

  String? join([String separator = ""]) => value?.join(separator);
  bool? every(bool Function(E element) test) => value?.every(test);
  bool? any(bool Function(E element) test) => value?.any(test);

  Iterable<E>? take(int count) => value?.take(count);
  Iterable<E>? takeWhile(bool Function(E element) test) =>
      value?.takeWhile(test);

  Iterable<E>? skip(int count) => value?.skip(count);
  Iterable<E>? skipWhile(bool Function(E element) test) =>
      value?.skipWhile(test);

  Set<E>? toSet() => value?.toSet();
  Rx<Set<E>?> toRxSet() =>
      pipe((e) => e.map((e) => e?.toSet()), init: (e) => e?.toSet());

  List<E>? toList({bool growable = true}) => value?.toList(growable: growable);
  Rx<List<E>?> toRxList({bool growable = true}) =>
      pipe((e) => e.map((e) => e?.toList(growable: growable)),
          init: (e) => e?.toList(growable: growable));
}
