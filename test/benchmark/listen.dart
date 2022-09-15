import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

void main() async {
  print("Benchmark listen: (dispatch time | add time | remove time)");
  for (int i = 0; i < 65; i += i == 0 ? 1 : i) {
    print("");
    print("With ${i + 1} listeners");
    await notifierTest(i);
    // await rxTrest(i);
    await nexImplemTest(i);
    await streamTest(i);
    await getxTrest(i);
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
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final endInNs2 = (stopWatch2.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    notifier.addListener(listener);
  }

  notifier.addListener(() {
    notifierCounter++;
    show("notifier: ", start, notifierCounter, _completer, endInNs, endInNs2);
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
  final callbackList = List<VoidCallback?>.filled(i + 1, null);
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
      callbackList[j]!();
    }
    stopWatch2.stop();
  }
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final endInNs2 = (stopWatch2.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    streamController.stream.listen(listener);
  }
  streamController.stream.listen((value) {
    streamCounter++;
    show("stream:   ", start, streamCounter, _completer, endInNs, endInNs2);
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
    show("getx:     ", start, notifierCounter, _completer, 0, 0);
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
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final endInNs2 = (stopWatch2.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    rx.listen(listener);
  }
  rx.listen((_) {
    notifierCounter++;
    show("obx:      ", start, notifierCounter, _completer, endInNs, endInNs2);
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
      callbackList[j] = notifier.add(RxSubscription(notifier, listener)).cancel;
    }
    stopWatch.stop();
    stopWatch2.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
    stopWatch2.stop();
  }

  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final endInNs2 = (stopWatch2.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final callbackList2 = List<VoidCallback?>.filled(i, null);
  for (int j = 0; j < i; j++) {
    callbackList2[j] = (notifier.add(RxSubscription(notifier, (_) {
      // if (notifierCounter == 3) {
      //   notifierCounter++;
      //   final node = notifier.add(RxSubscription(notifier, (_) {}));
      //   final otherNode = notifier.add(RxSubscription(notifier, (_) {}));
      //   notifier.emit();
      //   node.cancel();
      //   otherNode.cancel();
      // }
    }))
          ..pause()
          ..resume())
        .cancel;
  }

  // notifier.add(RxSubscription(notifier, (_) {
  //   for (int j = 0; j < i; j++) {
  //     callbackList2[j]!();
  //   }
  // }));
  notifier.add(RxSubscription(notifier, (_) {
    notifierCounter++;
    show("newImplem: ", start, notifierCounter, _completer, endInNs, endInNs2);
  }));
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    notifier.value = 10;
    notifier.emit();
  }
  return _completer.future;
}

// This typedef allow to have simple def for user
// RxSubscription<T> is StreamSubscription<T>
typedef RxSubscription<T> = _NodeSub<Function(T e), T>;

// For some reason it's very slow if we don't pass the whole function type
class _NodeSub<T extends Function(E e), E> implements StreamSubscription<E> {
  T? get _listener => _paused ? null : __listener;
  T? __listener;
  _NodeSub<T, E>? previous;
  _NodeSub<T, E>? next;
  NodeList<E>? _parent;

  bool _paused = false;

  _NodeSub(this._parent, [this.__listener]);

  @override
  Future<S> asFuture<S>([S? futureValue]) {
    // TODO: implement asFuture
    throw UnimplementedError();
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(void Function(E data)? handleData) {
    __listener = handleData as T;
  }

  @override
  void onDone(void Function()? handleDone) {
    // TODO: implement onDone
  }

  @override
  void onError(Function? handleError) {
    // TODO: implement onError
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

  @override
  Future<void> cancel() async {
    _parent?._unlink(this);
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

  _NodeSub<Function(T e), T>? _first;
  _NodeSub<Function(T e), T>? _last;

  int get length {
    if (_first == null) return 0;
    var current = _first;
    int len = 1;
    while ((current = current?.next) != null) {
      len++;
    }
    return len;
  }

  NodeList([this._value]);

  void emit() {
    if (_first == null) return;
    _NodeSub<Function(T e), T>? first = _first?.._listener?.call(_value as T);
    try {
      while (!identical(first = first!.next, null)) {
        first!._listener?.call(_value as T);
      }
    } catch (e) {
      print("Got error mesire");
      // Assert error is stack overlflow
      // TODO: add resume on error
    }
  }

  // TODO: unlink faster
  void _unlink(_NodeSub<Function(T e), T> node) {
    if (_first == node) {
      if (_last == node) {
        // First = Last = Node
        _first = _last = null;
        return;
      }
      // First = Node
      _first = node.next;
      _first!.previous = null;
      return;
    }
    if (_last == node) {
      // Last = Node
      _last = node.previous;
      _last!.next = null;
      return;
    }
    // Node = Random
    node.next!.previous = node.previous;
    node.previous!.next = node.next;
  }

  RxSubscription<T> add(RxSubscription<T> node) {
    if (_first == null) return _last = _first = node;
    node.previous = _last;
    return _last = _last!.next = node;
  }
}

  // void addError() {
  //   if (_first == null) return;
  //   // TODO: add cancel on error
  //   // TODO: transform into error callback
  //   _Node<Function(T e)>? first = _first?..value(_value as T);
  //   try {
  //     while (!identical(first = first!.next, null)) {
  //       first?.value(_value as T);
  //       // TODO: add cancel on error
  //       // TODO: transform into error callback
  //     }
  //   } catch (e) {
  //     print("Got error mesire");
  //     // TODO: add resume on error
  //   }
  // }
  //
  // void dispose() {
  //   if (_first == null) return;
  //   // TODO: call the done on the sub
  //   _Node<Function(T e)>? first = _first!;
  //   _first = _first!.previous = _first!._parent = _last = null;
  //   while (!identical(first = first!.next, null)) {
  //     // TODO: call the done on the sub
  //     first!.previous = first._parent = null;
  //   }
  // }
