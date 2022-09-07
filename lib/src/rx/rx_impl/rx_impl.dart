import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../orchestrator.dart';
import '../../equality.dart';
import 'rx_types.dart';
import 'rx_mixins.dart';

/// Complete implementation of Rx
class RxImpl<T> extends RxBase<T>
    with
        Actionable<T>,
        Distinguishable<T>,
        StreamBindable<T>,
        EmptyAble<T>,
        Equalizable<T> {
  RxImpl(super.val, {bool distinct = true})
      : _distinct = distinct,
        _equalizer = distinct && (val is Iterable || val is Map)
            ? equalizing<T>(val)
            : const DefaultEquality();

  @override
  // ignore: overridden_fields
  final Equality _equalizer;

  @override
  bool get isDistinct => _distinct;
  final bool _distinct;

  // This value will only be set if it matches
  @override
  set value(T newValue) {
    if (isDistinct && _equalizer.equals(_value, newValue)) return;
    super.trigger(newValue);
  }
}

mixin Equalizable<T> on Reactive<T> {
  /// Used to check for equality
  /// Since it's late it won't even use space if indistinct
  /// Since Equality are all const constructor there will only be
  /// One instance of each, so this is just a pointer in memory
  late final Equality _equalizer;

  @override
  bool operator ==(Object other) {
    if (other is ValueListenable<T?>) {
      return _equalizer.equals(value, other.value);
    }
    return _equalizer.foreignEquals(value, other);
  }

  @override
  int get hashCode => value.hashCode;
}

// This mixin is used to provide Actions to call
mixin Actionable<T> on Reactive<T> implements Emitting {
  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Trigger update with a new value
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    _value = v;
    _notify();
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  @override
  void emit() {
    trigger(_value as T);
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    _value = v;
  }

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  void refresh([T? v]) {
    if (v != null) {
      _value = v;
    }
    _notify();
  }
}

mixin EmptyAble<T> on RxBase<T> {
  bool get hasValue => _value != null || null is T;

  @override
  Disposer listenNow(
    void Function(T e) onData, {
    Function? onError,
    void Function()? onDone,
    StreamFilter<T>? filter,
    bool? cancelOnError,
  }) {
    if (hasValue) {
      onData(_value as T);
    }
    return listen(
      onData,
      filter: filter,
    );
  }
}

/// Basic implementation of the Rx
/// We have put a lot in the mixer (mixins)
class RxBase<T> extends Reactive<T>
    with
        Descriptible<T>,
        DisposersTrackable<T>,
        StreamCapable<T>,
        BroadCastStreamCapable<T> {
  RxBase(super.val);
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
class Emitter extends RxBase<Null> implements Emitting {
  Emitter() : super(null);

  /// Creates an emitter that emits from an Interval
  factory Emitter.fromInterval(
    Duration delay,
  ) =>
      Emitter()..emitEvery(delay);

  /// Cancel the emitter from auto emitting
  void cancel() {
    for (Disposer disposer in _disposers!) {
      disposer();
    }
    disposers!.clear();
  }

  /// Will emit after `delay`
  void emitIn(Duration delay) {
    _disposers!.add(Timer.periodic(delay, (_) {
      emit();
    }).cancel);
  }

  /// Will emit every `delay`
  void emitEvery(Duration delay) {
    _disposers!.add(Timer(delay, () {
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

  /// Emit a change to update UI/Listeners
  @override
  emit() {
    streamController?.add(null);
    _notify();
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

/// This is an internal class
/// It's the basic class for the [observe] function
/// It's name comes from the fact that it is set up
/// Then it fire once, and then it dies
/// So it really has a "single shot"
class SingleShot<T> extends Shot<T> {
  @override
  void _notify() {
    super._notify();
    for (final disposer in _disposers!) {
      disposer();
    }
    _disposers!.clear();
    _disposers = null;
    dispose();
  }
}

/// This is an internal class
/// It's the basic class for the [ever] function
class MultiShot<T> = Shot<T> with StreamCapable<T>;

/// This is an internal class
/// It's the basic class for [observe] and [ever]
/// It's name comes from the fact that it shoots
class Shot<T> extends Reactive<T> with DisposersTrackable<T>, Equalizable<T> {
  Shot() : super(null);

  @override
  set value(T newValue) {
    if (_equalizer.equals(_value, newValue)) {
      return;
    }
    _value = newValue;
    _notify();
  }

  void init(T value) {
    _equalizer = equalizing<T>(value);
    _value = value;
  }
}

mixin DisposersTrackable<T> on Reactive<T> {
  List<Disposer>? _disposers = <Disposer>[];
}

/// This is the mos basic reactive component
/// This will just update the ui when it updates
class Reactive<T> extends ListNotifier implements ValueListenable<T> {
  Reactive(T? val) : _value = val;

  T? _value;

  /// You should make sure to not call this if there is no value
  @override
  T get value {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value as T;
  }

  set value(T newValue) {
    if (value == newValue) {
      return;
    }
    _value = newValue;
    _notify();
  }
}

/// A Notifier with single listeners
class ListNotifier = Listenable with ListNotifiable;

/// This mixin add to Listenable the addListener, removerListener and
/// containsListener implementation
mixin ListNotifiable on Listenable {
  List<VoidCallback>? _listeners = <VoidCallback>[];

  @override
  void addListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners!.add(listener);
  }

  bool containsListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    return _listeners!.contains(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners!.remove(listener);
  }

  @protected
  void _notify() {
    assert(_debugAssertNotDisposed());
    _notifyUpdate();
  }

  @protected
  void _reportRead() => Orchestrator.read(this);

  @protected
  void reportAdd(VoidCallback disposer) => Orchestrator.add(disposer);

  void _notifyUpdate() {
    for (int i = 0; i < _listeners!.length; i++) {
      _listeners![i]();
    }
  }

  bool get isDisposed => _listeners == null;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (isDisposed) {
        throw FlutterError('''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''');
      }
      return true;
    }());
    return true;
  }

  int get listenersLength {
    assert(_debugAssertNotDisposed());
    return _listeners!.length;
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
  }
}

extension ValueOrNull<T> on Reactive<T> {
  T? get valueOrNull {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value;
  }
}

/// This is used to pass private fields to other files
extension ReactiveProtectedAccess<T> on Reactive<T> {
  T? get staticOrNull => _value;
  void notify() => _notify();
}

/// This is used to pass private fields to other files
extension DisposerTrackableProtectedAccess<T> on DisposersTrackable<T> {
  List<Disposer>? get disposers => _disposers;
  set disposers(List<Disposer>? newDisposers) => _disposers = newDisposers;
}
