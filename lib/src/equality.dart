import 'package:collection/collection.dart';

class NeverEquality<E> implements Equality<E> {
  const NeverEquality();

  @override
  equals(E? e1, E? e2) => false;

  @override
  int hash(E e) {
    throw UnimplementedError();
  }

  @override
  bool isValidKey(Object? o) {
    throw UnimplementedError();
  }
}

class BaseEquality<E> implements Equality<E> {
  const BaseEquality();
  @override
  equals(E? e1, E? e2) => e1 == e2;

  @override
  int hash(E e) {
    throw UnimplementedError();
  }

  @override
  bool isValidKey(Object? o) {
    throw UnimplementedError();
  }
}
