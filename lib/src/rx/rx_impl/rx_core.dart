import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../obx.dart';
import 'rx_impl.dart';

class Rx<T> extends RxImpl<T> {
  Rx._({T? initial, bool distinct = true}) : super(initial, distinct: distinct);

  // TODO: doc
  Rx([T? initial]) : super(initial, distinct: true);

  /// Creates an indistinct [Rx<T>]
  ///
  /// The contructed [Rx] will emit change everytime it's value changes
  /// Even if the value is the same as last time
  /// This is particuliry usefull in some scenarios
  Rx.indistinct([T? initial]) : super(initial, distinct: false);

  /// Creates a [Rx<T>] from any [Stream<T>]
  ///
  /// [Stream<T>] do not hold a value but you may still want to init your [Rx<T>]
  /// If you want a starting value you can provide the `init` parameter
  ///
  /// Finally, by default the [rx<t>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromStream(Stream<T> stream, {T? init, super.distinct}) : super(init) {
    bindStream(stream);
  }

  /// Creates a [Rx<T>] from any [Listenable]
  ///
  /// If your [Listenable] is [ValueListenable<T>] use [fromValueListenable] instead
  /// You need to provide a `onEvent` callback as [T Function()]
  /// This callback will be use to provide values to the [Rx<T>]
  ///
  /// [Listenable] do not hold a value but you may still want to init your [Rx<T>]
  /// If you want a starting value you can provide the `init` parameter
  /// You can also generate the first value with the callback by setting
  /// `callbackInit` parameter to true
  ///
  /// Finally, by default the [rx<t>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromListenable(Listenable listenable,
      {required T Function() onEvent,
      T? init,
      super.distinct,
      bool callbackInit = false})
      : super(callbackInit ? onEvent() : init) {
    bindListenable(listenable, onEvent: onEvent);
  }

  /// Creates a [Rx<T>] from any [ValueListenable<T>]
  ///
  /// If you want another value than the current value that is hold by the
  /// [ValueListenable<T>] you can provide the `init` parameter
  ///
  /// This function is practicaly usefull to create [Rx<T>] from
  /// a [ValueNotifier<T>] since it implements [ValueListenable<T>]
  ///
  /// Finally, by default the [rx<t>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromValueListenable(ValueListenable<T> listenable,
      {T? init, super.distinct})
      : super(init ?? listenable.value) {
    bindValueListenable(listenable);
  }

  /// Oberve the result of the equality
  @override
  bool operator ==(Object o) {
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

  /// Generates an [Rx<S>] based on [StreamTransformation<S,T>] of this [Rx<T>]
  ///
  /// You need to provide the stream transformation
  /// You can also provide an initial transformation (default to initial value)
  /// Be aware that if your stream transform change the internal type
  /// And you don't provide an initial transformation
  /// The value of the observable will default to null or empty
  /// If you want an initial value in such cases you must provide the initital transformation
  /// Be aware, you must call detatch or dispose otherwise streams won't close
  Rx<S> pipe<S>(StreamTransformation<S, T> transformer,
          {S? Function(T e)? init, bool? distinct}) =>
      _clone(
        convert: init,
        distinct: distinct,
      )..bindStream(transformer(subject.stream));

  /// Maps this [Rx<T>] into a new [Rx<S>]
  ///
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

  /// Create an exact copy of the [Rx<T>]
  /// The dupe will receive all event comming from the original
  Rx<T> dupe() => _dupe();

  /// Create an exact copy of the [Rx<T>] but distinct enforced
  ///
  /// The dupe will receive all event comming from the original
  /// Events that are indistinct will be skipped
  Rx<T> distinct() => _dupe(distinct: true);

  /// Create an exact copy of the [Rx<T>] but indistinct enforced
  ///
  /// The dupe will receive all event comming from the original
  /// Be aware that even if this observable is indistinct
  /// The value it recieves from the parent will match parent policy
  Rx<T> indistinct() => _dupe(distinct: false);
}
