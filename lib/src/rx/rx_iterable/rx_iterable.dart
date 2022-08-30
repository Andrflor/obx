import '../rx_impl/rx_core.dart';
import '../../notifier.dart';

bool isSubtype<S, T>() => <S>[] is List<T>;

// TODO: add dart documentation to those iterators

extension RxIterableExt<T extends Iterable<E>, E> on Rx<T> {
  Iterator<E> get iterator => value.iterator;

  S _observe<S>(S Function(T val) toElement) => Notifier.inBuild
      ? OneShot.fromMap<T, S>(this, toElement).value
      : toElement(static);

  Iterable<S> cast<S>() => value.cast<S>();
  Rx<Iterable<S>?> pipeCast<S>() => pipeMap((e) => e.cast<S>());

  int get length => _observe((e) => e.length);

  bool get isEmpty => _observe((e) => e.isEmpty);
  bool get isNotEmpty => _observe((e) => e.isEmpty);

  E get first => _observe((e) => e.first);
  E get last => _observe((e) => e.last);
  E get single => _observe((e) => e.single);

  bool contains(Object? element) => _observe((e) => e.contains(
      element is Rx && !isSubtype<E, Rx>() ? element.value : element));

  void forEach(void Function(E element) action) => value.forEach(action);

  Iterable<E> where(bool Function(E e) test) => _observe((e) => e.where(test));

  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _observe((e) => e.singleWhere(test, orElse: orElse));
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _observe((e) => e.firstWhere(test, orElse: orElse));
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _observe((e) => e.lastWhere(test, orElse: orElse));
  E elementAt(int index) => _observe((e) => e.elementAt(index));

  Iterable<S> map<S>(S Function(E e) toElement) =>
      _observe((e) => e.map<S>(toElement));
  Iterable<S> whereType<S>() => _observe((e) => e.whereType<S>());
  Iterable<S> expand<S>(Iterable<S> Function(E element) toElements) =>
      _observe((e) => e.expand<S>(toElements));

  E reduce(E Function(E value, E element) combine) =>
      _observe((e) => e.reduce(combine));
  S fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      _observe((e) => e.fold<S>(initialValue, combine));

  String join([String separator = ""]) => _observe((e) => e.join(separator));
  bool every(bool Function(E element) test) => _observe((e) => e.every(test));
  bool any(bool Function(E element) test) => _observe((e) => e.any(test));

  Iterable<E> take(int count) => _observe((e) => e.take(count));
  Iterable<E> takeWhile(bool Function(E element) test) =>
      _observe((e) => e.takeWhile(test));

  Iterable<E> skip(int count) => _observe((e) => e.skip(count));
  Iterable<E> skipWhile(bool Function(E element) test) =>
      _observe((e) => e.skipWhile(test));

  Set<E> toSet() => value.toSet();
  Rx<Set<E>?> toPipeSet() => pipeMap((e) => e.toSet());

  List<E> toList({bool growable = true}) => value.toList(growable: growable);
  Rx<List<E>> toPipeList({bool growable = true}) =>
      pipeMap((e) => e.toList(growable: growable));
}

extension RxnIterableExt<T extends Iterable<E>?, E> on Rx<T> {
  Iterator<E>? get iterator => value?.iterator;

  S? _observe<S>(S? Function(T val) toElement) => Notifier.inBuild
      ? OneShot.fromMap<T, S?>(this, toElement).value
      : toElement(static);

  Iterable<S>? cast<S>() => value?.cast<S>();
  Rx<Iterable<S>?> pipeCast<S>() => pipeMap((e) => e?.cast<S>());

  int? get length => _observe((e) => e?.length);

  bool? get isEmpty => _observe((e) => e?.isEmpty);
  bool? get isNotEmpty => _observe((e) => e?.isEmpty);

  E? get first => _observe((e) => e?.first);
  E? get last => _observe((e) => e?.last);
  E? get single => _observe((e) => e?.single);

  bool? contains(Object? element) => _observe((e) => e?.contains(
      element is Rx && !isSubtype<E, Rx>() ? element.value : element));

  void forEach(void Function(E element) action) => value?.forEach(action);

  Iterable<E>? where(bool Function(E e) test) =>
      _observe((e) => e?.where(test));

  E? singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _observe((e) => e?.singleWhere(test, orElse: orElse));
  E? firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _observe((e) => e?.firstWhere(test, orElse: orElse));
  E? lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _observe((e) => e?.lastWhere(test, orElse: orElse));
  E? elementAt(int index) => _observe((e) => e?.elementAt(index));

  Iterable<S>? map<S>(S Function(E e) toElement) =>
      _observe((e) => e?.map<S>(toElement));
  Iterable<S>? whereType<S>() => _observe((e) => e?.whereType<S>());
  Iterable<S>? expand<S>(Iterable<S> Function(E element) toElements) =>
      _observe((e) => e?.expand<S>(toElements));

  E? reduce(E Function(E value, E element) combine) =>
      _observe((e) => e?.reduce(combine));
  S? fold<S>(S initialValue, S Function(S previousValue, E element) combine) =>
      _observe((e) => e?.fold<S>(initialValue, combine));

  String? join([String separator = ""]) => _observe((e) => e?.join(separator));
  bool? every(bool Function(E element) test) => _observe((e) => e?.every(test));
  bool? any(bool Function(E element) test) => _observe((e) => e?.any(test));

  Iterable<E>? take(int count) => _observe((e) => e?.take(count));
  Iterable<E>? takeWhile(bool Function(E element) test) =>
      _observe((e) => e?.takeWhile(test));

  Iterable<E>? skip(int count) => _observe((e) => e?.skip(count));
  Iterable<E>? skipWhile(bool Function(E element) test) =>
      _observe((e) => e?.skipWhile(test));

  Set<E>? toSet() => value?.toSet();
  Rx<Set<E>?> toPipeSet() => pipeMap((e) => e?.toSet());

  List<E>? toList({bool growable = true}) => value?.toList(growable: growable);
  Rx<List<E>?> toPipeList({bool growable = true}) =>
      pipeMap((e) => e?.toList(growable: growable));
}
