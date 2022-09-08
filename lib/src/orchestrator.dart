import 'package:flutter/foundation.dart';
import 'rx/rx_impl/rx_impl.dart';
import 'rx/rx_impl/rx_core.dart';
import 'debouncer.dart';

// This callback remove the listener on addListener function
typedef Disposer = void Function();

// Replacing StateSetter, returns if the Widget is mounted for extra validation.
typedef StateUpdate = void Function();

abstract class Orchestrator {
  static bool get notInBuild => _notifyData == null;
  static bool get notObserving => notInBuild || _working;
  static bool _working = false;
  static NotifyData? _notifyData;

  static void add(VoidCallback listener) =>
      _notifyData!.disposers.add(listener);

  static void read(Reactive updaters) {
    final updater = _notifyData!.updater;
    // if (!updaters.containsListener(updater)) {
    // add(() => updaters.removeListener(updater));
    // }
  }

  static T append<T>(NotifyData data, T Function() builder) {
    _notifyData = data;
    final result = builder();
    if (data.disposers.isEmpty && data.throwException) {
      throw const ObxError();
    }
    _notifyData = null;
    return result;
  }

  static T observe<T>(T Function() builder) {
    final base = SingleShot<T>();
    _internal(builder, base);
    return base.value;
  }

  static void _internal<T, S extends Reactive<T>>(
      T Function() builder, S base) {
    _working = true;
    final previousData = _notifyData;
    final debouncer = EveryDebouncer(
        delay: const Duration(milliseconds: 5), retries: 4, enabled: false);
    _notifyData = NotifyData(
        updater: () => debouncer(() => base.value = builder()),
        disposers: [debouncer.cancel]);
    base.init(builder());
    debouncer.start();
    // base.disposers = _notifyData?.disposers;
    _notifyData = previousData;
    _working = false;
  }

  static MultiShot<T> listen<T>(T Function() builder) {
    final base = MultiShot<T>();
    _internal(builder, base);
    return base;
  }

  static Rx<T> fuse<T>(T Function() builder) {
    _working = true;
    final base = Rx<T>();
    final previousData = _notifyData;
    final debouncer = EveryDebouncer(
        delay: const Duration(milliseconds: 5), retries: 4, enabled: false);
    _notifyData = NotifyData(
        updater: () => debouncer(() => base.value = builder()),
        disposers: [debouncer.cancel]);
    base.value = builder();
    debouncer.start();
    // base.disposers = _notifyData?.disposers;
    _notifyData = previousData;
    _working = false;
    return base;
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
      Improper use of a [Obx] has been detected.
      You should only use [Obx] for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into [Obx]
      or insert them outside the scope that [Obx] considers suitable for an update
      (example: Obx => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an [Obx].
      """;
  }
}
