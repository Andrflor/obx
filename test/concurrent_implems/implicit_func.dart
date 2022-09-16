import 'dart:async';

// This typedef allow to have simple def for user
// RxSubscription<T> is StreamSubscription<T>
typedef VoidCallback = void Function();
typedef RxSubscription<T> = _NodeSub<T>;
typedef ErrorCallBack = void Function(Object error, [StackTrace? trace]);

/// Override of StreamSubscription to make cancel Futureor<void>
abstract class _Subscription<T> {
  FutureOr<void> cancel() {}
  void onData(Function(T value)? handleData);
  void onError(ErrorCallBack? handleError);
  void onDone(VoidCallback? handleDone);
  void pause([Future<void>? resumeSignal]);
  void resume();
  bool get isPaused;
  Future<E> asFuture<E>([E? futureValue]);
}

// For some reason that explicit Function(E value) makes it way faster
class _NodeSub<E> implements _Subscription<E> {
  Function(E value)? get _handleData => _paused ? null : __handleData;
  Function(E value)? __handleData;

  ErrorCallBack? get _handleError => _paused ? null : __handleError;
  ErrorCallBack? __handleError;

  VoidCallback? get _handleDone => _paused ? null : __handleDone;
  VoidCallback? __handleDone;

  _NodeSub<E>? _previous;
  _NodeSub<E>? _next;
  ReactiveImplicit<E>? _parent;

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
    __handleData = handleData;
  }

  @override
  void onDone(VoidCallback? handleDone) {
    __handleDone = handleDone;
  }

  @override
  void onError(ErrorCallBack? handleError) {
    __handleError = handleError;
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    resumeSignal?.then((_) => _paused = false);
  }

  @override
  void resume() {
    _paused = false;
  }

  _NodeSub<E>? _close() {
    _previous = _parent = null;
    _handleDone?.call();
    return _next;
  }

  @override
  void cancel() {
    if (identical(_parent, null)) return;
    // TODO: maybe _parent!.onCancel ?
    _parent!._unlink(this);
    _parent = null;
  }
}

class ReactiveImplicit<T> {
  T? _value;
  set value(T val) {
    if (_value != val) {
      _value = val;
      emit();
    }
  }

  T get value => _value as T;

  _NodeSub<T>? _firstSubscrption;
  _NodeSub<T>? _lastSubscription;

  ReactiveImplicit([this._value]);

  _Subscription<T> listen(Function(T value)? onData,
      {ErrorCallBack? onError, VoidCallback? onDone, bool? cancelOnError}) {
    final node = _NodeSub<T>(this, onData, onError, onDone);
    if (identical(_firstSubscrption, null)) {
      return _lastSubscription = _firstSubscrption = node;
    }
    node._previous = _lastSubscription;
    return _lastSubscription = _lastSubscription!._next = node;
  }

  void emit() {
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T>? currentSubscription = _firstSubscrption
      ?.._handleData?.call(_value as T);
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleData?.call(_value as T);
      }
    } catch (exception, trace) {
      _reportError("emit", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueEmitting(currentSubscription!._next);
    }
  }

  void addError(Object error, [StackTrace? trace]) {
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T>? currentSubscription = _firstSubscrption;
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

  void close() {
    // No need to close if we have no _firstSubscrption
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T>? currentSubscription = _firstSubscrption;
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

  void _continueEmitting(_NodeSub<T>? currentSubscription) {
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleData?.call(_value as T);
      }
    } catch (exception, trace) {
      _reportError("emit", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueEmitting(currentSubscription!._next);
    }
  }

  void _continueAddingError(
      Object error, StackTrace? trace, _NodeSub<T>? currentSubscription) {
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

  void _continueClosing(_NodeSub<T>? currentSubscription) {
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

  void _unlink(_NodeSub<T> node) {
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

  void _reportError(String kind, Object exception, [StackTrace? trace]) {}
}
