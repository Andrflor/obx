import '../rx_impl/rx_core.dart';
import '../../notifier.dart';

// TODO: add dart documentation to those iterators

extension RxIterableExt<T extends Iterable<E>, E> on Rx<T> {
  Iterator<E> get iterator => value.iterator;
  E operator [](int index) => elementAt(index);

  bool operator <(num other) => observe((e) => e.length < other);
  bool operator <=(num other) => observe((e) => e.length <= other);

  bool operator >(num other) => observe((e) => e.length > other);
  bool operator >=(num other) => observe((e) => e.length >= other);

  Iterable<S> cast<S>() => value.cast<S>();
  Rx<Iterable<S>?> pipeCast<S>() => pipeMap((e) => e.cast<S>());

  int get length => observe((e) => e.length);

  bool get isEmpty => observe((e) => e.isEmpty);
  bool get isNotEmpty => observe((e) => e.isEmpty);

  E get first => observe((e) => e.first);
  E get last => observe((e) => e.last);
  E get single => observe((e) => e.single);

  bool contains(Object? element) => observe((e) => e.contains(
      element is Rx && !isSubtype<E, Rx>() ? element.value : element));

  void forEach(void Function(E element) action) => value.forEach(action);

  Iterable<E> where(bool Function(E e) test) => observe((e) => e.where(test));

  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe((e) => e.singleWhere(test, orElse: orElse));
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe((e) => e.firstWhere(test, orElse: orElse));
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe((e) => e.lastWhere(test, orElse: orElse));
  E elementAt(int index) => observe((e) => e.elementAt(index));

  Iterable<S> map<S>(S Function(E e) toElement) =>
      observe((e) => e.map<S>(toElement));
  Iterable<S> whereType<S>() => observe((e) => e.whereType<S>());
  Iterable<S> expand<S>(Iterable<S> Function(E element) toElements) =>
      observe((e) => e.expand<S>(toElements));

  E reduce(E Function(E value, E element) combine) =>
      observe((e) => e.reduce(combine));
  S fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      observe((e) => e.fold<S>(initialValue, combine));

  String join([String separator = ""]) => observe((e) => e.join(separator));
  bool every(bool Function(E element) test) => observe((e) => e.every(test));
  bool any(bool Function(E element) test) => observe((e) => e.any(test));

  Iterable<E> take(int count) => observe((e) => e.take(count));
  Iterable<E> takeWhile(bool Function(E element) test) =>
      observe((e) => e.takeWhile(test));

  Iterable<E> followedBy(Iterable<E> other) =>
      observe((e) => e.followedBy(other));

  Iterable<E> skip(int count) => observe((e) => e.skip(count));
  Iterable<E> skipWhile(bool Function(E element) test) =>
      observe((e) => e.skipWhile(test));

  Set<E> toSet() => value.toSet();
  Rx<Set<E>?> toPipeSet() => pipeMap((e) => e.toSet());

  List<E> toList({bool growable = true}) => value.toList(growable: growable);
  Rx<List<E>> toPipeList({bool growable = true}) =>
      pipeMap((e) => e.toList(growable: growable));
}

extension RxnIterableExt<T extends Iterable<E>?, E> on Rx<T> {
  Iterator<E>? get iterator => value?.iterator;
  E? operator [](int index) => elementAt(index);

  bool operator <(num other) =>
      observe((e) => e == null ? true : e.length < other);
  bool operator <=(num other) =>
      observe((e) => e == null ? true : e.length <= other);

  bool operator >(num other) =>
      observe((e) => e == null ? false : e.length > other);
  bool operator >=(num other) =>
      observe((e) => e == null ? false : e.length >= other);

  Iterable<S>? cast<S>() => value?.cast<S>();
  Rx<Iterable<S>?> pipeCast<S>() => pipeMap((e) => e?.cast<S>());

  int? get length => observe((e) => e?.length);

  bool? get isEmpty => observe((e) => e?.isEmpty);
  bool? get isNotEmpty => observe((e) => e?.isEmpty);

  E? get first => observe((e) => e?.first);
  E? get last => observe((e) => e?.last);
  E? get single => observe((e) => e?.single);

  bool? contains(Object? element) => observe((e) => e?.contains(
      element is Rx && !isSubtype<E, Rx>() ? element.value : element));

  void forEach(void Function(E element) action) => value?.forEach(action);

  Iterable<E>? where(bool Function(E e) test) => observe((e) => e?.where(test));

  E? singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe((e) => e?.singleWhere(test, orElse: orElse));
  E? firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe((e) => e?.firstWhere(test, orElse: orElse));
  E? lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe((e) => e?.lastWhere(test, orElse: orElse));
  E? elementAt(int index) => observe((e) => e?.elementAt(index));

  Iterable<S>? map<S>(S Function(E e) toElement) =>
      observe((e) => e?.map<S>(toElement));
  Iterable<S>? whereType<S>() => observe((e) => e?.whereType<S>());
  Iterable<S>? expand<S>(Iterable<S> Function(E element) toElements) =>
      observe((e) => e?.expand<S>(toElements));

  E? reduce(E Function(E value, E element) combine) =>
      observe((e) => e?.reduce(combine));
  S? fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      observe((e) => e?.fold<S>(initialValue, combine));

  String? join([String separator = ""]) => observe((e) => e?.join(separator));
  bool? every(bool Function(E element) test) => observe((e) => e?.every(test));
  bool? any(bool Function(E element) test) => observe((e) => e?.any(test));

  Iterable<E>? take(int count) => observe((e) => e?.take(count));
  Iterable<E>? takeWhile(bool Function(E element) test) =>
      observe((e) => e?.takeWhile(test));

  Iterable<E>? followedBy(Iterable<E> other) =>
      observe((e) => e?.followedBy(other));

  Iterable<E>? skip(int count) => observe((e) => e?.skip(count));
  Iterable<E>? skipWhile(bool Function(E element) test) =>
      observe((e) => e?.skipWhile(test));

  Set<E>? toSet() => value?.toSet();
  Rx<Set<E>?> toPipeSet() => pipeMap((e) => e?.toSet());

  List<E>? toList({bool growable = true}) => value?.toList(growable: growable);
  Rx<List<E>?> toPipeList({bool growable = true}) =>
      pipeMap((e) => e?.toList(growable: growable));
}
