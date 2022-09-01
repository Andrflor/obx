import '../../functions.dart';
import '../rx_impl/rx_core.dart';
import '../../notifier.dart';

// TODO: add dart documentation to those iterators
extension RxIterableExt<T extends Iterable<E>, E> on Rx<T> {
  Iterator<E> get iterator => value.iterator;
  E operator [](int index) => elementAt(index);

  bool operator <(num other) => observe(() => value.length < other);
  bool operator <=(num other) => observe(() => value.length <= other);

  bool operator >(num other) => observe(() => value.length > other);
  bool operator >=(num other) => observe(() => value.length >= other);

  Iterable<S> cast<S>() => value.cast<S>();
  Rx<Iterable<S>?> pipeCast<S>() => pipeMap((e) => value.cast<S>());

  int get length => observe(() => value.length);

  bool get isEmpty => observe(() => value.isEmpty);
  bool get isNotEmpty => observe(() => value.isEmpty);

  E get first => observe(() => value.first);
  E get last => observe(() => value.last);
  E get single => observe(() => value.single);

  bool contains(Object? element) => observe(() => value.contains(
      element is Rx && !isSubtype<E, Rx>() ? element.value : element));

  void forEach(void Function(E element) action) => value.forEach(action);

  Iterable<E> where(bool Function(E value) test) =>
      observe(() => value.where(test));

  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe(() => value.singleWhere(test, orElse: orElse));
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe(() => value.firstWhere(test, orElse: orElse));
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe(() => value.lastWhere(test, orElse: orElse));
  E elementAt(int index) => observe(() => value.elementAt(index));

  Iterable<S> map<S>(S Function(E value) toElement) =>
      observe(() => value.map<S>(toElement));
  Iterable<S> whereType<S>() => observe(() => value.whereType<S>());
  Iterable<S> expand<S>(Iterable<S> Function(E element) toElements) =>
      observe(() => value.expand<S>(toElements));

  E reduce(E Function(E value, E element) combine) =>
      observe(() => value.reduce(combine));
  S fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      observe(() => value.fold<S>(initialValue, combine));

  String join([String separator = ""]) => observe(() => value.join(separator));
  bool every(bool Function(E element) test) => observe(() => value.every(test));
  bool any(bool Function(E element) test) => observe(() => value.any(test));

  Iterable<E> take(int count) => observe(() => value.take(count));
  Iterable<E> takeWhile(bool Function(E element) test) =>
      observe(() => value.takeWhile(test));

  Iterable<E> followedBy(Iterable<E> other) =>
      observe(() => value.followedBy(other));

  Iterable<E> skip(int count) => observe(() => value.skip(count));
  Iterable<E> skipWhile(bool Function(E element) test) =>
      observe(() => value.skipWhile(test));

  Set<E> toSet() => value.toSet();
  Rx<Set<E>?> toPipeSet() => pipeMap((e) => value.toSet());

  List<E> toList({bool growable = true}) => value.toList(growable: growable);
  Rx<List<E>> toPipeList({bool growable = true}) =>
      pipeMap((e) => value.toList(growable: growable));
}

extension RxnIterableExt<T extends Iterable<E>?, E> on Rx<T> {
  Iterator<E>? get iterator => value?.iterator;
  E? operator [](int index) => elementAt(index);

  bool operator <(num other) =>
      observe(() => value == null ? true : value!.length < other);
  bool operator <=(num other) =>
      observe(() => value == null ? true : value!.length <= other);

  bool operator >(num other) =>
      observe(() => value == null ? false : value!.length > other);
  bool operator >=(num other) =>
      observe(() => value == null ? false : value!.length >= other);

  Iterable<S>? cast<S>() => value?.cast<S>();
  Rx<Iterable<S>?> pipeCast<S>() => pipeMap((e) => e?.cast<S>());

  int? get length => observe(() => value?.length);

  bool? get isEmpty => observe(() => value?.isEmpty);
  bool? get isNotEmpty => observe(() => value?.isEmpty);

  E? get first => observe(() => value?.first);
  E? get last => observe(() => value?.last);
  E? get single => observe(() => value?.single);

  bool? contains(Object? element) => observe(() => value?.contains(
      element is Rx && !isSubtype<E, Rx>() ? element.value : element));

  void forEach(void Function(E element) action) => value?.forEach(action);

  Iterable<E>? where(bool Function(E value) test) =>
      observe(() => value?.where(test));

  E? singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe(() => value?.singleWhere(test, orElse: orElse));
  E? firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe(() => value?.firstWhere(test, orElse: orElse));
  E? lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      observe(() => value?.lastWhere(test, orElse: orElse));
  E? elementAt(int index) => observe(() => value?.elementAt(index));

  Iterable<S>? map<S>(S Function(E value) toElement) =>
      observe(() => value?.map<S>(toElement));
  Iterable<S>? whereType<S>() => observe(() => value?.whereType<S>());
  Iterable<S>? expand<S>(Iterable<S> Function(E element) toElements) =>
      observe(() => value?.expand<S>(toElements));

  E? reduce(E Function(E value, E element) combine) =>
      observe(() => value?.reduce(combine));
  S? fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      observe(() => value?.fold<S>(initialValue, combine));

  String? join([String separator = ""]) =>
      observe(() => value?.join(separator));
  bool? every(bool Function(E element) test) =>
      observe(() => value?.every(test));
  bool? any(bool Function(E element) test) => observe(() => value?.any(test));

  Iterable<E>? take(int count) => observe(() => value?.take(count));
  Iterable<E>? takeWhile(bool Function(E element) test) =>
      observe(() => value?.takeWhile(test));

  Iterable<E>? followedBy(Iterable<E> other) =>
      observe(() => value?.followedBy(other));

  Iterable<E>? skip(int count) => observe(() => value?.skip(count));
  Iterable<E>? skipWhile(bool Function(E element) test) =>
      observe(() => value?.skipWhile(test));

  Set<E>? toSet() => value?.toSet();
  Rx<Set<E>?> toPipeSet() => pipeMap((e) => e?.toSet());

  List<E>? toList({bool growable = true}) => value?.toList(growable: growable);
  Rx<List<E>?> toPipeList({bool growable = true}) =>
      pipeMap((e) => value?.toList(growable: growable));
}
