part of '../../orchestrator.dart';

// This typedef allow to have simple def for user
typedef RxSubscription<T> = _NodeSub<T, Function(T value)>;
typedef ErrorCallBack = void Function(Object error, [StackTrace? trace]);

enum StreamFunctionType {
  convert,
  test,
  autoRemoveTest,
  autoCloseTest,
  distinct
}

class StreamFunctionWrapper<T extends Function> {
  T func;
  StreamFunctionType type;

  StreamFunctionWrapper(this.func, this.type);
}

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
  void _syncCancel() {
    if (identical(_parent, null)) return;
    // TODO: notify parent onCancel if needed
    _parent!._unlink(this);
    _parent = null;
    _paused = false;
  }
}

class RxStream<T> extends _Stream<T> {
  @override
  T? get _data => _parent._data;
  final Reactive<T> _parent;

  @override
  bool get isBroadcast => true;

  RxStream(this._parent);

  @override
  StreamSubscription<T> _listen(_NodeSub<T, Function(T value)> node) =>
      _parent._listen(node);

  @override
  RxSubscription<T> listen(Function(T value)? onData,
          {Function? onError, VoidCallback? onDone, bool? cancelOnError}) =>
      _parent.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class _ReactiveStream<T> extends _Stream<T> {
  Function()? _disposer;

  _ReactiveStream._(_Stream<T> parent) {
    _disposer =
        parent.listen(_add, onError: _addError, onDone: _close)._syncCancel;
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

  // Allow to listen and gives you a subscription in return
  // Like [StreamSubscription] except that cancel is synchronous
  @override
  RxSubscription<T> _listen(_NodeSub<T, Function(T value)> node) {
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

abstract class _Stream<T> extends Stream<T> {
  T? _data;
  @override
  RxSubscription<T> listen(Function(T value)? onData,
      {Function? onError, VoidCallback? onDone, bool? cancelOnError});

  StreamSubscription<T> _listen(_NodeSub<T, Function(T value)> node);

  @override
  // TODO: Figure out the point of onListen and onCancel
  Stream<T> asBroadcastStream(
          {void Function(StreamSubscription<T> subscription)? onListen,
          void Function(StreamSubscription<T> subscription)? onCancel}) =>
      this;

  Stream<T> asAsync(
          {void Function(StreamSubscription<T> subscription)? onListen,
          void Function(StreamSubscription<T> subscription)? onCancel}) =>
      super.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  // @override
  // Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) {
  //   // TODO: implement asyncExpand
  //   throw UnimplementedError();
  // }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      convert is Future<E> Function(T event)
          ? _AsyncMapStream(this, convert)
          : _MapStream(this, convert as E Function(T event));

  @override
  Stream<R> cast<R>() => _MapStream(this, (e) => e as R);

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) =>
      _DistinctStream(this, equals);

  // TODO: specify that event are delayed
  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert,
			// add ExpandStream
      [Duration delay = const Duration(milliseconds: 30)])

  @override
  _ReactiveStream<S> map<S>(S Function(T event) convert) =>
      _MapStream(this, convert);

  @override
  Stream<T> skipWhile(bool Function(T element) test) =>
      _SkipWhileStream(this, test);

  @override
  Stream<T> skip(int count) {
    int passed = 0;
    return skipWhile((_) {
      if (++passed > count) {
        return false;
      }
      return true;
    });
  }

  @override
  _ReactiveStream<T> takeWhile(bool Function(T element) test) =>
      _TakeWhileStream(this, test);

  @override
  Stream<T> take(int count) {
    int passed = 0;
    return takeWhile((_) {
      if (++passed > count) {
        return false;
      }
      return true;
    });
  }

  // @override
  // Stream<T> timeout(Duration timeLimit,
  //     {void Function(EventSink<T> sink)? onTimeout}) {
  //   // TODO: implement timeout
  //   throw UnimplementedError();
  // }

  @override
  Stream<T> where(bool Function(T event) test) => _WhereStream(this, test);
}

class _MapStream<S, T> extends _ReactiveStream<T> {
  _MapStream(_Stream<S> parent, T Function(S event) convert) {
    if (parent._data is S) {
      _data = convert(parent._data as S);
    }
    _disposer = parent
        .listen((S val) => _add(convert(val)),
            onError: _addError, onDone: _close)
        ._syncCancel;
  }
}

class _AsyncMapStream<S, T> extends _ReactiveStream<T> {
  _AsyncMapStream(_Stream<S> parent, Future<T> Function(S event) convert) {
    if (parent._data is S) {
      convert(parent._data as S).then((val) => _data = val).then((_) =>
          _disposer = parent
              .listen((S val) => convert(val).then(_add),
                  onError: _addError, onDone: _close)
              ._syncCancel);
    } else {
      _disposer = parent
          .listen((S val) => convert(val).then(_add),
              onError: _addError, onDone: _close)
          ._syncCancel;
    }
  }
}

class _WhereStream<T> extends _ReactiveStream<T> {
  _WhereStream(_Stream<T> parent, bool Function(T event) test) {
    if (parent._data is T && test(parent._data as T)) {
      _data = parent._data;
    }
    _disposer = parent.listen((T val) {
      if (test(val)) {
        _add(val);
      }
    }, onError: _addError, onDone: _close)._syncCancel;
  }
}

class _TakeWhileStream<T> extends _ReactiveStream<T> {
  _TakeWhileStream(_Stream<T> parent, bool Function(T event) test) {
    if (parent._data is T && test(parent._data as T)) {
      _data = parent._data;
    }
    _disposer = parent.listen((T val) {
      if (test(val)) {
        _add(val);
      } else {
        _close();
      }
    }, onError: _addError, onDone: _close)._syncCancel;
  }
}

class _SkipWhileStream<T> extends _ReactiveStream<T> {
  _SkipWhileStream(_Stream<T> parent, bool Function(T event) test) {
    if (parent._data is T && !test(parent._data as T)) {
      _data = parent._data;
    }
    late final RxSubscription<T> sub;
    _disposer = (sub = parent.listen((T val) {
      if (test(val)) {
      } else {
        _add(val);
        sub.onData(_add);
      }
    }, onError: _addError, onDone: _close))
        ._syncCancel;
  }
}

class _DistinctStream<T> extends _ReactiveStream<T> {
  _DistinctStream(
      _Stream<T> parent, bool Function(T previous, T next)? equals) {
    _data = parent._data;
    final eq = equals ?? _eq;
    _disposer = parent.listen((T val) {
      if (_data is T) {
        if (!eq(_data as T, val)) {
          _add(val);
        }
      } else {
        _add(val);
      }
    }, onError: _addError, onDone: _close)._syncCancel;
  }

  bool _eq(T previous, T next) => previous == next;
}
