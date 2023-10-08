library obx;

import 'package:collection/collection.dart';

class NeverEquality<E> implements Equality<E> {
  const NeverEquality();

  @override
  bool equals(E? e1, E? e2) => false;

  @override
  int hash(E e) => e.hashCode;

  @override
  bool isValidKey(Object? o) => o is E;
}

class PropEquality<E, F> implements Equality<E> {
  final F Function(E) _comparisonKey;

  final Equality<F> _inner;

  const PropEquality(F Function(E) comparisonKey,
      [Equality<F> inner = const DefaultEquality<Never>()])
      : _comparisonKey = comparisonKey,
        _inner = inner;

  @override
  bool equals(E e1, E e2) =>
      _inner.equals(_comparisonKey(e1), _comparisonKey(e2));

  @override
  int hash(E e) => _inner.hash(_comparisonKey(e));

  @override
  bool isValidKey(Object? o) {
    if (o is E) {
      final value = _comparisonKey(o);
      return _inner.isValidKey(value);
    }
    return false;
  }
}

class CallbackEquality<E> implements Equality<E> {
  final bool Function(E? e1, E? e2) callback;
  const CallbackEquality(this.callback);

  @override
  bool equals(E? e1, E? e2) => callback(e1, e2);

  @override
  int hash(E e) => e.hashCode;

  @override
  bool isValidKey(Object? o) => o is E;
}

class CacheWrapper<E> extends Wrapper<E> {
  E? value;
  CacheWrapper(super.eq);

  @override
  bool equals(E? e1, E? e2) {
    final res = eq.equals(e1, e2);
    if (res) {
      value = e1;
    }
    return res;
  }
}

class BufferWrapper<E> extends Wrapper<E> {
  final List<E?> values = [];
  final int bufferSize;
  BufferWrapper(super.eq, [this.bufferSize = 10]);

  @override
  bool equals(E? e1, E? e2) {
    final res = eq.equals(e1, e2);
    if (res) {
      if (values.length > bufferSize) {
        values.removeAt(0);
      }
      values.add(e1);
    }
    return res;
  }
}

class Wrapper<E> implements Equality<E> {
  final Equality eq;
  const Wrapper(this.eq);

  @override
  bool equals(E? e1, E? e2) => eq.equals(e1, e2);

  @override
  int hash(E e) => eq.hash(e);

  @override
  bool isValidKey(Object? o) => eq.isValidKey(o);
}
