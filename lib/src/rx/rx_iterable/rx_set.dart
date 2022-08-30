import '../rx_impl/rx_core.dart';

// TODO: add docuementation from dart
// TODO: add set specific stuff
// TODO: make sure it properly works with implem
// TODO: write the extension for Rx<Set<E>?>
extension RxSetExt<E> on Rx<Set<E>> {
  /// Special override to push() element(s) in a reactive way
  /// inside the Set
  Rx<Set<E>> operator +(Iterable<E> val) {
    addAll(val);
    refresh();
    return this;
  }

  E operator [](int index) {
    return value.elementAt(index);
  }

  void operator []=(int index, E val) {
    value.remove(value.elementAt(index));
    value.add(val);
    refresh();
  }

  Set<S> cast<S>() => value.cast<S>();
  Rx<Set<S>> pipeCast<S>() => pipeMap((e) => e.cast<S>());

  Set<E> toSet() => value;
  Rx<Set<E>> toPipeSet() => dupe();

  bool add(E value) {
    final hasAdded = this.value.add(value);
    if (hasAdded) {
      refresh();
    }
    return hasAdded;
  }

  E? lookup(Object? element) {
    return value.lookup(element);
  }

  bool remove(Object? value) {
    var hasRemoved = this.value.remove(value);
    if (hasRemoved) {
      refresh();
    }
    return hasRemoved;
  }

  void addAll(Iterable<E> elements) {
    value.addAll(elements);
    refresh();
  }

  void clear() {
    value.clear();
    refresh();
  }

  void removeAll(Iterable<Object?> elements) {
    value.removeAll(elements);
    refresh();
  }

  void retainAll(Iterable<Object?> elements) {
    value.retainAll(elements);
    refresh();
  }

  void retainWhere(bool Function(E) test) {
    value.retainWhere(test);
    refresh();
  }

  /// Replaces all existing items of this list with [item]
  void assign(E item) {
    clear();
    add(item);
  }

  /// Replaces all existing items of this list with [items]
  void assignAll(Iterable<E> items) {
    clear();
    addAll(items);
  }
}
