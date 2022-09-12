import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import '../../../obx.dart';
import '../../orchestrator.dart';
import '../../equality.dart';

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
    res._addDisposeListener(subscribe((T data) => res.value = transform(data)));
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
    res._addDisposeListener(subscribe((T data) {
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
    res._addDisposeListener(subscribe((T data) {
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

  //TODO: write doc
  @override
  VoidCallback subscribe(Function(T value) callback,
          {StreamFilter<T>? filter}) =>
      filter?.call(stream).listen(callback).cancel ?? super.subscribe(callback);

  //TODO: write doc
  @override
  VoidCallback subNow(Function(T value) callback, {StreamFilter<T>? filter}) {
    callback(_value as T);
    return filter?.call(stream).listen(callback).cancel ??
        super.subscribe(callback);
  }

  //TODO: write doc
  @override
  VoidCallback subDiff(Function(T last, T current) callback,
      {StreamFilter<T>? filter}) {
    if (filter != null) {
      T oldVal = _value as T;
      listener(T value) {
        callback(oldVal, value);
        oldVal = _value as T;
      }

      return filter(stream).listen(listener).cancel;
    }
    return super.subDiff(callback);
  }

  List<Disposer>? _disposers;
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
  /// This also mean that the error will be sent to the stream
  /// If you made one lazy load
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
      for (int i = 0; i <= _disposers!.length; i++) {
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
    final sub = rx.subscribe(
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
    // TODO: remove this from the list of observables
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

  List<Disposer>? _disposers = [];

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

/// This is the mos basic reactive component
/// This will just update the ui when it updates
class Reactive<T> {
  int _reserveInt = 0;

  T? _value;

  final Equality _eq;
  Equality get equalizer =>
      _eq is CacheWrapper<T> ? (_eq as CacheWrapper<T>).eq : _eq;

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  bool get hasValue => _value != null || null is T;

  Reactive({T? initial, Equality eq = const Equality()})
      : _value = initial,
        _eq = eq;

  List<Function(T e)?> _listeners = List<Function(T e)?>.filled(1, null);

  static bool debugAssertNotDisposed(Reactive notifier) {
    assert(() {
      if (notifier.disposed) {
        throw FlutterError(
          'A ${notifier.runtimeType} was used after being disposed.\n'
          'Once you have called dispose() on a ${notifier.runtimeType}, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  /// Used to add listeners
  ///
  /// This function is optimized with voodoo to be as fast as possible
  /// I'm joking, but no kidding it's faster than ChangeNotifier
  void _addListener(Function(T e) listener) {
    assert(Reactive.debugAssertNotDisposed(this));
    if (_count == _listeners.length) {
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(_listeners.length + 5, null);
      for (int i = 0; i < _count; i++) {
        newListeners[i] = _listeners[i];
      }
      _listeners = newListeners;
    }

    _listeners[_reserveInt++] = listener;
  }

  void _removeAt(int index) {
    // The list holding the listeners is not growable for performances reasons.
    // We still want to shrink this list if a lot of listeners have been added
    // and then removed outside a notifyListeners iteration.
    // We do this only when the real number of listeners is half the length
    // of our list.
    _reserveInt -= 1;
    if (_count + 5 < _listeners.length) {
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(_count, null);

      // Listeners before the index are at the same place.
      for (int i = 0; i < index; i++) {
        newListeners[i] = _listeners[i];
      }

      // Listeners after the index move towards the start of the list.
      for (int i = index; i < _count; i++) {
        newListeners[i] = _listeners[i + 1];
      }

      _listeners = newListeners;
    } else {
      // When there are more listeners than half the length of the list, we only
      // shift our listeners, so that we avoid to reallocate memory for the
      // whole list.
      for (int i = index; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    }
  }

  /// Used to remove the listener
  ///
  /// This function is made to be ultra fast
  /// We won't remove anything here
  /// Just set thos to null
  /// Then we will garbage collect manually the list
  void _removeListener(Function(T e) listener) {
    if ((_reserveInt & 4294901760) != 0) {
      for (int i = 0; i < _count; i++) {
        if (_listeners[i] == listener) {
          _listeners[i] = null;
          _reserveInt += 4294967296;
          break;
        }
      }
    } else {
      for (int i = 0; i < _count; i++) {
        if (_listeners[i] == listener) {
          _listeners[i] = null;
          _removeAt(i);
          break;
        }
      }
    }
  }

  /// Shift existing callbacks to the null values are at the end
  ///
  /// This is a sort of many garbage collection
  /// Will reallocate the List if it shrinks to much
  void _shift() {
    // TODO: implem cleanup with the third space and shift operation
    // TODO: this time we need to recreate the list
  }

  bool get disposed => _listeners.isEmpty;
  bool get hasListeners => (_count) != 0;

  int get _count => _reserveInt & 65535;
  int get _removedReantrant => (_reserveInt & 562949953355776) >> 32;
  bool get _hasController => (_reserveInt & 281474976710656) != 0;
  void _toggleHasController() => _reserveInt ^ 281474976710656;
  bool get _hasDisposers => (_reserveInt & 562949953421312) != 0;
  void _toggleHasDisposers() => _reserveInt ^ 562949953421312;
  bool get _hasErrorListeners => (_reserveInt & 1125899906842624) != 0;
  void _toggleHasHasErrorListeners() => _reserveInt ^ 1125899906842624;

  // TODO: implement detatch if needed
  void detatch() {}

  @mustCallSuper
  void dispose() {
    assert(Reactive.debugAssertNotDisposed(this));
    _listeners = [];
    _reserveInt = 0;
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void emit() {
    assert(Reactive.debugAssertNotDisposed(this));
    _reserveInt += 65536;
    for (int i = 0; i < _count; i++) {
      _listeners[i]?.call(_value as T);
    }
    _reserveInt -= 65536;
    if ((_reserveInt & 562949953355776) != 0) _shift();
  }

  /// You should make sure to not call this if there is no value
  T get value {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value as T;
  }

  /// Change the value if it matches the equality constraint
  set value(T val) {
    if (_eq.equals(_value, val)) return;
    _value = val;
    emit();
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    _value = v;
  }

  /// Trigger update
  /// Force update value and notify all elements
  /// This means that piped object will recieve the update
  void trigger(T v) {
    _value = v;
    emit();
  }

  VoidCallback subscribe(
    Function(T value) callback,
  ) {
    _addListener(callback);
    return () => _removeListener(callback);
  }

  VoidCallback subNow(Function(T value) callback) {
    callback(_value as T);
    _addListener(callback);
    return () => _removeListener(callback);
  }

  VoidCallback subDiff(
    Function(T last, T current) callback,
  ) {
    T oldVal = _value as T;
    listener(T value) {
      callback(oldVal, value);
      oldVal = _value as T;
    }

    _addListener(listener);
    return () => _removeListener(listener);
  }

  @protected
  void _reportRead() {
    if (Orchestrator.notInObserve) {
      final reactives = Orchestrator.element!.reactives;
      for (int i = 0; i < reactives.length; i++) {
        if (reactives[i] == this) return;
      }
      reactives.add(this);
      _addListener(Orchestrator.element!.refresh);
    } else {
      final reactives = Orchestrator.reactives;
      for (int i = 0; i < reactives.length; i++) {
        if (reactives[i] == this) return;
      }
      final listener = Orchestrator.notifyData!.updater;
      reactives.add(this);
      _addListener(listener);
      Orchestrator.notifyData!.disposers.add(() => _removeListener(listener));
    }
  }
}

class RxSubscription<T> implements StreamSubscription<T> {
  Rx<T>? _parent;
  Function(T data)? _onData;
  Function(Object error, [StackTrace? trace])? _onError;
  void Function()? _onDone;
  bool _paused = false;

  RxSubscription(Rx<T> parent,
      {Function(T data)? onData,
      void Function()? onDone,
      Function(Object error, [StackTrace? trace])? onError})
      : _parent = parent,
        _onData = onData,
        _onDone = onDone,
        _onError = onError {
    resume();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    final completer = Completer<E>();
    onDone(() => completer.complete(futureValue as E));
    onError((Object error, [StackTrace? trace]) {
      completer.completeError(error, trace);
      cancel();
    });
    return completer.future;
  }

  @override
  Future<void> cancel() async {
    if (!_paused && _parent != null) {
      if (_onData != null) {
        _parent!._removeListener(_onData!);
      }
      if (_onDone != null) {
        _parent!._addDisposeListener(_onDone!);
      }
      if (_onError != null) {
        _parent!._addErrorListener(_onError!);
      }
      _parent = null;
    }
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(Function(T data)? handleData) {
    if (_onData != null && !_paused) {
      _parent?._removeListener(_onData!);
    }
    _onData = handleData;
    if (_onData != null) {
      _parent?._addListener(_onData!);
    }
  }

  @override
  void onDone(void Function()? handleDone) {
    if (_onDone != null && !_paused) {
      _parent?._removeDisposeListener(_onDone!);
    }
    _onDone = handleDone;
    if (_onDone != null) {
      _parent?._addDisposeListener(_onDone!);
    }
  }

  @override
  void onError(Function? handleError) {
    if (_onError != null && !_paused) {
      _parent?._removeErrorListener(_onError!);
    }
    _onError = handleError as Function(Object, [StackTrace?]);
    if (_onError != null) {
      _parent?._addErrorListener(_onError!);
    }
  }

  /// Like stream pause but elements won't be buffered
  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    if (_parent != null) {
      if (_onData != null) {
        _parent!._removeListener(_onData!);
      }
      if (_onDone != null) {
        _parent!._removeDisposeListener(_onDone!);
      }
      if (_onError != null) {
        _parent!._removeErrorListener(_onError!);
      }
    }
    resumeSignal?.then((_) => resume());
  }

  @override
  void resume() {
    _paused = false;
    if (_parent != null) {
      if (_onData != null) {
        _parent!._addListener(_onData!);
      }
      if (_onDone != null) {
        _parent!._addDisposeListener(_onDone!);
      }
      if (_onError != null) {
        _parent!._addErrorListener(_onError!);
      }
    }
  }
}

extension ValueOrNull<T> on Reactive<T> {
  T? get valueOrNull {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value;
  }
}

/// Component that can track changes in a reactive variable
mixin StatelessObserverComponent on StatelessElement {
  List<Reactive> reactives = [];

  void refresh(_) {
    if (reactives.isNotEmpty) {
      scheduleMicrotask(markNeedsBuild);
    }
  }

  @override
  Widget build() {
    Orchestrator.element = this;
    final result = super.build();
    if (reactives.isEmpty) {
      throw const ObxError();
    }
    Orchestrator.element = null;
    return result;
  }

  @override
  void unmount() {
    super.unmount();
    for (int i = 0; i < reactives.length; i++) {
      reactives[i]._removeListener(refresh);
    }
    reactives = [];
  }
}
