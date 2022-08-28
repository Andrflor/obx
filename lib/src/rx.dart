import 'dart:async';
import 'package:flutter/foundation.dart';

import 'notifier.dart';

class Rx<T> extends _RxImpl<T> {
  Rx(T initial, {bool distinct = true}) : super(initial, distinct: distinct);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }

  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert}) =>
      Rx(convert?.call(static) ?? static as S,
          distinct: distinct ?? isDistinct);
  Rx<T> _dupe({bool? distinct}) =>
      _clone(distinct: distinct)..bindStream(subject.stream);

  /// Generate an obserable based on stream transformation observable
  Rx<S> pipe<S>(Stream<S> Function(Stream<T> e) transformer,
          {S Function(T e)? init, bool? distinct}) =>
      _clone(
        convert: init,
        distinct: distinct,
      )..bindStream(transformer(subject.stream));

  /// Create a standalone copy of the observale
  /// distinct parameter is used to enforce distinct or indistinct
  Rx<T> clone({bool? distinct}) => _clone(distinct: distinct);

  /// Create an exact copy with same stream of the observable
  Rx<T> dupe() => _dupe();

  /// Same as dupe but enforce distinct
  Rx<T> distinct() => _dupe(distinct: true);

  /// Same as dupe but enforce indistinct
  Rx<T> indistinct() => _dupe(distinct: false);

  /// Allow to bind to an object
  void bind<S extends Object>(S other) {
    if (other is Stream<T>) {
      return bindStream(other);
    }

    if (other is Rx<T>) {
      return bindStream(other.subject.stream);
    }
    if (other is ValueListenable<T>) {
      other.addListener(() {
        value = other.value;
      });
    } else {
      try {
        final stream = (other as dynamic).stream;
        if (stream is Stream<T>) {
          bindStream(stream);
        } else {
          try {
            final sub = stream.listen((e) {
              value = e;
            });
            reportAdd(sub.cancel);
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
  _RxImpl(T initial, {bool distinct = true})
      : super(initial, distinct: distinct);

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  /// Uses a callback to update [value] internally, similar to [refresh],
  /// but provides the current value as the argument.
  /// Makes sense for custom Rx types (like Models).

  void update(T Function(T? val) fn) {
    value = fn(value);
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

  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  /// You can bind multiple sources to update the value.
  /// Closing the subscription will happen automatically when the observer
  /// Widget (`ObxValue` or `Obx`) gets unmounted from the Widget tree.
  void bindStream(Stream<T> stream) {
    final sub = stream.listen((e) {
      value = e;
    });
    reportAdd(sub.cancel);
  }
}
