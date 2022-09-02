import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obx/src/rx/rx_impl/rx_mixins.dart';

import '../obx.dart';

// This callback remove the listener on addListener function
typedef Disposer = void Function();

// replacing StateSetter, return if the Widget is mounted for extra validation.
// if it brings overhead the extra call,
typedef StateUpdate = void Function();

/// A Notifier with single listeners
class ListNotifier = Listenable with ListNotifiable;

/// This mixin add to Listenable the addListener, removerListener and
/// containsListener implementation
mixin ListNotifiable on Listenable {
  List<StateUpdate>? _updaters = <StateUpdate>[];

  @override
  Disposer addListener(StateUpdate listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.add(listener);
    return () => _updaters!.remove(listener);
  }

  bool containsListener(StateUpdate listener) {
    return _updaters?.contains(listener) ?? false;
  }

  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.remove(listener);
  }

  @protected
  void _notify() {
    assert(_debugAssertNotDisposed());
    _notifyUpdate();
  }

  @protected
  void reportRead() {
    Notifier.instance.read(this);
  }

  @protected
  void reportAdd(VoidCallback disposer) {
    Notifier.instance.add(disposer);
  }

  void _notifyUpdate() {
    final list = _updaters?.toList() ?? [];

    for (var element in list) {
      element();
    }
  }

  bool get isDisposed => _updaters == null;

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
    return _updaters!.length;
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updaters = null;
  }
}

class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();
  static bool get inBuild =>
      !(instance._notifyData == null || instance._working);

  bool _working = false;
  NotifyData? _notifyData;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(ListNotifiable updaters) {
    final listener = _notifyData?.updater;
    if (listener != null && !updaters.containsListener(listener)) {
      updaters.addListener(listener);
      add(() => updaters.removeListener(listener));
    }
  }

  T append<T>(NotifyData data, T Function() builder) {
    _notifyData = data;
    final result = builder();
    if (data.disposers.isEmpty && data.throwException) {
      throw const ObxError();
    }
    _notifyData = null;
    return result;
  }

  T _observe<T>(T Function() builder) {
    final base = SingleShot<T>();
    _internal(builder, base);
    return base.value;
  }

  void _internal<T, S extends DisposersTrackable<T>>(
      T Function() builder, S base) {
    final previousData = _notifyData;
    final debouncer = EveryDebouncer(
        delay: const Duration(milliseconds: 5), retries: 4, enabled: false);
    _notifyData = NotifyData(
        updater: () => debouncer(() => base.value = builder()),
        disposers: [debouncer.cancel]);
    final result = builder();
    debouncer.start();
    base._disposers = _notifyData?.disposers;
    _notifyData = previousData;
    base.value = result;
  }

  MultiShot<T> _listen<T>(T Function() builder) {
    final base = MultiShot<T>();
    _internal(builder, base);
    return base;
  }

  T observe<T>(T Function() builder) => work<T>(() => _observe(builder))();
  MultiShot<T> listen<T>(T Function() builder) =>
      work<MultiShot<T>>(() => _listen(builder))();

  T Function() work<T>(T Function() builder) {
    return () {
      _working = true;
      final result = builder();
      _working = false;
      return result;
    };
  }
}

class NotifyData {
  const NotifyData(
      {required this.updater,
      required this.disposers,
      this.throwException = true});
  final StateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;
}

class ObxError {
  const ObxError();
  @override
  String toString() {
    return """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
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
class Shot<T> extends Reactive<T> with DisposersTrackable<T> {
  Shot() : super(null);

  @override
  bool get hasValue => _hasValue;
  bool _hasValue = false;

  @override
  set value(T value) {
    if (!hasValue) {
      _value = value;
      _hasValue = true;
      return;
    }
    super.value = value;
  }
}

mixin DisposersTrackable<T> on Reactive<T> {
  List<Disposer>? _disposers = <Disposer>[];
}

/// This is the mos basic reactive component
/// This will just update the ui when it updates
class Reactive<T> extends ListNotifier implements ValueListenable<T> {
  Reactive(T? val) : _value = val;

  bool get hasValue => null is T || _value != null;

  T? _value;

  @override
  T get value {
    if (!hasValue) {
      throw FlutterError(
          '''Trying to access `value` for $runtimeType but it's not initialized.
Make sure to initialize it first or use `ValueOrNull` instead.''');
    }
    reportRead();
    return _value as T;
  }

  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    _notify();
  }

  /// This equality override works for instances and the internal
  /// values.
  @override
  bool operator ==(Object o) {
    // Todo, find a common implementation for the hashCode of different Types.
    if (o is T) return value == o;
    if (o is ValueListenable<T>) return value == o.value;
    return false;
  }

  @override
  int get hashCode => value.hashCode;
}

/// This is used to pass private fields to other files
extension ReactiveProtectedAccess<T> on Reactive<T> {
  T get static => _value as T;
  set static(T value) => _value = value;
  void notify() => _notify();
}

/// This is used to pass private fields to other files
extension DisposerTrackableProtectedAccess<T> on DisposersTrackable<T> {
  List<Disposer>? get disposers => _disposers;
  set disposers(List<Disposer>? newDisposers) => _disposers = newDisposers;
}

/// Little helper for type checks
bool isSubtype<S, T>() => <S>[] is List<T>;

/// This allow [ever] to run properly even when the user input the wrong data
/// In debug mode assert check will advert the developper
class EmptyStreamSubscription<T> extends StreamSubscription<T> {
  @override
  Future<E> asFuture<E>([E? futureValue]) => throw FlutterError(
      '''You tried to call asFuture on an EmptyStreamSubscription
This should never append, make sure you respect contract when calling [ever]''');

  @override
  Future<void> cancel() async {}
  @override
  bool get isPaused => true;
  @override
  void onData(void Function(T data)? handleData) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void onError(Function? handleError) {}
  @override
  void pause([Future<void>? resumeSignal]) {}
  @override
  void resume() {}
}
