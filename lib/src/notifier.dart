import 'package:flutter/foundation.dart';

import 'debouncer.dart';

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
  static bool get inBuild => instance._notifyData != null;

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

  T observe<T>(T Function() builder) {
    if (_notifyData == null) return builder();
    final previousData = _notifyData;
    final base = SingleShot<T>();
    final debouncer =
        EveryDebouncer(delay: const Duration(milliseconds: 5), retries: 4);
    _notifyData = NotifyData(
        updater: () => debouncer(() => base.value = builder()),
        disposers: [builder]);
    final result = builder();
    _notifyData = previousData;
    base.value = result;
    return base.value;
  }

  T silent<T>(T Function() builder) {
    final previousData = _notifyData;
    _notifyData = null;
    final result = builder();
    _notifyData = previousData;
    return result;
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
/// It's the basic class for the observe function
/// It's name comes from the fact that it is set up
/// Then it fire once, and then it dies
/// So it really has a "single shot"
class SingleShot<T> extends Reactive<T> {
  SingleShot() : super(null);

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

  @override
  void _notify() {
    super._notify();
    dispose();
  }
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

// This mixin is used to provide Actions to call
mixin Actionable<T> on Reactive<T> {
  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return _value;
  }

  /// Trigger update with a new value
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    _value = v;
    _notify();
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  void emit() {
    if (hasValue) {
      trigger(_value as T);
    }
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

bool isSubtype<S, T>() => <S>[] is List<T>;
