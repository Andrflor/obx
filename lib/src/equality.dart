import 'package:collection/collection.dart' as coll;

/// Little helper for type checks
bool isSubtype<S, T>() => <S>[] is List<T>;

/// Little helpers to check if a type is a collection
bool isList<T>() => isSubtype<T, List?>();
bool isMap<T>() => isSubtype<T, Map?>();
bool isSet<T>() => isSubtype<T, Set?>();
bool isIterable<T>() => isSubtype<T, Iterable?>();

/// Defines the equalizer depending on T
Equality equalizer<T>() {
  if (isIterable<T>()) {
    if (isList<T>()) {
      return const ListEquality();
    }
    if (isSet<T>()) {
      return const SetEquality();
    } else {
      return const IterableEquality();
    }
  } else if (isMap<T>()) {
    return const MapEquality();
  } else {
    return const DefaultEquality();
  }
}

/// Defines the equalizer depending on T
Equality equalizing<T>(T? val) {
  if (val == null) return equalizer<T>();
  if (val is Map) {
    return const MapEquality();
  }
  if (val is List) {
    return const ListEquality();
  }
  if (val is Set) {
    return const SetEquality();
  }
  return const IterableEquality();
}

// Override to get foreignEquals
mixin Equality<E> on coll.Equality<E> {
  bool foreignEquals(E? e1, Object? e2) => e1 == e2;
}

class DefaultEquality<E> = coll.DefaultEquality<E> with Equality<E>;

class ListEquality<E> extends coll.ListEquality<E> with Equality<List<E>> {
  const ListEquality([super.elementEquality]);

  @override
  bool foreignEquals(List<E>? e1, Object? e2) =>
      e2 is List<E>? ? equals(e1, e2) : false;
}

class SetEquality<E> extends coll.SetEquality<E> with Equality<Set<E>> {
  const SetEquality([super.elementEquality]);
  @override
  bool foreignEquals(Set<E>? e1, Object? e2) =>
      e2 is Set<E>? ? equals(e1, e2) : false;

  @override
  bool equals(Set<E>? elements1, Set<E>? elements2) {
    if (identical(elements1, elements2)) return true;
    if (elements1 == null || elements2 == null) return false;
    if (elements1.length != elements2.length) return false;
    return elements1.difference(elements2).isEmpty;
  }
}

class MapEquality<K, V> extends coll.MapEquality<K, V>
    with Equality<Map<K, V>> {
  const MapEquality({super.keys, super.values});
  @override
  bool foreignEquals(Map<K, V>? e1, Object? e2) =>
      e2 is Map<K, V>? ? equals(e1, e2) : false;
}

class IterableEquality<E> extends coll.IterableEquality<E>
    with Equality<Iterable<E>> {
  const IterableEquality([super.elementEquality]);
  @override
  bool foreignEquals(Iterable<E>? e1, Object? e2) =>
      e2 is Iterable<E>? ? equals(e1, e2) : false;
}
