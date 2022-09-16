part of '../../orchestrator.dart';

/// This is the most basic reactive component
/// This will just update the ui when it updates
class Reactive<T> {
  T? _data;
  Object? _error;

  final Equality _eq;
  Equality get equalizer =>
      _eq is CacheWrapper<T> ? (_eq as CacheWrapper<T>).eq : _eq;

  _NodeSub<T, Function(T value)>? _firstSubscrption;
  _NodeSub<T, Function(T value)>? _lastSubscription;

  /// Retreive the data and add one if specified
  T call([T? value]) {
    if (value != null) {
      data = value;
    }
    return data;
  }

  Reactive({T? initial, Equality eq = const Equality()})
      : _data = initial,
        _eq = eq;

  /// You should make sure to not call this if there is no value
  T get data {
    if (!Orchestrator.notInBuild) _reportRead();
    return _data as T;
  }

  // Change the value if it matches the equality constraint
  // Removes any existing error
  set data(T val) {
    _error = null;
    if (_eq.equals(_data, val)) return;
    _data = val;
    emit();
  }

  // Retrieve the current error
  // You should not call this if there is no error
  Object get error {
    if (!Orchestrator.notInBuild) _reportRead();
    return _error!;
  }

  // Add a new error
  set error(Object error) {
    addError(error);
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T value) {
    _data = value;
  }

  /// Trigger update
  /// Force update value and notify all elements
  /// This means that piped object will recieve the update
  void trigger(T value) {
    _data = value;
    emit();
  }

  RxStream<T>? _stream;
  RxStream<T> get stream {
    if (_stream == null) {
      return _stream = RxStream<T>(this);
    }
    return _stream!;
  }

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

  // Allow to listen and gives you a subscription in return
  // Like [StreamSubscription] except that cancel is synchronous
  StreamSubscription<T> _listen(_NodeSub<T, Function(T value)> node) {
    if (identical(_firstSubscrption, null)) {
      _lastSubscription = node;
      return _firstSubscrption = node;
    }
    node._previous = _lastSubscription;
    return _lastSubscription = _lastSubscription!._next = node;
  }

  @protected
  void _reportRead() {
    if (Orchestrator.notInObserve) {
      final reactives = Orchestrator.element!.reactives;
      for (int i = 0; i < reactives.length; i++) {
        if (reactives[i] == this) return;
      }
      reactives.add(this);
      // TODO: add back
      // _addListener(Orchestrator.element!.refresh);
    } else {
      final reactives = Orchestrator.reactives;
      for (int i = 0; i < reactives.length; i++) {
        if (reactives[i] == this) return;
      }
      final listener = Orchestrator.notifyData!.updater;
      reactives.add(this);
      // TODO: add back
      // _addListener(listener);
      // Orchestrator.notifyData!.disposers
      // .add(() => _unsafeRemoveListener(listener));
    }
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
