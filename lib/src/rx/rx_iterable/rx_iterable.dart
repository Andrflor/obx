import '../rx_impl/rx_core.dart';

extension RxIterableExt<T extends Iterable<E>, E> on Rx<T> {
  Iterator<E> get iterator => value.iterator;
  Rx<Iterable<S>> rxCast<S>() =>
      pipe((e) => e.map((event) => event.cast<S>()), init: (e) => e.cast<S>());

  Iterable<S> cast<S>() => value.cast<S>();
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

  Iterable<E> reduce() => value.reduce((value, element) => null);
  Iterable<E> fold() =>
      value.fold(initialValue, (previousValue, element) => null);
  Iterable<E> every() => value.every((element) => false);
  Iterable<E> join() => value.join();
  Iterable<E> any() => value.any((element) => false);
  Iterable<E> take() => value.take(count);
  Iterable<E> takeWhile() => value.takeWhile((value) => false);
  Iterable<E> skip() => value.skip(count);
  Iterable<E> skipWhile() => value.skipWhile((value) => false);

  Set<E> toSet() => value.toSet();
  List<E> toList({bool growable = true}) => value.toList(growable: growable);
}
