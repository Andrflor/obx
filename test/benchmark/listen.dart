import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

void main() async {
  print(
      "Benchmark listen: dispatch time | add time | remove time (time/listener)");
  for (int i = 0; i < 100; i++) {
    print("");
    print("With ${i + 1} listeners");
    await controlTest(i);
    await notifierTest(i);
    // await rxTrest(i);
    await nexImplemTest(i);
    // await streamTest(i);
    // await getxTrest(i);
  }
}

const loops = 1000000;

void show(
  String name,
  DateTime start,
  int notifierCount,
  Completer completer,
  double addInNs,
  double addInNs2,
) {
  if (notifierCount == loops) {
    final end = DateTime.now();
    print(
        "$name${(end.difference(start).inMicroseconds * 1000 / loops).toStringAsFixed(0)} ns | ${addInNs.toStringAsFixed(0)} ns | ${addInNs2.toStringAsFixed(0)} ns");
    completer.complete();
  }
}

double adjust(int i) => linearcCoeff * (i + 1) + linearAffix;

// Change does consts to get 0ns on remove
const linearcCoeff = 1.783;
const linearAffix = 33.31;

// Change first linearCoeff and LinearAffix then,
// When you get 0ns on remove control change this to get 0ns on add
const adaptConst = 2;

Future<void> controlTest(int i) async {
  final _completer = Completer<void>();
  final notifier = ValueNotifier<int?>(null);
  final callbackList = List<VoidCallback?>.filled(i + 1, null);
  late final DateTime start;
  listener() {}
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j] = () {};
    }
    stopWatch.stop();
    stopWatch2.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
    stopWatch2.stop();
  }
  final endInNs =
      ((stopWatch.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1) -
          adaptConst;
  final endInNs2 =
      ((stopWatch2.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1);
  for (int j = 0; j < i; j++) {
    notifier.addListener(listener);
  }
  show("control:   ", DateTime.now(), loops, _completer, endInNs, endInNs2);
  return _completer.future;
}

Future<void> notifierTest(int i) async {
  final _completer = Completer<void>();
  final notifier = ValueNotifier<int?>(null);
  var notifierCounter = 0;
  final callbackList = List<VoidCallback?>.filled(i + 1, null);
  late final DateTime start;
  listener() {}
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      notifier.addListener(listener);
      callbackList[j] = () => notifier.removeListener(listener);
    }
    stopWatch.stop();
    stopWatch2.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
    stopWatch2.stop();
  }
  final endInNs =
      ((stopWatch.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1) -
          adaptConst;
  final endInNs2 =
      ((stopWatch2.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1);
  for (int j = 0; j < i; j++) {
    notifier.addListener(listener);
  }

  notifier.addListener(() {
    notifierCounter++;
    show("notifier:  ", start, notifierCounter, _completer, endInNs, endInNs2);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    notifier.value = 10;
    notifier.notifyListeners();
  }
  return _completer.future;
}

Future<void> streamTest(int i) async {
  final _completer = Completer<void>();
  final streamController = StreamController.broadcast();
  var streamCounter = 0;
  listener(_) {}
  final callbackList = List<Future Function()?>.filled(i + 1, null);
  late final DateTime start;
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j] = streamController.stream.listen(listener).cancel;
    }
    stopWatch.stop();
    stopWatch2.start();
    for (int j = 0; j <= i; j++) {
      await callbackList[j]!();
    }
    stopWatch2.stop();
  }

  final endInNs =
      ((stopWatch.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1) -
          adaptConst;
  final endInNs2 = (stopWatch2.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    streamController.stream.listen(listener);
  }
  streamController.stream.listen((value) {
    streamCounter++;
    show("stream:    ", start, streamCounter, _completer, endInNs, endInNs2);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    streamController.add(10);
  }
  return _completer.future;
}

Future<void> getxTrest(int i) async {
  final _completer = Completer<void>();
  final rx = getx.RxnInt();
  final callbackList = List<VoidCallback?>.filled(i + 1, null);
  var notifierCounter = 0;
  late final DateTime start;
  listener(_) {}
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  // stopWatch.start();
  // for (int k = 0; k < loops; k++) {
  //   for (int j = 0; j <= i; j++) {
  //     callbackList[j] = rx.listen(listener).cancel;
  //   }
  //   for (int j = 0; j <= i; j++) {
  //     callbackList[j]!();
  //   }
  // }
  // stopWatch.stop();
  // final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    rx.listen(listener);
  }
  rx.listen((_) {
    notifierCounter++;
    show("getx:      ", start, notifierCounter, _completer, 0, 0);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    rx.trigger(10);
  }
  return _completer.future;
}

Future<void> rxTrest(int i) async {
  final _completer = Completer<void>();
  final rx = Rx(0);
  var notifierCounter = 0;
  final callbackList = List<VoidCallback?>.filled(i + 1, null);
  late final DateTime start;
  listener(_) {}
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j] = rx.listen(listener);
    }
    stopWatch.stop();
    stopWatch2.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
    stopWatch2.stop();
  }
  stopWatch.stop();
  final endInNs =
      ((stopWatch.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1) -
          adaptConst;
  final endInNs2 =
      ((stopWatch2.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1);
  for (int j = 0; j < i; j++) {
    rx.listen(listener);
  }
  rx.listen((_) {
    notifierCounter++;
    show("obx:       ", start, notifierCounter, _completer, endInNs, endInNs2);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    rx.value = 10;
    rx.emit();
  }
  return _completer.future;
}

Future<void> nexImplemTest(int i) async {
  final _completer = Completer<void>();
  final notifier = NodeList<int?>(0);
  var notifierCounter = 0;
  final callbackList = List<VoidCallback?>.filled(i + 1, null);
  late final DateTime start;
  listener(_) {}
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j] = notifier.listen(listener).cancel;
    }
    stopWatch.stop();
    stopWatch2.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
    stopWatch2.stop();
  }

  final endInNs =
      ((stopWatch.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1) -
          adaptConst;
  final endInNs2 =
      ((stopWatch2.elapsedMicroseconds * 1000) / loops - adjust(i)) / (i + 1);
  final callbackList2 = List<VoidCallback?>.filled(i, null);
  for (int j = 0; j < i; j++) {
    callbackList2[j] = notifier.listen((_) {
      // if (notifierCounter == 3) {
      //   notifierCounter++;
      //   final node = notifier.add(RxSubscription(notifier, (_) {}));
      //   final otherNode = notifier.add(RxSubscription(notifier, (_) {}));
      //   notifier.emit();
      //   node.cancel();
      //   otherNode.cancel();
      // }
    }).cancel;
  }

  // notifier.add(RxSubscription(notifier, (_) {
  //   for (int j = 0; j < i; j++) {
  //     callbackList2[j]!();
  //   }
  // }));
  notifier.listen((_) {
    notifierCounter++;
    show("newImplem: ", start, notifierCounter, _completer, endInNs, endInNs2);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    notifier.value = 10;
    notifier.emit();
  }
  return _completer.future;
}

// This typedef allow to have simple def for user
// RxSubscription<T> is StreamSubscription<T>
typedef RxSubscription<T> = _NodeSub<Function(T value), T>;
typedef ErrorCallBack = void Function(Object error, [StackTrace? trace]);

/// Override of StreamSubscription to make cancel Futureor<void>
abstract class Subscription<T> {
  FutureOr<void> cancel() {}
  void onData(Function(T value)? handleData);
  void onError(ErrorCallBack? handleError);
  void onDone(VoidCallback? handleDone);
  void pause([Future<void>? resumeSignal]);
  void resume();
  bool get isPaused;
  Future<E> asFuture<E>([E? futureValue]);
}

// For some reason it's very slow if we don't pass the whole function type
class _NodeSub<T extends Function(E value), E> implements Subscription<E> {
  T? get _handleData => _paused ? null : __handleData;
  T? __handleData;

  ErrorCallBack? get _handleError => _paused ? null : __handleError;
  ErrorCallBack? __handleError;

  VoidCallback? get _handleDone => _paused ? null : __handleDone;
  VoidCallback? __handleDone;

  _NodeSub<T, E>? previous;
  _NodeSub<T, E>? next;
  NodeList<E>? _parent;

  bool _paused = false;

  _NodeSub(this._parent,
      [this.__handleData, this.__handleError, this.__handleDone]);

  @override
  Future<S> asFuture<S>([S? futureValue]) {
    final completer = Completer<S>();
    onDone(() => completer.complete(futureValue as S));
    onError((Object error, [StackTrace? trace]) {
      completer.completeError(error, trace);
      cancel();
    });
    return completer.future;
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(void Function(E data)? handleData) {
    __handleData = handleData as T;
  }

  @override
  void onDone(VoidCallback? handleDone) {
    __handleDone = handleDone;
  }

  @override
  void onError(ErrorCallBack? handleError) {
    __handleError = handleError;
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    resumeSignal?.then((_) => _paused = false);
  }

  @override
  void resume() {
    _paused = false;
  }

  _NodeSub<T, E>? _close() {
    previous = _parent = null;
    _handleDone?.call();
    return next;
  }

  @override
  void cancel() {
    if (_parent == null) return;
    _parent!._unlink(this);
    // TODO: parent onCancel??
    // TODO: maybe add this line to prevent memory leak?
    // previous = next = null;
    _parent = null;
  }
}

class NodeList<T> {
  T? _value;
  set value(T val) {
    if (_value != val) {
      _value = val;
      emit();
    }
  }

  _NodeSub<Function(T e), T>? _firstSubscrption;
  _NodeSub<Function(T e), T>? _lastSubscription;

  bool get hasListeners => _firstSubscrption != null;

  NodeList([this._value]);

  void _unlink(_NodeSub<Function(T e), T> node) {
    if (_firstSubscrption == node) {
      if (_lastSubscription == node) {
        // First = Last = Node
        _firstSubscrption = _lastSubscription = null;
        return;
      }
      // First = Node
      _firstSubscrption = node.next;
      _firstSubscrption!.previous = null;
      return;
    }
    if (_lastSubscription == node) {
      // Last = Node
      _lastSubscription = node.previous;
      _lastSubscription!.next = null;
      return;
    }
    // Node = Random
    node.next!.previous = node.previous;
    node.previous!.next = node.next;
  }

  Subscription<T> listen(Function(T value)? onData,
      {ErrorCallBack? onError, VoidCallback? onDone, bool? cancelOnError}) {
    final node = _NodeSub<Function(T value), T>(this, onData, onError, onDone);
    if (_firstSubscrption == null) {
      return _lastSubscription = _firstSubscrption = node;
    }
    node.previous = _lastSubscription;
    return _lastSubscription = _lastSubscription!.next = node;
  }

  void emit() {
    if (_firstSubscrption == null) return;
    _NodeSub<Function(T e), T>? first = _firstSubscrption
      ?.._handleData?.call(_value as T);
    try {
      while (!identical(first = first!.next, null)) {
        first!._handleData?.call(_value as T);
      }
    } catch (e) {
      print("Got error mesire");
      // Assert error is stack overlflow
      // TODO: add resume on error
    }
  }

  void addError(Object error, [StackTrace? trace]) {
    if (_firstSubscrption == null) return;
    _NodeSub<Function(T e), T>? first = _firstSubscrption;
    try {
      while (!identical(first = first!._close(), null)) {}
    } catch (e) {
      print("Got error mesire");
      // Assert error is stack overlflow
      // TODO: add resume on error
    }
  }

  void close() {
    if (_firstSubscrption == null) return;
    _NodeSub<Function(T e), T>? first = _firstSubscrption;
    _firstSubscrption = _lastSubscription = null;
    try {
      while (!identical(first = first!._close(), null)) {}
    } catch (e) {
      print("Got error mesire");
      // TODO: resume closing on error
    }
  }
}
