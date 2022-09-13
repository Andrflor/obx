part of '../../orchestrator.dart';

// TODO: add the errors on the bindings
// TODO: add errors / disposers on the listen

class RxImpl<T> extends Reactive<T> {
  RxImpl({super.initial, super.eq});

  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert, Equality? eq}) =>
      Rx.withEq(
          init: hasValue ? (convert?.call(_value as T) ?? _value as S) : null,
          eq: eq ??
              (distinct == null
                  ? _eq
                  : distinct
                      ? const Equality()
                      : const NeverEquality()));

  /// Creates a new [Rx<S>] based on [StreamTransformation<S,T>] of this [Rx<T>]
  ///
  /// The provided `transformer` will be used to tranform the incoming stream
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// Avoid chaining this operator
  /// To do common operation, prefer the other `pipe` operators
  /// Those are not based on stream, so much faster
  /// See also:
  /// - [pipeMap]
  /// - [pipeWhere]
  /// - [pipeMapWhere]
  Rx<S> pipe<S>(StreamTransformation<S, T> transformer,
          {S Function(T e)? init, bool? distinct}) =>
      _clone(
        convert: init,
        distinct: distinct,
      )..bindStream(transformer(stream));

  /// Maps this [Rx<T>] into a new [Rx<S>]
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeMap] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMap<S>(S Function(T e) transform, {bool? distinct, Equality? eq}) {
    final res = _clone(distinct: distinct, convert: transform, eq: eq);
    res._addDisposeListener(listen((T data) => res.value = transform(data)));
    return res;
  }

  /// Create a [Rx<T>] from this [Rx<T>] discarding elements based on a `test`
  ///
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<T>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeWhere] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<T> pipeWhere(bool Function(T e) test, {bool? distinct, Equality? eq}) {
    final res = _clone<T>(distinct: distinct, eq: eq);
    res._addDisposeListener(listen((T data) {
      if (test(data)) {
        res.value = data;
      }
    }));
    return res;
  }

  /// Maps this [Rx<T>] into [Rx<T>] discarding elements based on a `test`
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeMapWhere] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMapWhere<S>(S Function(T e) transform, bool Function(T e) test,
      {bool? distinct, Equality? eq}) {
    final res = _clone(distinct: distinct, eq: eq, convert: transform);
    res._addDisposeListener(listen((T data) {
      if (test(data)) {
        res.value = transform(data);
      }
    }));
    return res;
  }

  /// Create an exact copy of the [Rx<T>]
  ///
  /// The copy will receive all events comming from the original
  Rx<T> dupe({Equality? eq}) =>
      Rx.withEq(init: _value, eq: eq ?? _eq)..bindRx(this);

  /// Create an exact copy of the [Rx<T>] but distinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Events that are indistinct will be skipped
  Rx<T> distinct() => dupe(eq: const Equality());

  /// Create an exact copy of the [Rx<T>] but indistinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Be aware that even if this observable is indistinct
  /// The value it recieves from the parent will match parent policy
  Rx<T> indistinct() => dupe(eq: const NeverEquality());

  /// The stream associated with this Rx
  ///
  /// Returns a Broadcast [Stream<T>]
  /// The [StreamController] is lazy loaded
  ///
  /// Only use it if you really need it
  /// Streams are 10 to 100 times slower
  /// And use more ressources
  ///
  /// Furthermore [Rx] is not based on stream
  Stream<T> get stream {
    if (_hasController) return _streamController!.stream;
    _streamController = StreamController<T>.broadcast();
    _addListener(_streamController!.add);
    _streamController!.onCancel = () {
      if (!_streamController!.hasListener) {
        _removeListener(_streamController!.add);
        _streamController!.close();
        _streamController = null;
        _toggleHasController();
      }
    };
    _toggleHasController();
    return _streamController!.stream;
  }

  @override
  String toString() => value.toString();

  // We check if we have a distinct observable
  bool get isDistinct => equalizer is! NeverEquality;

  /// Simple listen to an [Rx]
  ///
  /// Allow to pass a StreamFilter to modify the stream
  /// If no [StreamFilter] is provided no [Stream] will be used
  /// Thus resulting in up to 90x faster results
  /// So only use a StreamFilter if you really need it
  ///
  /// Returns a [VoidCallback] to dispose the listener
  @override
  VoidCallback listen(Function(T value) callback, {StreamFilter<T>? filter}) =>
      filter?.call(stream).listen(callback).cancel ?? super.listen(callback);

  StreamController<T>? _streamController;
  List<void Function(Object error, [StackTrace? trace])>? _errorListeners;

  /// Add an errorListener to the [Rx]
  void _addErrorListener(
      void Function(Object error, [StackTrace? trace]) errorListener) {
    if (_hasErrorListeners) {
      _errorListeners!.add(errorListener);
    } else {
      _errorListeners = [errorListener];
      _toggleHasController();
    }
  }

  /// Remove an errorListener to the [Rx]
  bool _removeErrorListener(
      void Function(Object error, [StackTrace? trace]) errorListener) {
    if (_hasErrorListeners) {
      if (_errorListeners!.remove(errorListener)) {
        if (_errorListeners!.isEmpty) {
          _errorListeners = null;
          _toggleHasHasErrorListeners();
        }
        return true;
      }
    }
    return false;
  }

  /// Add a disposeListener to the [Rx]
  void _addDisposeListener(void Function() disposer) {
    if (_hasDisposers) {
      _disposers!.add(disposer);
    } else {
      _disposers = [disposer];
      _toggleHasDisposers();
    }
  }

  /// Remove a disposer to the [Rx]
  bool _removeDisposeListener(void Function() disposer) {
    if (_hasDisposers) {
      if (_disposers!.remove(disposer)) {
        if (_disposers!.isEmpty) {
          _disposers = null;
          _toggleHasDisposers();
        }
        return true;
      }
    }
    return false;
  }

  /// Allow to add an error the the [Rx]
  ///
  /// Error will be sent to all existing listeners
  /// This also mean that the error will be sent to the stream if any
  void addError(Object error, [StackTrace? trace]) {
    if (_hasErrorListeners) {
      for (int i = 0; i < _errorListeners!.length; i++) {
        _errorListeners![i](error, trace);
      }
    }
    if (_hasController) {
      _streamController!.addError(error, trace);
    }
  }

  void _removeController() {
    if (_hasController) {
      _removeListener(_streamController!.add);
      _streamController!.close();
      _streamController = null;
      _toggleHasController();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_hasErrorListeners) _errorListeners = null;
    if (_hasDisposers) {
      for (int i = 0; i < _disposers!.length; i++) {
        _disposers![i]();
      }
      _disposers = null;
    }
    _removeController();
    super.dispose();
  }

  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  ///
  /// You can bind multiple sources to update the value.
  /// Once a stream closes the subscription will cancel itself
  /// You can also cancel the sub with the provided callback
  Disposer bindStream(Stream<T> stream, [StreamFilter<T>? filter]) {
    final sub = (filter?.call(stream) ?? stream).listen((e) {
      value = e;
    }, cancelOnError: false);
    _addDisposeListener(sub.cancel);
    clean() {
      _removeDisposeListener(sub.cancel);
      sub.cancel();
    }

    sub.onDone(clean);
    return clean;
  }

  /// Binding to this [Rx<T>] to any other [Rx<T>]
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindRx(RxImpl<T> rx, [StreamFilter<T>? filter]) {
    final sub = rx.listen(
      (e) {
        value = e;
      },
      filter: filter,
    );
    _addDisposeListener(sub);
    clean() {
      _removeDisposeListener(sub);
      sub();
    }

    return clean;
  }

  /// Binding to any listener with callback
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindValueListenable(
    ValueListenable<T> listenable,
  ) {
    closure() {
      value = listenable.value;
    }

    listenable.addListener(closure);
    cancel() => listenable.removeListener(closure);
    _addDisposeListener(cancel);

    return () {
      _removeDisposeListener(cancel);
      cancel();
    };
  }

  /// Binding to any listener with provided `onEvent` callback
  ///
  /// Binds an existing [Listenable]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [Listenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindListenable(Listenable listenable,
      {required T Function() onEvent}) {
    closure() => value = onEvent();
    listenable.addListener(closure);
    cancel() => listenable.removeListener(closure);
    _addDisposeListener(cancel);

    return () {
      _removeDisposeListener(cancel);
      cancel();
    };
  }
}

/// This is an internal class
///
/// It's the basic class for the [observe] function
/// It's name comes from the fact that it is set up
/// Then it fire once, and then it dies
/// So it really has a "single shot"
class SingleShot<T> extends Reactive<T> {
  SingleShot() : super();

  @override
  void emit() {
    super.emit();
    dispose();
  }

  @override
  void dispose() {
    for (int i = 0; i < _disposers!.length; i++) {
      _disposers![i]();
    }
    _disposers = null;
    // TODO: remove from ObxElement
    super.dispose();
  }
}

/// Simple emitter for when you don't care about the value
///
/// Example:
/// ```dart
/// final emitter = Emitter();
/// emitter.emit(); \\ Will emit a null value
/// ```
/// This null emit will be forwareded to Listeners
//ignore: prefer_void_to_null
class Emitter extends Reactive<Null> {
  Emitter() : super(eq: const NeverEquality());

  /// Creates an emitter that emits from an Interval
  factory Emitter.fromInterval(
    Duration delay,
  ) =>
      Emitter()..emitEvery(delay);

  /// Cancel the emitter from auto emitting
  void cancel() {
    for (int i = 0; i < (_disposers?.length ?? 0); i++) {
      _disposers![i]();
    }
  }

  /// Will emit after `delay`
  void emitIn(Duration delay) {
    assert(Reactive.debugAssertNotDisposed(this));
    _disposers?.add(Timer.periodic(delay, (_) {
      emit();
    }).cancel);
  }

  /// Will emit every `delay`
  void emitEvery(Duration delay) {
    assert(Reactive.debugAssertNotDisposed(this));
    _disposers?.add(Timer(delay, () {
      emit();
    }).cancel);
  }

  @override
  //ignore: prefer_void_to_null
  set value(Null value) => emit();

  @override
  Null get value {
    assert(Reactive.debugAssertNotDisposed(this));
    if (!Orchestrator.notInBuild) _reportRead();
    return null;
  }

  /// Bundle a [T] with this emitter
  ///
  /// This allow to pass the emitter inside the UI
  /// Example:
  /// ```dart
  /// Obx(() => Text(emiter.bundle(myVariable)));
  /// ```
  T bundle<T>(T value) {
    assert(Reactive.debugAssertNotDisposed(this));
    if (!Orchestrator.notInBuild) _reportRead();
    return value;
  }

  @override
  void dispose() {
    cancel();
    _disposers = null;
    super.dispose();
  }
}
