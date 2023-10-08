part of '../../orchestrator.dart';

/// This is the most basic reactive component
/// This will just update the ui when it updates
class Reactive<T> implements EventSink<T> {
  T? _data;
  Object? _error;

  final Equality _eq;
  Equality get equalizer =>
      _eq is CacheWrapper<T> ? (_eq as CacheWrapper<T>).eq : _eq;

  _NodeSub<T, Function(T value)>? _firstSubscription;
  _NodeSub<T, Function(T value)>? _lastSubscription;

  /// Retreive the data and add one if specified
  T call([T? value]) {
    if (value != null) {
      data = value;
    }
    return data;
  }

  /// Chekc if this rx has a value
  bool get hasValue => _data is T;

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

  _RxStream<T>? _stream;

  /// The stream associated with this Rx
  ///
  /// Returns a Fast Sync Broadcast [Stream<T>]
  /// This is a full reimplementation of Stream
  /// If you what this stream to be async
  /// Just call the `async()` method
  /// Be aware that async() stream is 10-100x slower
  RxStream<T> get stream {
    if (_stream == null) {
      return _stream = _RxStream<T>(this);
    }
    return _stream!;
  }

  @override
  void add(T event) => data = event;

  void Function()? _onListen;
  void Function()? _onCancel;

  // Allow to listen and gives you a subscription in return
  // Like [StreamSubscription] except that cancel is synchronous
  RxSubscription<T> listen(
    Function(T value)? onData, {
    Function? onError,
    VoidCallback? onDone,
    bool? cancelOnError,
  }) {
    final node = _NodeSub<T, Function(T value)>(this, onData, onError, onDone);
    if (_firstSubscription == null) {
      _lastSubscription = _firstSubscription = node;
      _onListen?.call();
      return node;
    }
    node._previous = _lastSubscription;
    _lastSubscription = _lastSubscription!._next = node;
    return node;
  }

  /// Emit the last data value
  void emit() {
    if (identical(_firstSubscription, null)) return;
    _NodeSub<T, Function(T value)>? currentSubscription;
    try {
      currentSubscription = _firstSubscription?.._handleData?.call(_data as T);
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

  /// Allow to add an error with an optional [StackTrace]
  void addError(Object error, [StackTrace? trace]) {
    _error = error;
    if (identical(_firstSubscription, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription;
    try {
      currentSubscription = _firstSubscription
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
  @override
  void close() {
    // No need to close if we have no _firstSubscrption
    if (identical(_firstSubscription, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription = _firstSubscription;
    _firstSubscription = _lastSubscription = null;
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
    if (identical(_firstSubscription, node)) {
      if (identical(_lastSubscription, node)) {
        // First = Last = Node
        _firstSubscription = _lastSubscription = null;
        _onCancel?.call();
        return;
      }
      // First = Node
      _firstSubscription = node._next;
      _firstSubscription!._previous = null;
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

  @protected
  void _reportRead() {
    if (Orchestrator.notInObserve) {
      Orchestrator.element!.read(this);
    } else {
      Orchestrator.read(this);
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
