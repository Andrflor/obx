import 'dart:async';

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
    res._disposers.add(subscribe((T data) => res.value = transform(data)));
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
    res._disposers.add(subscribe((T data) {
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
    res._disposers.add(subscribe((T data) {
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
  /// It uses [Expando] to avoid any unnecessary memory allocation
  Stream<T> get stream {
    final controller = _streamControllerExpando[this] as StreamController<T>?;
    if (controller != null) return controller.stream;
    final newController = StreamController<T>.broadcast();
    _streamControllerExpando[this] = newController;
    _addListener(newController.add);
    newController.onCancel = () {
      if (!newController.hasListener) {
        _removeListener(newController.add);
        newController.close();
        _streamControllerExpando[this] = null;
      }
    };
    return newController.stream;
  }

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

  void _removeController() {
    final controller = _streamControllerExpando[this];
    if (controller != null) {
      _removeListener(controller.add);
      controller.close();
      _streamControllerExpando[this] = null;
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    detatch();
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
    _disposers.add(sub.cancel);
    clean() {
      _disposers.remove(sub.cancel);
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
    _disposers.add(sub);
    clean() {
      _disposers.remove(sub);
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
    _disposers.add(cancel);

    return () {
      _disposers.remove(cancel);
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
    _disposers.add(cancel);

    return () {
      _disposers.remove(cancel);
      cancel();
    };
  }
}

/// This is an internal class
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
}

/// Simple emitter for when you don't care about the value
///
/// Example:
/// ```dart
/// final emitter = Emitter();
/// emitter.emit(); \\ Will emit a null value
/// ```
///
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
  void cancel() => detatch();

  /// Will emit after `delay`
  void emitIn(Duration delay) {
    _disposers.add(Timer.periodic(delay, (_) {
      emit();
    }).cancel);
  }

  /// Will emit every `delay`
  void emitEvery(Duration delay) {
    _disposers.add(Timer(delay, () {
      emit();
    }).cancel);
  }

  @override
  //ignore: prefer_void_to_null
  set value(Null value) => emit();

  @override
  Null get value {
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
    if (!Orchestrator.notInBuild) _reportRead();
    return value;
  }
}

/// This is the mos basic reactive component
/// This will just update the ui when it updates
class Reactive<T> {
  int _count = 0;
  List<int> _nullIdx = [];

  T? _value;

  final Equality _eq;
  Equality get equalizer =>
      _eq is CacheWrapper<T> ? (_eq as CacheWrapper<T>).eq : _eq;

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return _value as T;
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
          List<Function(T e)?>.filled(_listeners.length + 4, null);
      for (int i = 0; i < _count; i++) {
        newListeners[i] = _listeners[i];
      }
      _listeners = newListeners;
    }

    _listeners[_count++] = listener;
  }

  /// Used to remove the listener
  ///
  /// This function is made to be ultra fast
  /// We won't remove anything here
  /// Just set thos to null
  /// Then we will garbage collect manually the list
  /// Using the [_shift] function to shrink the list
  void _removeListener(Function(T e) listener) {
    for (int i = 0; i < _count; i++) {
      if (_listeners[i] == listener) {
        _listeners[i] = null;
        _nullIdx.add(i);
        break;
      }
    }
  }

  /// Shift existing callbacks to the null values are at the end
  ///
  /// This is a sort of many garbage collection
  /// Will reallocate the List if it shrinks to much
  void _shift() {
    final length = _nullIdx.length;
    if (length == 1) {
      _count -= length;
      for (int i = _nullIdx.first; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    } else {
      _nullIdx.sort();
      // TODO: reallocate smaller if needed
      int shift = 1;
      for (int i = 0; i < length; i++) {
        if (i + 1 == length) {
          for (int j = _nullIdx[i] + 1; j < _count; j++) {
            _listeners[j - shift] = _listeners[j];
          }
          for (int j = _count - shift; j < _count; j++) {
            _listeners[j] = null;
          }
          break;
        }
        if (_nullIdx[i] + 1 == _nullIdx[i + 1]) {
          shift++;
          continue;
        }
        for (int j = _nullIdx[i] + 1; j < _nullIdx[i + 1]; j++) {
          _listeners[j - shift] = _listeners[j];
        }
        shift++;
      }
      _count -= length;
    }
    _nullIdx = [];
  }

  bool get disposed => _listeners.isEmpty;

  @mustCallSuper
  void dispose() {
    assert(Reactive.debugAssertNotDisposed(this));
    _disposersExpando[this] = null;
    _listeners = [];
    _nullIdx = [];
    _count = 0;
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void emit() {
    assert(Reactive.debugAssertNotDisposed(this));
    for (int i = 0; i < _count; i++) {
      _listeners[i]?.call(_value as T);
    }
    // If callback have been deleted they will be in the _nullIdxList
    // So we need to [_shift] to assure speed and collect our garbage
    if (_nullIdx.isNotEmpty) _shift();
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

  /// Ca
  void _addErrorListener(
      void Function(Object error, [StackTrace? trace]) errorListener) {
    final errorListeners = _errorListenerExpando[this];
    if (errorListeners == null) {
      _errorListenerExpando[this] = [errorListener];
    } else {
      errorListeners.add(errorListener);
    }
  }

  /// Allow to add an error the the [Rx]
  ///
  /// Error will be sent to all existing listeners
  /// This also mean that the error will be sent to the stream
  /// If you made one lazy load
  void addError(Object error, [StackTrace? trace]) {
    final listeners = _errorListenerExpando[this];
    if (listeners != null) {
      for (int i = 0; i < listeners.length; i++) {
        listeners[i](error, trace);
      }
    }
    _streamControllerExpando[this]?.addError(error, trace);
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
  void _reportRead() => Orchestrator.read(this);

  @protected
  void reportAdd(VoidCallback disposer) => Orchestrator.add(disposer);
}

class RxSubscription<T> implements StreamSubscription<T> {
  Rx<T>? _parent;
  Function(T data)? _listener;
  Function()? _onDone;
  bool _paused = false;

  RxSubscription(Rx<T> parent, Function(T data) listener, this._onDone)
      : _parent = parent,
        _listener = listener {
    parent._addListener(listener);
    if (_onDone != null) {
      parent._disposers.add(_onDone);
    }
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) async {
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
    if (_listener != null && !_paused) {
      _parent?._removeListener(_listener!);
    }
    _listener = null;
    _parent = null;
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(Function(T data)? handleData) {
    if (_listener != null && !_paused) {
      _parent?._removeListener(_listener!);
    }
    _listener = handleData;

    if (_listener != null && !_paused) {
      _parent?._addListener(_listener!);
    }
  }

  @override
  void onDone(void Function()? handleDone) {
    if (_onDone != null) {
      _parent?._disposers.remove(_onDone);
    }
    _onDone = handleDone;
    if (_onDone != null) {
      _parent?._disposers.add(_onDone);
    }
  }

  @override
  void onError(Function? handleError) {
    /// There is no error on Rx
    // TODO: maybe add errors?
  }

  /// Like stream pause but elements won't be buffered
  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    if (_listener != null) {
      _parent?._removeListener(_listener!);
    }
    resumeSignal?.then((_) => resume());
  }

  @override
  void resume() {
    _paused = false;
    if (_listener != null) {
      _parent?._addListener(_listener!);
    }
  }
}

extension ValueOrNull<T> on Reactive<T> {
  T? get valueOrNull {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value;
  }
}

final _disposersExpando = Expando<StreamController>();
final _streamControllerExpando = Expando<StreamController>();
final _errorListenerExpando =
    Expando<List<void Function(Object error, [StackTrace? trace])>>();

/// This is used to pass private fields to other files
extension RxTrackableProtectedAccess<T> on Reactive<T> {
  set disposers(List<void Function()?> value) => _disposers = value;
}
