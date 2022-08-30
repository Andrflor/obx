import '../rx_impl/rx_core.dart';
import '../rx_impl/rx_types.dart';

// TODO: add docuementation from dart
// TODO: add all needed from iterable
// TODO: add list specific stuff
// TODO: make sure it properly works with implem
// TODO: write the extension for Rx<List<E>?>
extension RxListExt<E> on Rx<List<E>> {
  Iterator<E> get iterator => value.iterator;

  E operator [](int index) {
    return value[index];
  }

  void operator []=(int index, E val) {
    value[index] = val;
    refresh();
  }

  List<S> cast<S>() => value.cast<S>();
  Rx<List<S>> pipeCast<S>() => pipeMap((e) => e.cast<S>());

  List<E> toList() => value;
  Rx<List<E>> toListSet() => dupe();

  /// Special override to push() element(s) in a reactive way
  /// inside the List,
  RxList<E> operator +(Iterable<E> val) {
    addAll(val);
    refresh();
    return this;
  }

  void add(E element) {
    value.add(element);
    refresh();
  }

  void addAll(Iterable<E> iterable) {
    value.addAll(iterable);
    refresh();
  }

  void removeWhere(bool Function(E element) test) {
    value.removeWhere(test);
    refresh();
  }

  void retainWhere(bool Function(E element) test) {
    value.retainWhere(test);
    refresh();
  }

  int get length => value.length;

  // @override
  // @protected
  // List<E> get value {
  //   RxInterface.proxy?.addListener(subject);
  //   return subject.value;
  // }

  set length(int newLength) {
    value.length = newLength;
    refresh();
  }

  void insertAll(int index, Iterable<E> iterable) {
    value.insertAll(index, iterable);
    refresh();
  }

  Iterable<E> get reversed => value.reversed;

  Iterable<E> where(bool Function(E) test) {
    return value.where(test);
  }

  Iterable<T> whereType<T>() {
    return value.whereType<T>();
  }

  void sort([int Function(E a, E b)? compare]) {
    value.sort(compare);
    refresh();
  }
}
