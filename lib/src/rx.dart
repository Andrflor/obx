import 'notifier.dart';

class Rx<T> extends _RxImpl<T> {
  Rx(T initial, {bool distinct = true}) : super(initial, distinct: distinct);

  static Rx<T?> fromStream<T>(Stream<T> stream, {T? init}) => (init == null
      ? (null is T ? Rx<T>(null as T) : Rx<T?>(null))
      : Rx<T>(init)) as Rx<T>
    ..bind(stream);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

extension RxT<T> on T {
  /// Observable of the specified type
  Rx<T> get obs => Rx<T>(this);

  /// Observable of the nullbale type
  Rx<T?> get nobs => Rx<T?>(this);

  /// Indistinct observable of the specified type
  Rx<T> get iobs => Rx<T>(this, distinct: false);

  /// Indistinct observable of the nullable type
  Rx<T?> get inobs => Rx<T?>(this, distinct: false);
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

/// This class is the foundation for all reactive (Rx) classes that makes Get
/// so powerful.
/// This interface is the contract that [_RxImpl]<T> uses in all it's
/// subclass.

class RxListenable<T> extends ListNotifierSingle {
  RxListenable(T val, {bool distinct = true})
      : _distinct = distinct,
        _value = val;

  final bool _distinct;

  bool _triggered = false;

  bool get isDistinct => _distinct;

  StreamController<T>? _controller;

  void _initController() {
    final initVal = _value;
    bool firstCall = true;
    _controller =
        StreamController<T>.broadcast(onCancel: addListener(_streamListener));
    _stream = isDistinct
        ? _controller!.stream.distinct((i, e) {
            if (_triggered) {
              _triggered = false;
              return false;
            }
            return i == e;
          }).skipWhile((e) {
            if (firstCall) {
              firstCall = false;
              return e == initVal;
            }
            return false;
          })
        : _controller!.stream;
  }

  StreamController<T> get subject {
    if (_controller == null) {
      _initController();
    }
    return _controller!;
  }

  void _streamListener() {
    _controller?.add(_value);
  }

  Stream<T>? _stream;

  Stream<T> get stream {
    if (_controller == null) {
      _initController();
    }
    return _stream!;
  }

  /// Performs a trigger update
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    if (!isDistinct || v != _value) {
      value = v;
      return;
    }
    _triggered = true;
    _controller?.add(v);
    _value = v;
    _notify();
  }

  /// Performs a silent update
  /// Update value and listeners without updating widgets
  /// Piped observable will be notified
  void silent(T v) {
    _controller?.add(v);
    _value = v;
  }

  /// Same as silent but the listeners are not notified
  /// This means that piped object won't recieve the update
  void invisible(T v) {
    _value = v;
  }

  T _value;

  @override
  T get value {
    reportRead();
    return _value;
  }

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  void refresh([T? value]) {
    if (value != null) {
      if (_distinct && _value == value) {
        _controller?.add(value);
      } else {
        _value = value;
      }
    }
    _notify();
  }

  set value(T newValue) {
    if (_distinct && _value == newValue) {
      _controller?.add(newValue);
      return;
    }
    _value = newValue;
    _notify();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Allow to listen to the observable according to distinct
  @override
  StreamSubscription<T> listen(
    void Function(T e)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  /// Same as listen but is also called now
  StreamSubscription<T> listenNow(
    void Function(T e)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onData?.call(_value);
    return listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  @override
  String toString() => value.toString();
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

extension RxOperators<T> on Rx<T> {
  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert}) =>
      Rx(convert?.call(_value) ?? _value as S,
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

  /// This is used to get a non moving value
  T get static => clone()();

  /// Allow to bind to an object
  void bind<S extends Object>(S other) {
    if (other is Stream<T>) {
      return bindStream(other);
    }
    if (other is Rx<T>) {
      return bindStream(other.subject.stream);
    } else {
      try {
        final stream = (other as dynamic).stream;
        if (stream is Stream<T>) {
          bindStream(stream);
        } else {
          throw '${stream.runtimeType} from $S method [stream] is not a Stream<$T>';
        }
      } catch (_) {
        throw '$S has not method [stream]';
      }
    }
  }
}

extension StreamOperators<T> on Stream<T> {}
