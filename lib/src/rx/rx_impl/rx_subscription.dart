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
  void _syncCancel() {
    if (identical(_parent, null)) return;
    // TODO: notify parent onCancel if needed
    _parent!._unlink(this);
    _parent = null;
    _paused = false;
  }
}

class RxStream<T> extends _Stream<T> {
  final Reactive<T> _parent;
  RxStream(this._parent);

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _parent.listen(onData, onError: onError, onDone: onDone);

  @override
  StreamSubscription<T> _listen(_NodeSub<T, Function(T value)> node) =>
      _parent._listen(node);
}

abstract class _Stream<T> implements Stream<T> {
  @override
  Stream<T> asBroadcastStream(
      {void Function(StreamSubscription<T> subscription)? onListen,
      void Function(StreamSubscription<T> subscription)? onCancel}) {
    // TODO: implement asBroadcastStream
    throw UnimplementedError();
  }

  StreamSubscription<T> _listen(_NodeSub<T, Function(T value)> node);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(T event) convert) {
    // TODO: implement asyncExpand
    throw UnimplementedError();
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) {
    // TODO: implement asyncMap
    throw UnimplementedError();
  }

  @override
  Stream<R> cast<R>() {
    // TODO: implement cast
    throw UnimplementedError();
  }

  @override
  Future<bool> any(bool Function(T element) test) {
    // TODO: implement any
    throw UnimplementedError();
  }

  @override
  Future<bool> contains(Object? needle) {
    // TODO: implement contains
    throw UnimplementedError();
  }

  @override
  Stream<T> distinct([bool Function(T previous, T next)? equals]) {
    // TODO: implement distinct
    throw UnimplementedError();
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    // TODO: implement drain
    throw UnimplementedError();
  }

  @override
  Future<T> elementAt(int index) {
    // TODO: implement elementAt
    throw UnimplementedError();
  }

  @override
  Future<bool> every(bool Function(T element) test) {
    // TODO: implement every
    throw UnimplementedError();
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(T element) convert) {
    // TODO: implement expand
    throw UnimplementedError();
  }

  @override
  // TODO: implement first
  Future<T> get first => throw UnimplementedError();

  @override
  Future<T> firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement firstWhere
    throw UnimplementedError();
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, T element) combine) {
    // TODO: implement fold
    throw UnimplementedError();
  }

  @override
  Future forEach(void Function(T element) action) {
    // TODO: implement forEach
    throw UnimplementedError();
  }

  @override
  Stream<T> handleError(Function onError,
      {bool Function(dynamic error)? test}) {
    // TODO: implement handleError
    throw UnimplementedError();
  }

  @override
  // TODO: implement isBroadcast
  bool get isBroadcast => throw UnimplementedError();

  @override
  // TODO: implement isEmpty
  Future<bool> get isEmpty => throw UnimplementedError();

  @override
  Future<String> join([String separator = ""]) {
    // TODO: implement join
    throw UnimplementedError();
  }

  @override
  // TODO: implement last
  Future<T> get last => throw UnimplementedError();

  @override
  Future<T> lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement lastWhere
    throw UnimplementedError();
  }

  @override
  // TODO: implement length
  Future<int> get length => throw UnimplementedError();

  @override
  Stream<S> map<S>(S Function(T event) convert) {
    // TODO: implement map
    throw UnimplementedError();
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    // TODO: implement pipe
    throw UnimplementedError();
  }

  @override
  Future<T> reduce(T Function(T previous, T element) combine) {
    // TODO: implement reduce
    throw UnimplementedError();
  }

  @override
  // TODO: implement single
  Future<T> get single => throw UnimplementedError();

  @override
  Future<T> singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement singleWhere
    throw UnimplementedError();
  }

  @override
  Stream<T> skip(int count) {
    // TODO: implement skip
    throw UnimplementedError();
  }

  @override
  Stream<T> skipWhile(bool Function(T element) test) {
    // TODO: implement skipWhile
    throw UnimplementedError();
  }

  @override
  Stream<T> take(int count) {
    // TODO: implement take
    throw UnimplementedError();
  }

  @override
  Stream<T> takeWhile(bool Function(T element) test) {
    // TODO: implement takeWhile
    throw UnimplementedError();
  }

  @override
  Stream<T> timeout(Duration timeLimit,
      {void Function(EventSink<T> sink)? onTimeout}) {
    // TODO: implement timeout
    throw UnimplementedError();
  }

  @override
  Future<List<T>> toList() {
    // TODO: implement toList
    throw UnimplementedError();
  }

  @override
  Future<Set<T>> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    // TODO: implement transform
    throw UnimplementedError();
  }

  @override
  Stream<T> where(bool Function(T event) test) {
    print(test.runtimeType);
    return _WhereReactiveStream<T>(this, test);
  }
}

class _ReactiveStream<T> extends _Stream<T> {
  T? _data;
  Object? _error;

  _NodeSub<T, Function(T value)>? _firstSubscrption;
  _NodeSub<T, Function(T value)>? _lastSubscription;

  // Allow to listen and gives you a subscription in return
  // Like [StreamSubscription] except that cancel is synchronous
  @override
  StreamSubscription<T> listen(Function(T value)? onData,
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
  StreamSubscription<T> _listen(_NodeSub<T, Function(T value)> node) {
    if (identical(_firstSubscrption, null)) {
      _lastSubscription = node;
      return _firstSubscrption = node;
    }
    node._previous = _lastSubscription;
    return _lastSubscription = _lastSubscription!._next = node;
  }

  /// Emit the last data value
  void _emit() {
    if (identical(_firstSubscrption, null)) return;
    var currentSubscription = _firstSubscrption?.._handleData?.call(_data as T);
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
      _continueEmitting(currentSubscription!._next);
    }
  }

  /// Allow to add an error with an optional [StackTrace]
  void _addError(Object error, [StackTrace? trace]) {
    _error = error;
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription = _firstSubscrption;
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
      _continueAddingError(error, trace, currentSubscription!._next);
    }
  }

  /// Close the [Rx<T>] with proper cleanup
  ///
  /// You don't need to call this unless you don't have closed all subscriptions
  void _close() {
    // No need to close if we have no _firstSubscrption
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription = _firstSubscrption;
    _firstSubscrption = _lastSubscription = null;
    try {
      while (!identical(
          currentSubscription = currentSubscription!._close(), null)) {}
    } catch (exception, trace) {
      _reportError("close", exception, trace);
      // StackOverflowError is impossible here
      // recursive function to avoid try catching on every loop
      _continueClosing(currentSubscription!._next);
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
      _continueEmitting(currentSubscription!._next);
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
      _continueAddingError(error, trace, currentSubscription!._next);
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
      _continueClosing(currentSubscription!._next);
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

class _WhereReactiveStream<T> extends _ReactiveStream<T> {
  _WhereReactiveStream(_Stream<T> source, bool Function(T value) test) {
    source._listen(_WhereSub<T, Function(T)>(this, test));
  }
}

class _WhereSub<E, T extends Function(E value)> extends _NodeSub<E, T> {
  final bool Function(E value) _test;
  _WhereSub(super.parent, this._test);

  @override
  T? get _handleData => throw UnimplementedError();

  @override
  // TODO: implement _handleDone
  VoidCallback? get _handleDone => throw UnimplementedError();

  @override
  // TODO: implement _handleError
  Function? get _handleError => throw UnimplementedError();
}

class _FeedSub<E, T extends Function(E value)> extends _NodeSub<E, T> {
  _FeedSub(super.parent);

  @override
  T? __handleData = ;

  @override
  VoidCallback? __handleDone;

  @override
  Function? __handleError = parent.e;
}
