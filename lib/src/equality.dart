import 'package:collection/collection.dart';

class NeverEquality<E> implements Equality<E> {
  const NeverEquality();

  @override
  equals(E? e1, E? e2) => false;

  @override
  int hash(E e) => e.hashCode;

  @override
  bool isValidKey(Object? o) => o is E;
}
