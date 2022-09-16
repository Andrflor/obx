import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

void main() async {
  print(
      "Benchmark listen: dispatch time | add time | remove time (time/listener)");

  for (int i = 0; i < 100; i++) {
    print("");
    int j = i;
    print("With ${i + 1} listeners");
    // await controlTest(i);
    // await rxTrest(i);
    await notifierTest(j);
    await nexImplemTest(j);
    await notifierTest(j);
    await nexImplemTest(j);
    await notifierTest(j);
    await nexImplemTest(j);
    await notifierTest(j);
    await nexImplemTest(j);
    await notifierTest(j);
    await nexImplemTest(j);
    await notifierTest(j);
    await nexImplemTest(j);
    await notifierTest(j);
    await nexImplemTest(j);
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
  final notifier = Reactive<int?>(0);
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
      // if (identical(notifierCounter, 3)) {
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
    show("current:   ", start, notifierCounter, _completer, endInNs, endInNs2);
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
typedef RxSubscription<T> = _NodeSub<T, Function(T value)>;
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

// For some reason that explicit Function(E value) makes it way faster
class _NodeSub<E, T extends Function(E value)> implements Subscription<E> {
  T? get _handleData => _paused ? null : __handleData;
  T? __handleData;

  ErrorCallBack? get _handleError => _paused ? null : __handleError;
  ErrorCallBack? __handleError;

  VoidCallback? get _handleDone => _paused ? null : __handleDone;
  VoidCallback? __handleDone;

  // We explicitly use dynamic here because it gives faster unlink
  dynamic _previous;
  _NodeSub<E, T>? _next;
  Reactive<E>? _parent;

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

  _NodeSub<E, T>? _close() {
    _previous = _parent = null;
    _handleDone?.call();
    return _next;
  }

  @override
  void cancel() {
    if (identical(_parent, null)) return;
    // TODO: maybe _parent!.onCancel ?
    _parent!._unlink(this);
    _parent = null;
  }
}

class Reactive<T> {
  T? _value;
  set value(T val) {
    if (_value != val) {
      _value = val;
      emit();
    }
  }

  T get value => _value as T;

  _NodeSub<T, Function(T value)>? _firstSubscrption;
  _NodeSub<T, Function(T value)>? _lastSubscription;

  Reactive([this._value]);

  Subscription<T> listen(Function(T value)? onData,
      {ErrorCallBack? onError, VoidCallback? onDone, bool? cancelOnError}) {
    final node = _NodeSub<T, Function(T value)>(this, onData, onError, onDone);
    if (identical(_firstSubscrption, null)) {
      _lastSubscription = node;
      return _firstSubscrption = node;
    }
    node._previous = _lastSubscription;
    return _lastSubscription = _lastSubscription!._next = node;
  }

  void emit() {
    if (identical(_firstSubscrption, null)) return;
    var currentSubscription = _firstSubscrption
      ?.._handleData?.call(_value as T);
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleData?.call(_value as T);
      }
    } catch (exception, trace) {
      _reportError("emit", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueEmitting(currentSubscription!._next);
    }
  }

  void addError(Object error, [StackTrace? trace]) {
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription = _firstSubscrption;
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleError?.call(error, trace);
      }
    } catch (exception, trace) {
      _reportError("addError", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueAddingError(error, trace, currentSubscription!._next);
    }
  }

  void close() {
    // No need to close if we have no _firstSubscrption
    if (identical(_firstSubscrption, null)) return;
    _NodeSub<T, Function(T e)>? currentSubscription = _firstSubscrption;
    _firstSubscrption = _lastSubscription = null;
    try {
      while (!identical(
          currentSubscription = currentSubscription!._close(), null)) {}
    } catch (exception, trace) {
      _reportError("close", exception, trace);
      // StackOverflowError is impossible here
      // recursive function to avoid try catching on every loop
      _continueClosing(currentSubscription!._next);
    }
  }

  void _continueEmitting(_NodeSub<T, Function(T e)>? currentSubscription) {
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleData?.call(_value as T);
      }
    } catch (exception, trace) {
      _reportError("emit", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueEmitting(currentSubscription!._next);
    }
  }

  void _continueAddingError(Object error, StackTrace? trace,
      _NodeSub<T, Function(T e)>? currentSubscription) {
    try {
      while (
          !identical(currentSubscription = currentSubscription!._next, null)) {
        currentSubscription!._handleError?.call(error, trace);
      }
    } catch (exception, trace) {
      _reportError("addError", exception, trace);
      // On stack overflow we break the loop
      if (exception is StackOverflowError) return;
      // recursive function to avoid try catching on every loop
      _continueAddingError(error, trace, currentSubscription!._next);
    }
  }

  void _continueClosing(_NodeSub<T, Function(T e)>? currentSubscription) {
    try {
      while (!identical(
          currentSubscription = currentSubscription!._close(), null)) {}
    } catch (exception, trace) {
      _reportError("close", exception, trace);
      // StackOverflowError is impossible here
      // recursive function to avoid try catching on every loop
      _continueClosing(currentSubscription!._next);
    }
  }

  void _unlink(node) {
    if (identical(_firstSubscrption, node)) {
      if (identical(_lastSubscription, node)) {
        // First = Last = Node
        _firstSubscrption = _lastSubscription = null;
        return;
      }
      // First = Node
      _firstSubscrption = node._next;
      _firstSubscrption!._previous = null;
      return;
    }
    if (identical(_lastSubscription, node)) {
      // Last = Node
      _lastSubscription = node._previous;
      _lastSubscription!._next = null;
      return;
    }
    // Node = Random
    node._next!._previous = node._previous;
    node._previous!._next = node._next;
  }

  void _reportError(String kind, Object exception, [StackTrace? trace]) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: exception,
      stack: trace,
      library: 'obx library',
      silent: true,
      context: ErrorSummary(
          'dispatching $kind for $runtimeType\nThis error was catched to ensure that listener events are dispatched\nSome of your listeners for this Rx is throwing an exception\nMake sure that your listeners do not throw to ensure optimal performance'),
    ));
  }
}
