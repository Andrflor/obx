import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import '../../orchestrator.dart';
import '../../equality.dart';

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
  Emitter() : super(equalizer: const NeverEquality());

  /// Creates an emitter that emits from an Interval
  factory Emitter.fromInterval(
    Duration delay,
  ) =>
      Emitter()..emitEvery(delay);

  /// Cancel the emitter from auto emitting
  void cancel() {
    for (Disposer disposer in _disposers) {
      disposer();
    }
    _disposers = [];
  }

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

  final Equality _equalizer;
  Equality get equalizer => _equalizer;

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return _value as T;
  }

  bool get hasValue => _value != null || null is T;

  Reactive({T? initial, Equality equalizer = const BaseEquality()})
      : _value = initial,
        _equalizer = equalizer;

  List<Function(T e)?> _listeners = List<Function(T e)?>.filled(5, null);
  List<VoidCallback> _disposers = [];

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

  /// This method allow to remove all incoming subs
  /// This will detatched this obs from stream listenable other piped obs
  void detatch() {
    for (Disposer disposer in _disposers) {
      disposer();
    }
    _disposers = [];
  }

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

    _listeners[_count++] = listener;
  }

  void _removeListener(Function(T e) listener) {
    for (int i = 0; i < _count; i++) {
      if (_listeners[i] == listener) {
        _listeners[i] = null;
        _nullIdx.add(i);
        break;
      }
    }
  }

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
    detatch();
    assert(Reactive.debugAssertNotDisposed(this));
    _listeners = [];
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
    if (_nullIdx.isNotEmpty) _shift();
  }

  /// You should make sure to not call this if there is no value
  T get value {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value as T;
  }

  set value(T val) {
    if (_equalizer.equals(_value, val)) return;
    _value = val;
    emit();
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    _value = v;
  }

  VoidCallback subscribe(Function(T value) callback) {
    _addListener(callback);
    return () => _removeListener(callback);
  }

  VoidCallback subDiff(Function(T last, T current) callback) {
    T oldVal = _value as T;
    listener(T value) {
      callback(oldVal, value);
      oldVal = _value as T;
    }

    _addListener(listener);
    return () => _removeListener(listener);
  }

  VoidCallback subNow(Function(T value) callback) {
    callback(_value as T);
    _addListener(callback);
    return () => _removeListener(callback);
  }

  @protected
  void _reportRead() => Orchestrator.read(this);

  @protected
  void reportAdd(VoidCallback disposer) => Orchestrator.add(disposer);
}

extension ValueOrNull<T> on Reactive<T> {
  T? get valueOrNull {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value;
  }
}

/// This is used to pass private fields to other files
extension RxTrackableProtectedAccess<T> on Reactive<T> {
  List<Disposer> get disposers => _disposers;
  set disposers(List<Disposer> value) => _disposers = value;
  T? get staticOrNull => _value;
}
