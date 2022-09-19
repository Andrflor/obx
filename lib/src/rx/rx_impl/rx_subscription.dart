part of '../../orchestrator.dart';

// This typedef allow to have simple def for user
typedef RxSubscription<T> = _NodeSub<T, Function(T value)>;
typedef ErrorCallBack = void Function(Object error, [StackTrace? trace]);

// For some reason that explicit Function(E value) makes it way faster
class _NodeSub<E, T extends Function(E value)>
    implements StreamSubscription<E> {
  T? get _handleData => _paused ? null : __handleData;
  T? __handleData;

  Function? get _handleError => _paused ? null : __handleError;
  Function? __handleError;

  VoidCallback? get _handleDone => _paused ? null : __handleDone;
  VoidCallback? __handleDone;

  // We explicitly use dynamic here because it gives faster unlink
  dynamic _previous;
  _NodeSub<E, T>? _next;
  // We explicitly use dynamic here because otherwise we would need mixins
  // And mixins are slow for some reason...
  dynamic _parent;

  bool _paused = false;

  _NodeSub(this._parent,
      [this.__handleData, this.__handleError, this.__handleDone]);

  @override
  Future<S> asFuture<S>([S? futureValue]) {
    final completer = Completer<S>();
    onDone(() => completer.complete(futureValue as S));
    onError((Object error, [StackTrace? trace]) {
      completer.completeError(error, trace);
      cancel();
    });
    return completer.future;
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(void Function(E data)? handleData) {
    __handleData = handleData as T;
  }

  @override
  void onDone(VoidCallback? handleDone) {
    __handleDone = handleDone;
  }

  @override
  void onError(Function? handleError) {
    __handleError = handleError;
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    if (identical(_parent, null)) return;
    _paused = true;
    resumeSignal?.then((_) => _paused = false);
  }

  @override
  void resume() {
    if (identical(_parent, null)) return;
    _paused = false;
  }

  _NodeSub<E, T>? _close() {
    _previous = _parent = null;
    _paused = false;
    _handleDone?.call();
    return _next;
  }

  @override
  Future<void> cancel() async {
    if (identical(_parent, null)) return;
    // TODO: notify parent onCancel if needed
    _parent!._unlink(this);
    _parent = null;
    _paused = false;
  }

  // Faster cancel due to sync nature
  void syncCancel() {
    if (identical(_parent, null)) return;
    // TODO: notify parent onCancel if needed
    _parent!._unlink(this);
    _parent = null;
    _paused = false;
  }
}

extension SyncStream<T> on Stream<T> {
  RxStream<T> sync() => _ReactiveStream._(this);
}

extension SyncCancel<T> on StreamSubscription<T> {
  void syncCancel() => cancel();
}

class _RxStream<T> extends RxStream<T> {
  @override
  T? get _data => _parent._data;
  final Reactive<T> _parent;

  @override
  bool get isBroadcast => true;

  _RxStream(this._parent);

  @override
  RxSubscription<T> listen(Function(T value)? onData,
          {Function? onError, VoidCallback? onDone, bool? cancelOnError}) =>
      _parent.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class _ReactiveStream<T> extends RxStream<T> {
  Function()? _disposer;

  _ReactiveStream._(Stream<T> parent) {
    _disposer =
        parent.listen(_add, onError: _addError, onDone: _close).syncCancel;
  }

  _ReactiveStream();

  _NodeSub<T, Function(T value)>? _firstSubscrption;
  _NodeSub<T, Function(T value)>? _lastSubscription;

  // Allow to listen and gives you a subscription in return
  // Like [StreamSubscription] except that cancel is synchronous
  @override
  RxSubscription<T> listen(Function(T value)? onData,
      {Function? onError, VoidCallback? onDone, bool? cancelOnError}) {
    final node = _NodeSub<T, Function(T value)>(this, onData, onError, onDone);
    if (identical(_firstSubscrption, null)) {
      _lastSubscription = node;
      return _firstSubscrption = node;
    }
    node._previous = _lastSubscription;
    return _lastSubscription = _lastSubscription!._next = node;
  }

  /// Emit the last data value
  void _emit() {
    _NodeSub<T, Function(T value)>? currentSubscription;
    try {
      currentSubscription = _firstSubscrption?.._handleData?.call(_data as T);

      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleData?.call(_data as T);
      }
    } catch (exception, trace) {
      _reportError("emit", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueEmitting(currentSubscription?._next);
    }
  }

  void _add(T event) {
    _data = event;
    if (identical(_firstSubscrption, null)) return;
    _emit();
  }

  /// Allow to add an error with an optional [StackTrace]
  void _addError(Object error, [StackTrace? trace]) {
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription;
    try {
      currentSubscription = _firstSubscrption
        ?.._handleError?.call(error, trace);
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleError?.call(error, trace);
      }
    } catch (exception, trace) {
      _reportError("addError", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueAddingError(error, trace, currentSubscription?._next);
    }
  }

  /// Close the [Rx<T>] with proper cleanup
  ///
  /// You don't need to call this unless you don't have closed all subscriptions
  void _close() {
    // No need to close if we have no _firstSubscrption
    if (identical(_firstSubscrption, null)) return;
    _disposer?.call();
    _NodeSub<T, Function(T e)>? currentSubscription = _firstSubscrption;
    _firstSubscrption = _lastSubscription = null;
    try {
      while (!identical(
          currentSubscription = currentSubscription!._close(), null)) {}
    } catch (exception, trace) {
      _reportError("close", exception, trace);
      // StackOverflowError is impossible here
      // recursive function to avoid try catching on every loop
      _continueClosing(currentSubscription?._next);
    }
  }

  void _continueEmitting(_NodeSub<T, Function(T e)>? currentSubscription) {
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleData?.call(_data as T);
      }
    } catch (exception, trace) {
      _reportError("emit", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueEmitting(currentSubscription?._next);
    }
  }

  void _continueAddingError(Object error, StackTrace? trace,
      _NodeSub<T, Function(T e)>? currentSubscription) {
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleError?.call(error, trace);
      }
    } catch (exception, trace) {
      _reportError("addError", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueAddingError(error, trace, currentSubscription?._next);
    }
  }

  void _continueClosing(_NodeSub<T, Function(T e)>? currentSubscription) {
    try {
      while (!identical(
          currentSubscription = currentSubscription!._close(), null)) {}
    } catch (exception, trace) {
      _reportError("close", exception, trace);
      // StackOverflowError is impossible here
      // recursive function to avoid try catching on every loop
      _continueClosing(currentSubscription?._next);
    }
  }

  void _unlink(node) {
    if (identical(_firstSubscrption, node)) {
      if (identical(_lastSubscription, node)) {
        // First = Last = Node
        _firstSubscrption = _lastSubscription = null;
        return;
      }
      // First = Node
      _firstSubscrption = node._next;
      _firstSubscrption!._previous = null;
      return;
    }
    if (identical(_lastSubscription, node)) {
      // Last = Node
      _lastSubscription = node._previous;
      _lastSubscription!._next = null;
      return;
    }
    // Node = Random
    node._next!._previous = node._previous;
    node._previous!._next = node._next;
  }

  void _reportError(String kind, Object exception, [StackTrace? trace]) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: exception,
      stack: trace,
      library: 'obx library',
      silent: true,
      context: ErrorSummary(
          'dispatching $kind for $runtimeType\nThis error was catched to ensure that listener events are dispatched\nSome of your listeners for this Rx is throwing an exception\nMake sure that your listeners do not throw to ensure optimal performance'),
    ));
  }
}

abstract class RxStream<T> extends Stream<T> {
  T? _data;
  @override
  RxSubscription<T> listen(Function(T value)? onData,
      {Function? onError, VoidCallback? onDone, bool? cancelOnError});

  StreamController<T>? _asyncStreamController;

  /// Gives you a normal async stream
  Stream<T> async() {
    if (_asyncStreamController != null) {
      return _asyncStreamController!.stream;
    }

    _asyncStreamController = StreamController<T>.broadcast();
    listen(
      _asyncStreamController!.add,
      onError: _asyncStreamController!.addError,
      onDone: () {
        _asyncStreamController!.close();
        _asyncStreamController = null;
      },
      cancelOnError: false,
    );
    return _asyncStreamController!.stream;
  }

  @override
  Future<T> get first {
    final completer = Completer<T>.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        completer.complete(val);
        sub.syncCancel();
      },
      onError: completer.completeError,
      onDone: () {
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          completer.completeError(e, s);
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) =>
      async().asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      convert is Future<E> Function(T event)
          ? async().asyncMap(convert)
          : _MapStream(this, convert as E Function(T event));

  @override
  RxStream<R> cast<R>() => _MapStream(this, (e) => e as R);

  @override
  RxStream<T> distinct([bool Function(T previous, T next)? equals]) =>
      _DistinctStream(this, equals);

  @override
  RxStream<S> expand<S>(
    Iterable<S> Function(T element) convert,
    // add ExpandStream
  ) =>
      _ExpandStream<S, T>(this, convert);

  @override
  RxStream<S> map<S>(S Function(T event) convert) => _MapStream(this, convert);

  @override
  RxStream<T> skipWhile(bool Function(T element) test) =>
      _SkipWhileStream(this, test);

  @override
  RxStream<T> skip(int count) {
    int passed = 0;
    return skipWhile((_) {
      if (++passed > count) {
        return false;
      }
      return true;
    });
  }

  @override
  RxStream<T> takeWhile(bool Function(T element) test) =>
      _TakeWhileStream(this, test);

  @override
  RxStream<T> take(int count) {
    int passed = 0;
    return takeWhile((_) {
      if (++passed > count) {
        return false;
      }
      return true;
    });
  }

  @override
  Future<T> get single {
    final completer = Completer<T>.sync();
    late final RxSubscription<T> sub;
    late T result;
    bool foundResult = false;
    sub = listen(
      (T value) {
        if (foundResult) {
          try {
            throw IterableElementError.tooMany();
          } catch (e, s) {
            completer.completeError(e, s);
          }
          sub.syncCancel();
        } else {
          foundResult = true;
          result = value;
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (foundResult) {
          completer.complete(result);
        } else {
          completer.completeError(IterableElementError.tooFew());
          try {
            throw IterableElementError.noElement();
          } catch (e, s) {
            completer.completeError(e, s);
          }
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  RxStream<T> where(bool Function(T event) test) => _WhereStream(this, test);

  @override
  Future<bool> any(bool Function(T element) test) {
    final completer = Completer<bool>.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        try {
          if (test(val)) {
            completer.complete(true);
            sub.syncCancel();
          }
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(false);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<bool> contains(Object? needle) {
    final completer = Completer<bool>.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        try {
          if (val == needle) {
            completer.complete(true);
            sub.syncCancel();
          }
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(false);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    return listen(null, cancelOnError: true).asFuture<E>(futureValue);
  }

  @override
  Future<T> elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    final completer = Completer<T>.sync();
    late final RxSubscription<T> sub;
    int idx = 0;
    sub = listen(
      (T val) {
        if (index == idx) {
          completer.complete(val);
          sub.syncCancel();
        }
        idx++;
      },
      onError: completer.completeError,
      onDone: () {
        try {
          throw RangeError.index(index, this, "index", null, idx);
        } catch (e, s) {
          completer.completeError(e, s);
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<bool> every(bool Function(T element) test) {
    final completer = Completer<bool>.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        try {
          if (!test(val)) {
            completer.complete(false);
            sub.syncCancel();
          }
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(true);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  @override
  Future<T> reduce(T Function(T previous, T element) combine) {
    final completer = Completer<T>.sync();
    late T value;
    bool seenFirst = false;
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        if (seenFirst) {
          try {
            value = combine(value, val);
            seenFirst = true;
          } catch (e, s) {
            completer.completeError(e, s);
            sub.syncCancel();
          }
        } else {
          value = val;
          seenFirst = true;
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (!seenFirst) {
          try {
            throw IterableElementError.noElement();
          } catch (e, s) {
            completer.completeError(e, s);
          }
        } else {
          completer.complete(value);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, T element) combine) {
    final completer = Completer<S>.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        try {
          initialValue = combine(initialValue, val);
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(initialValue);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    final completer = Completer<T>.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T value) {
        try {
          if (test(value)) {
            completer.complete(value);
            sub.syncCancel();
          }
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (orElse != null) {
          try {
            completer.complete(orElse());
          } catch (e, s) {
            completer.completeError(e, s);
          }
          return;
        }
        try {
          // Sets stackTrace on error.
          throw IterableElementError.noElement();
        } catch (e, s) {
          completer.completeError(e, s);
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    final completer = Completer<T>.sync();
    late T last;
    bool found = false;
    late final RxSubscription<T> sub;
    sub = listen(
      (T value) {
        try {
          if (found) {
            try {
              throw IterableElementError.tooMany();
            } catch (e, s) {
              completer.completeError(e, s);
              sub.syncCancel();
            }
            return;
          }
          if (test(value)) {
            last = value;
            found = true;
          }
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (found) {
          return completer.complete(last);
        }
        if (orElse != null) {
          try {
            completer.complete(orElse());
          } catch (e, s) {
            completer.completeError(e, s);
          }
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          completer.completeError(e, s);
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    final completer = Completer<T>.sync();
    late T last;
    bool found = false;
    late final RxSubscription<T> sub;
    sub = listen(
      (T value) {
        try {
          if (test(value)) {
            last = value;
            found = true;
          }
        } catch (e, s) {
          completer.completeError(e, s);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        if (found) {
          return completer.complete(last);
        }
        if (orElse != null) {
          try {
            completer.complete(orElse());
          } catch (e, s) {
            completer.completeError(e, s);
          }
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          completer.completeError(e, s);
        }
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future forEach(void Function(T element) action) {
    final completer = Completer.sync();
    late final RxSubscription<T> sub;
    sub = listen(
      (T val) {
        try {
          action(val);
        } catch (e) {
          completer.completeError(e);
          sub.syncCancel();
        }
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(null);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// As no effect since it is already a broadcast stream
  // TODO: make a proper implementation of this
  @override
  RxStream<T> asBroadcastStream(
      {void Function(StreamSubscription<T> subscription)? onListen,
      void Function(StreamSubscription<T> subscription)? onCancel}) {
    throw UnimplementedError();
  }

  // TODO: make a proper implementation of this
  @override
  RxStream<T> timeout(Duration timeLimit,
      {void Function(EventSink<T> sink)? onTimeout}) {
    // TODO: implement timeout
    throw UnimplementedError();
  }

  @override
  RxStream<T> handleError(Function onError,
          {bool Function(dynamic error)? test}) =>
      _ErrorStream(this, test);

  @override
  bool get isBroadcast => true;

  @override
  Future<bool> get isEmpty {
    final completer = Completer<bool>.sync();

    late final RxSubscription<T> sub;
    sub = listen(
      (_) {
        completer.complete(false);
        sub.syncCancel();
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(true);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<String> join([String separator = ""]) {
    final completer = Completer<String>();
    final buffer = StringBuffer();
    bool first = true;
    listen(
      separator.isEmpty
          ? (T element) {
              try {
                buffer.write(element);
              } catch (e, s) {
                completer.completeError(e, s);
              }
            }
          : (T element) {
              if (!first) {
                buffer.write(separator);
              }
              first = false;
              try {
                buffer.write(element);
              } catch (e, s) {
                completer.completeError(e, s);
              }
            },
      onError: completer.completeError,
      onDone: () {
        completer.complete(buffer.toString());
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<T> get last {
    final completer = Completer<T>.sync();
    listen(
      null,
      onError: completer.completeError,
      onDone: () {
        completer.complete(_data);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<int> get length {
    final completer = Completer<int>.sync();
    int count = 0;
    listen(
      (T val) {
        count++;
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(count);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<List<T>> toList() {
    List<T> result = [];
    final completer = Completer<List<T>>();
    listen(
      (T data) {
        result.add(data);
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(result);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future<Set<T>> toSet() {
    Set<T> result = {};
    final completer = Completer<Set<T>>();
    listen(
      (T data) {
        result.add(data);
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(result);
      },
      cancelOnError: true,
    );
    return completer.future;
  }
}

class _MapStream<S, T> extends _ReactiveStream<T> {
  _MapStream(RxStream<S> parent, T Function(S event) convert) {
    if (parent._data is S) {
      try {
        _data = convert(parent._data as S);
      } catch (e, stack) {
        _addError(e, stack);
      }
    }
    _disposer = parent.listen((S val) {
      try {
        _add(convert(val));
      } catch (e, stack) {
        _addError(e, stack);
      }
    }, onError: _addError, onDone: _close).syncCancel;
  }
}

class _WhereStream<T> extends _ReactiveStream<T> {
  _WhereStream(RxStream<T> parent, bool Function(T event) test) {
    try {
      if (parent._data is T && test(parent._data as T)) {
        _data = parent._data;
      }
    } catch (_) {}
    _disposer = parent.listen((T val) {
      try {
        if (test(val)) {
          _add(val);
        }
      } catch (e, stack) {
        _addError(e, stack);
      }
    }, onError: _addError, onDone: _close, cancelOnError: false).syncCancel;
  }
}

class _TakeWhileStream<T> extends _ReactiveStream<T> {
  _TakeWhileStream(RxStream<T> parent, bool Function(T event) test) {
    try {
      if (parent._data is T && test(parent._data as T)) {
        _data = parent._data;
      }
    } catch (_) {}
    _disposer = parent.listen((T val) {
      try {
        if (test(val)) {
          _add(val);
        } else {
          _close();
        }
      } catch (e, s) {
        _addError(e, s);
      }
    }, onError: _addError, onDone: _close, cancelOnError: false).syncCancel;
  }
}

class _SkipWhileStream<T> extends _ReactiveStream<T> {
  _SkipWhileStream(RxStream<T> parent, bool Function(T event) test) {
    try {
      if (parent._data is T && !test(parent._data as T)) {
        _data = parent._data;
      }
    } catch (_) {}
    late final RxSubscription<T> sub;
    _disposer = (sub = parent.listen((T val) {
      try {
        if (test(val)) {
        } else {
          _add(val);
          sub.onData(_add);
        }
      } catch (e, s) {
        _addError(e, s);
      }
    }, onError: _addError, onDone: _close, cancelOnError: false))
        .syncCancel;
  }
}

class _DistinctStream<T> extends _ReactiveStream<T> {
  _DistinctStream(
      RxStream<T> parent, bool Function(T previous, T next)? equals) {
    _data = parent._data;
    final eq = equals ?? _eq;
    _disposer = parent.listen((T val) {
      if (_data is T) {
        try {
          if (!eq(_data as T, val)) {
            _add(val);
          }
        } catch (e, s) {
          _addError(e, s);
        }
      } else {
        _add(val);
      }
    }, onError: _addError, onDone: _close, cancelOnError: false).syncCancel;
  }

  bool _eq(T previous, T next) => previous == next;
}

class _ExpandStream<T, S> extends _ReactiveStream<T> {
  _ExpandStream(RxStream<S> parent, Iterable<T> Function(S element) convert) {
    if (parent._data is S) {
      try {
        for (var e in convert(parent._data as S)) {
          _data = e;
        }
      } catch (_) {}
    }
    _disposer = parent
        .listen((S val) => convert(val).forEach(_add),
            onError: _addError, onDone: _close, cancelOnError: false)
        .syncCancel;
  }
}

class _ErrorStream<T> extends _ReactiveStream<T> {
  _ErrorStream(RxStream<T> parent, bool Function(Object error)? test) {
    _disposer = parent
        .listen(null,
            onError: (test == null)
                ? _addError
                : (Object error, [StackTrace? trace]) {
                    if (test(error)) {
                      _addError(error, trace);
                    }
                  },
            onDone: _close,
            cancelOnError: false)
        .syncCancel;
  }
}

abstract class IterableElementError {
  static StateError noElement() => StateError("No element");
  static StateError tooMany() => StateError("Too many elements");
  static StateError tooFew() => StateError("Too few elements");
}
