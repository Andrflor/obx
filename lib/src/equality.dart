import 'package:collection/collection.dart' as coll;

/// Little helper for type checks
bool isSubtype<S, T>() => <S>[] is List<T>;

/// Little helpers to check if a type is a collection
bool isList<T>() => isSubtype<T, List?>();
bool isMap<T>() => isSubtype<T, Map?>();
bool isSet<T>() => isSubtype<T, Set?>();
bool isIterable<T>() => isSubtype<T, Iterable?>();

/// Defines the equalizer depending on T
Equality equalizer<T>(bool distinct) {
  if (distinct) {
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
  if (isIterable<T>()) {
    if (isList<T>()) {
      return const ListIndistinctEquality();
    }
    if (isSet<T>()) {
      return const SetIndistinctEquality();
    } else {
      return const IterableIndistinctEquality();
    }
  } else if (isMap<T>()) {
    return const MapIndistinctEquality();
  } else {
    return const DefaultIndistinctEquality();
  }
}

/// Defines the equalizer depending on T
Equality equalizing<T>(T? val, bool distinct) {
  if (distinct) {
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
  if (val is Map) {
    return const MapIndistinctEquality();
  }
  if (val is List) {
    return const ListIndistinctEquality();
  }
  if (val is Set) {
    return const SetIndistinctEquality();
  }
  return const IterableIndistinctEquality();
}

// Override to get foreignEquals
mixin Equality<E> on coll.Equality<E> {
  bool foreignEquals(E? e1, Object? e2) => e1 == e2;
  bool memberEquals(E e1, E e2) => equals(e1, e2);
}

// Override to get foreignEquals
mixin IndistinctEquality<E> on Equality<E> {
  @override
  bool memberEquals(E e1, E e2) => false;
}

class DefaultEquality<E> = coll.DefaultEquality<E> with Equality<E>;

class DefaultIndistinctEquality<E> = DefaultEquality<E>
    with IndistinctEquality<E>;

class ListEquality<E> extends coll.ListEquality<E> with Equality<List<E>> {
  const ListEquality([super.elementEquality]);

  @override
  bool foreignEquals(List<E>? e1, Object? e2) =>
      e2 is List<E>? ? equals(e1, e2) : false;
}

class ListIndistinctEquality<E> extends ListEquality<E>
    with IndistinctEquality<List<E>> {
  const ListIndistinctEquality([super.elementEquality]);
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

class SetIndistinctEquality<E> extends SetEquality<E>
    with IndistinctEquality<Set<E>> {
  const SetIndistinctEquality([super.elementEquality]);
}

class MapEquality<K, V> extends coll.MapEquality<K, V>
    with Equality<Map<K, V>> {
  const MapEquality({super.keys, super.values});
  @override
  bool foreignEquals(Map<K, V>? e1, Object? e2) =>
      e2 is Map<K, V>? ? equals(e1, e2) : false;
}

class MapIndistinctEquality<K, V> extends MapEquality<K, V>
    with IndistinctEquality<Map<K, V>> {
  const MapIndistinctEquality({super.keys, super.values});
}

class IterableEquality<E> extends coll.IterableEquality<E>
    with Equality<Iterable<E>> {
  const IterableEquality([super.elementEquality]);
  @override
  bool foreignEquals(Iterable<E>? e1, Object? e2) =>
      e2 is Iterable<E>? ? equals(e1, e2) : false;
}

class IterableIndistinctEquality<E> extends IterableEquality<E>
    with IndistinctEquality<Iterable<E>> {
  const IterableIndistinctEquality([super.elementEquality]);
}
