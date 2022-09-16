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
}

/// Override of StreamSubscription to make cancel Futureor<void>
abstract class Subscription<T> {
  /// Cancels this subscription.
  ///
  /// After this call, the subscription no longer receives events.
  ///
  /// The [Rx] may need to shut down the source of events and clean up after
  /// the subscription is canceled.
  ///
  /// Returns a future that is completed once the stream has finished
  /// its cleanup or returns void when synchronous.
  FutureOr<void> cancel();

  /// Replaces the data event handler of this subscription.
  ///
  /// The [handleData] function is called for each data event of the [Rx]
  /// after this function is called.
  /// If [handleData] is `null`, data events are ignored.
  ///
  /// This method replaces the current handler set by the invocation of
  /// [Rx.listen] or by a previous call to [onData].
  void onData(void Function(T data)? handleData);

  /// Replaces the error event handler of this subscription.
  ///
  /// The [handleError] function must be able to be called with either
  /// one positional argument, or with two positional arguments
  /// where the seconds is always a [StackTrace].
  ///
  /// The [handleError] argument may be `null`, in which case further
  /// error events are considered *unhandled*, and will be reported to
  /// [Zone.handleUncaughtError].
  ///
  /// The provided function is called for all error events from the
  /// subscription.
  ///
  /// This method replaces the current handler set by the invocation of
  /// [Rx.listen], by calling [asFuture], or by a previous call to [onError].
  void onError(Function(Object error, [StackTrace? trace])? handleError);

  /// Replaces the done event handler of this subscription.
  ///
  /// The [handleDone] function is called when the stream closes.
  /// The value may be `null`, in which case no function is called.
  ///
  /// This method replaces the current handler set by the invocation of
  /// [Rx.listen], by calling [asFuture], or by a previous call to [onDone].
  void onDone(void Function()? handleDone);

  /// Requests that the [Rx] do not dispatch events to this subscription until further notice.
  ///
  /// While paused, the subscription will not recieve any events.
  /// Pausing is a very lightweight operation.
  ///
  /// If [resumeSignal] is provided, the subscription will undo the pause
  /// when the future completes, as if by a call to [resume].
  /// If the future completes with an error,
  /// the stream will still resume, but the error will be considered unhandled
  /// and is passed to [Zone.handleUncaughtError].
  ///
  /// A call to [resume] will also undo a pause.
  ///
  /// If the subscription is paused more than once it has no additional effect
  /// Calls to [resume] and the completion of a [resumeSignal] are
  /// interchangeable - the [pause] which was passed a [resumeSignal] may be
  /// ended by a call to [resume], and completing the [resumeSignal] may end a
  /// different [pause].
  ///
  /// It is safe to [resume] or complete a [resumeSignal] even when the
  /// subscription is not paused, and the resume will have no effect.
  void pause([Future<void>? resumeSignal]);

  /// Resumes after a pause.
  ///
  /// This undoes one previous call to [pause].
  /// The subscription will recieve events again.
  ///
  /// It is safe to [resume] even when the subscription is not paused, and the
  /// resume will have no effect.
  void resume();

  /// Whether the [Subscription] is currently paused.
  ///
  /// Returns `false` if the [Rx] can currently emit events, or if
  /// the subscription has completed or been cancelled.
  bool get isPaused;

  /// Returns a future that handles the [onDone] and [onError] callbacks.
  ///
  /// This method *overwrites* the existing [onDone] and [onError] callbacks
  /// with new ones that complete the returned future.
  ///
  /// In case of an error the subscription will automatically cancel (even
  /// when it was listening with `cancelOnError` set to `false`).
  ///
  /// In case of a `done` event the future completes with the given
  /// [futureValue].
  ///
  /// If [futureValue] is omitted, the value `null as E` is used as a default.
  /// If `E` is not nullable, this will throw immediately when [asFuture]
  /// is called.
  Future<E> asFuture<E>([E? futureValue]);
}

class RxStream<T> extends _Stream<T> {
  final Reactive<T> _parent;
  RxStream(this._parent);

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _parent.listen(onData, onError: onError, onDone: onDone);
}

abstract class _Stream<T> implements Stream<T> {
  @override
  Stream<T> asBroadcastStream(
      {void Function(StreamSubscription<T> subscription)? onListen,
      void Function(StreamSubscription<T> subscription)? onCancel}) {
    // TODO: implement asBroadcastStream
    throw UnimplementedError();
  }

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
    // TODO: implement where
    throw UnimplementedError();
  }
}

class _ReactiveStream<T> extends _Stream<T> {
  T? _data;
  Object? _error;

  _NodeSub<T, Function(T value)>? _firstSubscrption;
  _NodeSub<T, Function(T value)>? _lastSubscription;

  // Allow to listen and gives you a subscription in return
  // Like [StreamSubscription] except that cancel is synchronous
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

  /// Emit the last data value
  void emit() {
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
  void addError(Object error, [StackTrace? trace]) {
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
  void close() {
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
