import '../rx_impl/rx_core.dart';

typedef Condition = bool Function();

extension RxSetExt<E> on Rx<Set<E>> {
  /// Special override to push() element(s) in a reactive way
  /// inside the List,
  Rx<Set<E>> operator +(Set<E> val) {
    addAll(val);
    refresh();
    return this;
  }

  bool add(E value) {
    final hasAdded = this.value.add(value);
    if (hasAdded) {
      refresh();
    }
    return hasAdded;
  }

  bool contains(Object? element) {
    return value.contains(element);
  }

  Iterator<E> get iterator => value.iterator;

  int get length => value.length;

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

  Set<E> toSet() {
    return value.toSet();
  }

  List<E> toList() {
    return value.toList();
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

  /// Add [item] to [List<E>] only if [condition] is true.
  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  /// Adds [Iterable<E>] to [List<E>] only if [condition] is true.
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
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

extension RxnSetExt<E> on Rx<Set<E>?> {
  /// Special override to push() element(s) in a reactive way
  /// inside the List,
  Rx<Set<E>?> operator +(Set<E> val) {
    addAll(val);
    refresh();
    return this;
  }

  bool add(E value) {
    final hasAdded = this.value?.add(value) ?? false;
    if (hasAdded) {
      refresh();
    }
    return hasAdded;
  }

  bool? contains(Object? element) {
    return value?.contains(element);
  }

  Iterator<E>? get iterator => value?.iterator;

  int? get length => value?.length;
  bool? get isEmpty => value?.isEmpty;
  bool? get isNotEmpty => value?.isNotEmpty;

  E? get first => value?.first;
  E? get last => value?.first;

  E? lookup(Object? element) {
    return value?.lookup(element);
  }

  bool remove(Object? value) {
    var hasRemoved = this.value?.remove(value) ?? false;
    if (hasRemoved) {
      refresh();
    }
    return hasRemoved;
  }

  Set<E>? toSet() {
    return value?.toSet();
  }

  List<E>? toList() {
    return value?.toList();
  }

  void addAll(Iterable<E> elements) {
    value?.addAll(elements);
    refresh();
  }

  void clear() {
    value?.clear();
    refresh();
  }

  void removeAll(Iterable<Object?> elements) {
    value?.removeAll(elements);
    refresh();
  }

  void retainAll(Iterable<Object?> elements) {
    value?.retainAll(elements);
    refresh();
  }

  void retainWhere(bool Function(E) test) {
    value?.retainWhere(test);
    refresh();
  }

  /// Add [item] to [List<E>] only if [condition] is true.
  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  /// Adds [Iterable<E>] to [List<E>] only if [condition] is true.
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
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

extension SetExtension<E> on Set<E> {
  /// Add [item] to [List<E>] only if [condition] is true.
  void addIf(dynamic condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  /// Adds [Iterable<E>] to [List<E>] only if [condition] is true.
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
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
