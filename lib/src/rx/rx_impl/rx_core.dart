import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../functions.dart';
import 'rx_impl.dart';

class Rx<T> extends RxImpl<T> {
  Rx._({T? initial, bool distinct = true}) : super(initial, distinct: distinct);

  Rx([T? initial]) : super(initial, distinct: true);

  /// Constructor for the indistinct version of a [Rx]
  Rx.indistinct([T? initial]) : super(initial, distinct: false);

  Rx.fromStream(Stream<T> stream, {T? init, super.distinct}) : super(init) {
    bindStream(stream);
  }

  // TODO: bind this callback to create a rx from this
  // TODO: make a proper implem for it
  Rx.fuse(T Function() callback) : super(null);

  // TODO: make this a private constructor
  Rx.fromListenable(Listenable listenable, T Function() onEvent,
      {T? init, super.distinct})
      : super(init ??
            (listenable is ValueListenable<T> ? listenable.value : null)) {
    bindListenable(listenable);
  }

  Rx.fromValueListenable(ValueListenable<T> listenable,
      {T? init, super.distinct})
      : super(init ?? listenable.value) {
    bindListenable(listenable);
  }

  /// Oberve the result of the equality
  @override
  bool operator ==(Object o) {
    // TODO: find a common implementation for the hashCode of different Types.
    return observe(() => o is T
        ? value == o
        : (o is ValueListenable<T> ? value == o.value : false));
  }

  Rx<S> _clone<S>({bool? distinct, S? Function(T e)? convert}) => Rx._(
      // TODO assert if null is S or not in that
      initial: hasValue ? (convert?.call(value) ?? value as S) : null,
      distinct: distinct ?? isDistinct);
  Rx<T> _dupe({bool? distinct}) =>
      _clone(distinct: distinct)..bindStream(subject.stream);

  /// Generates an obserable based on stream transformation of the observable
  /// You need to provide the stream transformation
  /// You can also provide an initial transformation (default to initial value)
  /// Be aware that if your stream transform change the internal type
  /// And you don't provide an initial transformation
  /// The value of the observable will default to null or empty
  /// If you want an initial value in such cases you must provide the initital transformation
  /// Be aware, you must call detatch or dispose otherwise streams won't close
  Rx<S> pipe<S>(Stream<S> Function(Stream<T> stream) transformer,
          {S? Function(T e)? init, bool? distinct}) =>
      _clone(
        convert: init,
        distinct: distinct,
      )..bindStream(transformer(subject.stream));

  /// This is a convenient function to make a common pipe operation
  /// This will map the value of this observable in another
  /// Do not chain that kind of operators
  /// If you have more complex operation to do, use pipe instead
  Rx<S> pipeMap<S>(S Function(T e) transform, {bool? distinct}) =>
      pipe((e) => e.map(transform), init: transform, distinct: distinct);

  /// This is a convenient function to make a common pipe operation
  /// This will create an observalbe based on the condition assertion
  /// Do not chain that kind of operators
  /// If you have more complex operation to do, use pipe instead
  Rx<T> pipeWhere(bool Function(T e) test, {bool? distinct}) =>
      pipe((e) => e.where(test), distinct: distinct);

  /// This is a convenient function to make a common pipe operation
  /// This will first map it and then assert the condition
  /// Do not chain operators, prefer this
  /// If you have more complex operation to do, use pipe instead
  Rx<S> pipeMapWhere<S>(S Function(T e) transform, bool Function(S e) test,
          {bool? distinct}) =>
      pipe((e) => e.map(transform).where(test),
          init: transform, distinct: distinct);

  /// This is a convenient function to make a common pipe operation
  /// This will first assert the condition then map it
  /// Do not chain operators, prefer this
  /// If you have more complex operation to do, use pipe instead
  Rx<S> pipeWhereMap<S>(bool Function(T e) test, S Function(T e) transform,
          {bool? distinct}) =>
      pipe((e) => e.where(test).map(transform),
          init: transform, distinct: distinct);

  /// Create an exact copy of the observable
  /// The dupe will receive all event comming from the original
  Rx<T> dupe() => _dupe();

  /// Create an exact copy of the observable but distinct enforced
  /// The dupe will receive all event comming from the original
  /// Events that are indistinct will be skipped
  Rx<T> distinct() => _dupe(distinct: true);

  /// Create an exact copy of the observable but indistinct enforced
  /// The dupe will receive all event comming from the original
  /// Be aware that even if this observable is indistinct
  /// The value it recieves from the parent will match parent policy
  Rx<T> indistinct() => _dupe(distinct: false);
}
