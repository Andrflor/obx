import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../notifier.dart';

class Rx<T> extends _RxImpl<T> {
  Rx._({T? initial, bool distinct = true, bool oneShot = false})
      : super(initial, distinct: distinct);

  Rx([T? initial]) : super(initial, distinct: true);
  Rx.indistinct([T? initial]) : super(initial, distinct: false);

  /// This allow to observe the changes
  /// So you can only do when to observable are differents
  /// Maybe remove that ?? Is there a point to observe this??
  @override
  bool operator ==(Object o) {
    // TODO: find a common implementation for the hashCode of different Types.
    return observe((e) =>
        o is T ? e == o : (o is RxObjectMixin<T> ? e == o.value : false));
  }

  @override
  int get hashCode => value.hashCode;

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }

  Rx<S> _clone<S>({bool? distinct, S? Function(T e)? convert}) => Rx._(
      // TODO assert if null is S or not in that
      initial: hasValue ? (convert?.call(static) ?? static as S) : null,
      distinct: distinct ?? isDistinct);
  Rx<T> _dupe({bool? distinct}) =>
      _clone(distinct: distinct)..bindStream(subject.stream);

  /// Allow to observe any variable
  /// This is entended way to do if you want refined controll
  /// Use it inside an obx with a complex object
  /// This will allow only this particular value to update
  S observe<S>(S Function(T val) toElement) => Notifier.inBuild
      ? OneShot.fromMap<T, S>(this, toElement).value
      : toElement(static);

  /// Generates an obserable based on stream transformation of the observable
  /// You need to provide the stream transformation
  /// You can also provide an initial transformation (default to initial value)
  /// Be aware that if your stream transform change the internal type
  /// And you don't provide an initial transformation
  /// The value of the observable will default to null or empty
  /// If you want an initial value in such cases you must provide the initital transformation
  /// Be aware, you must call detatch or dispose otherwise streams won't close
  Rx<S> pipe<S>(Stream<S> Function(Stream<T> e) transformer,
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

  /// Create a standalone copy of the observale
  /// Distinct parameter is used to enforce distinct or indistinct
  Rx<T> clone({bool? distinct}) => _clone(distinct: distinct);

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
