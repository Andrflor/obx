library obx;

import 'package:collection/collection.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obx/src/rx/rx_impl/rx_types.dart';

import 'equality.dart';
import 'package:flutter/material.dart';
import 'rx/rx_impl/rx_core.dart';
import 'debouncer.dart';

part 'rx/rx_impl/rx_impl.dart';
part 'rx/rx_impl/rx_reactive.dart';
part 'rx/rx_impl/rx_subscription.dart';

// This callback remove the listener on addListener function
typedef Disposer = void Function();

// Replacing StateSetter, returns if the Widget is mounted for extra validation.
typedef StateUpdate = void Function();

abstract class Orchestrator {
  static bool get notInBuild => element == null;
  static bool get notInObserve => notifyData == null;
  static bool get notObserving => notInBuild || notifyData != null;
  static StatelessObserverComponent? element;
  static List<Reactive> reactives = [];
  static NotifyData? notifyData;

  static void _internal<T, S extends Reactive<T>>(
      T Function() builder, S base) {
    //TODO: use something more optimized and un a timeout debouncer instead of that one
    // maybe the debouncer may be a view parameter so you may have very reactive views ?
    final debouncer = EveryDebouncer(
        delay: const Duration(milliseconds: 5), retries: 4, enabled: false);
    notifyData = NotifyData(
        updater: (_) => debouncer(() => base.data = builder()),
        disposers: [debouncer.cancel]);
    reactives = [];
    base._data = builder();
    debouncer.start();
    final disposers = notifyData!.disposers;
    base.listen(null, onDone: () {
      for (int i = 0; i < disposers.length; i++) {
        disposers[i]();
      }
    });
    notifyData = null;
  }

  static void read<T>(Reactive<T> reactive) {
    for (int i = 0; i < reactives.length; i++) {
      if (reactives[i] == reactive) {
        return;
      }
    }
    notifyData!.disposers.add(reactive.listen(notifyData!.updater).syncCancel);
  }

  static T observe<T>(T Function() builder) {
    final base = SingleShot<T>();
    _internal(builder, base);
    return base.data;
  }

  static Rx<T> fuse<T>(T Function() builder, {Equality eq = const Equality()}) {
    final base = Rx<T>.withEq(eq: eq);
    _internal(builder, base);
    return base;
  }
}

class NotifyData {
  const NotifyData(
      {required this.updater,
      required this.disposers,
      this.throwException = true});
  final Function(dynamic) updater;
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

/// Component that can track changes in a reactive variable
mixin StatelessObserverComponent on StatelessElement {
  List<Subscription>? reactives = [];

  void refresh(_) {
    markNeedsBuild();
  }

  @override
  Widget build() {
    Orchestrator.element = this;
    final result = super.build();
    assert(() {
      if (reactives!.isEmpty) {
        throw const ObxError();
      }
      return true;
    }());
    Orchestrator.element = null;
    return result;
  }

  @override
  void unmount() {
    super.unmount();
    for (int i = 0; i < reactives!.length; i++) {
      reactives![i].syncCancel();
    }
    reactives = null;
  }

  void read<T>(Reactive<T> reactive) {
    for (int i = 0; i < reactives!.length; i++) {
      if (reactives![i]._parent == reactive) return;
    }
    reactives!.add(reactive.listen(refresh));
  }
}
