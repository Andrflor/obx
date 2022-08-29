import '../rx_impl/rx_core.dart';

extension RxIterableExt<T extends Iterable<E>, E> on Rx<T> {
  bool contains(Object? element) {
    return value.contains(element);
  }

  Iterator<E> get iterator => value.iterator;
  Rx<Iterable<S>> rxCast<S>() =>
      pipe((e) => e.map((event) => event.cast<S>()), init: (e) => e.cast<S>());

  // T cast<S>() => value.cast<S>();

  int get length => value.length;
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;

  test() {
    // value.single;
    // value.map((e) => null)
    // value.where((element) => false)
    // value.whereType()
    // value.expand((element) => null)
    // value.contains(element)
    // value.forEach((element) { })
    // value.reduce((value, element) => null)
    // value.fold(initialValue, (previousValue, element) => null)
    // value.every((element) => false)
    // value.join()
    // value.any((element) => false)
    // value.take(count)
    // value.takeWhile((value) => false)
    // value.skip(count)
    // value.skipWhile((value) => false)
    // value.singleWhere((element) => false)
    // value.firstWhere((element) => false)
    // value.lastWhere((element) => false)
    // value.elementAt(index)
  }

  E? get first => value.first;
  E? get last => value.first;

  Set<E> toSet() {
    return value.toSet();
  }

  List<E> toList({bool growable = true}) {
    return value.toList(growable: growable);
  }
}
