import 'package:flutter/foundation.dart';
import 'rx/rx_impl/rx_impl.dart';
import 'debouncer.dart';
import 'package:collection/collection.dart';

// This callback remove the listener on addListener function
typedef Disposer = void Function();

// Replacing StateSetter, returns if the Widget is mounted for extra validation.
// if it brings overhead the extra call,
typedef StateUpdate = void Function();

abstract class Notifier {
  static bool get notInBuild => _notifyData == null;
  static NotifyData? _notifyData;

  static void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  static void read(ListNotifiable updaters) {
    final listener = _notifyData!.updater;
    if (!updaters.containsListener(listener)) {
      _notifyData?.disposers.add(updaters.addListener(listener));
    }
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

  static void _internal<T, S extends DisposersTrackable<T>>(
      T Function() builder, S base) {
    final previousData = _notifyData;
    final debouncer = EveryDebouncer(
        delay: const Duration(milliseconds: 5), retries: 4, enabled: false);
    _notifyData = NotifyData(
        updater: () => debouncer(() => base.value = builder()),
        disposers: {debouncer.cancel});
    final result = builder();
    debouncer.start();
    base.disposers = _notifyData?.disposers;
    _notifyData = previousData;
    base.value = result;
  }

  static MultiShot<T> listen<T>(T Function() builder) {
    final base = MultiShot<T>();
    _internal(builder, base);
    return base;
  }
}

class NotifyData {
  const NotifyData(
      {required this.updater,
      required this.disposers,
      this.throwException = true});
  final StateUpdate updater;
  final Set<VoidCallback> disposers;
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

/// Little helper for type checks
bool isSubtype<S, T>() => <S>[] is List<T>;

/// Little helper to check if a type is a collection
bool isList<T>() => isSubtype<T, List?>();
bool isMap<T>() => isSubtype<T, Map?>();
bool isSet<T>() => isSubtype<T, Set?>();
bool isIterable<T>() => isSubtype<T, Iterable?>();

/// Defines the equalizer depending on T
Equality equalizer<T>() {
  if (isIterable<T>()) {
    if (isList<T>()) {
      return const ListEquality();
    }
    if (isSet<T>()) {
      return const SetEquality();
    } else {
      return const IterableEquality();
    }
  } else if (isMap<T>()) {
    return const MapEquality();
  } else {
    return const DefaultEquality();
  }
}
