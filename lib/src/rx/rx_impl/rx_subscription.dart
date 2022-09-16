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
  Reactive<E>? _parent;

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

class RxStream<T> extends Stream<T> {
  final Reactive<T> _parent;
  RxStream(this._parent);

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _parent.listen(onData, onError: onError, onDone: onDone);
}
