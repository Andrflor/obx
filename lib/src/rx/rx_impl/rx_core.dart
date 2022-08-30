import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../notifier.dart';

class Rx<T> extends _RxImpl<T> {
  Rx._({T? initial, bool distinct = true}) : super(initial, distinct: distinct);

  Rx([T? initial]) : super(initial, distinct: true);

  Rx.distinct([T? initial]) : super(initial, distinct: true);
  Rx.indistinct([T? initial]) : super(initial, distinct: false);

  static S oneShot<S>(S value) => Notifier.inBuild ? Rx<S>(value).value : value;

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }

  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert}) => Rx._(
      initial: convert?.call(static) ?? static as S,
      distinct: distinct ?? isDistinct);
  Rx<T> _dupe({bool? distinct}) =>
      _clone(distinct: distinct)..bindStream(subject.stream);

  /// Generate an obserable based on stream transformation observable
  /// You need to provide a stream transformation
  /// You can also provide an initial transformation (default to initial value)
  /// Be aware that if your stream transform change the internal type
  /// Then you must provide an initital transformation
  Rx<S> pipe<S>(Stream<S> Function(Stream<T> e) transformer,
          {S Function(T e)? init, bool? distinct}) =>
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

  /// Create a standalone copy of the observale
  /// Distinct parameter is used to enforce distinct or indistinct
  Rx<T> clone({bool? distinct}) => _clone(distinct: distinct);

  /// Create an exact copy with same stream of the observable
  Rx<T> dupe() => _dupe();

  /// Same as dupe but enforce distinct
  Rx<T> distinct() => _dupe(distinct: true);

  /// Same as dupe but enforce indistinct
  Rx<T> indistinct() => _dupe(distinct: false);

  /// Allow to bind to an object
  /// The object must be a stream<T> or a valueListenable<T>
  /// Or the object must implement a stream parameter that contains a Stream<T>
  /// Will provide a VoidCallback to close the sub and clean
  /// Stream subscriptions are automatically closed when the stream is done
  VoidCallback bind<S extends Object>(S other) {
    if (other is Stream<T>) {
      return bindStream(other);
    }

    if (other is Rx<T>) {
      return bindStream(other.subject.stream);
    }
    if (other is ValueListenable<T>) {
      return bindListenable(other);
    } else {
      try {
        final stream = (other as dynamic).stream;
        if (stream is Stream<T>) {
          return bindStream(stream);
        } else {
          try {
            return bindStream(stream);
          } catch (_) {
            throw '${stream.runtimeType} from $S method [stream] is not a Stream<$T>';
          }
        }
      } catch (_) {
        throw '$S has not method [stream]';
      }
    }
  }
}

/// Base Rx class that manages all the stream logic for any Type.
abstract class _RxImpl<T> extends RxListenable<T> with RxObjectMixin<T> {
  _RxImpl(T? initial, {bool distinct = true})
      : super(initial, distinct: distinct);

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }
}

mixin RxObjectMixin<T> on RxListenable<T> {
  @override
  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  String get string => value.toString();

  @override
  String toString() => value.toString();

  /// Returns the json representation of `value`.
  dynamic toJson() => value;

  /// This equality override works for _RxImpl instances and the internal
  /// values.
  @override
  bool operator ==(Object o) {
    // Todo, find a common implementation for the hashCode of different Types.
    if (o is T) return value == o;
    if (o is RxObjectMixin<T>) return value == o.value;
    return false;
  }

  @override
  int get hashCode => value.hashCode;

  /// Updates the [value] and adds it to the stream, updating the observer
  /// Widget. Indistinct will always update whereas distinct (default) will only
  /// update when new value differs from the previous
  @override
  set value(T val) {
    if (isDisposed) return;
    super.value = val;
  }
}
