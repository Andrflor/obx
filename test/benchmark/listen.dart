import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

void main() async {
  print("Benchmark listen: (dispatch time | add+remove time)");
  // for (int i = 0; i < 20; i++) {
  for (int i in [0, 1, 9, 99]) {
    print("");
    print("With ${i + 1} listeners");
    await notifierTest(i);
    await rxTrest(i);
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
) {
  if (notifierCount == loops) {
    final end = DateTime.now();
    print(
        "$name${(end.difference(start).inMicroseconds * 1000 / loops).toStringAsFixed(0)} ns | ${addInNs.toStringAsFixed(0)} ns");
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
  stopWatch.start();
  for (int k = 0; k < loops; k++) {
    for (int j = 0; j <= i; j++) {
      notifier.addListener(listener);
      callbackList[j] = () => notifier.removeListener(listener);
    }
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
  }
  stopWatch.stop();
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    // if (i != 3) {
    // } else {
    // listener = () {
    // throw FlutterError("");
    // };
    // }
    // listener = () => notifier.removeListener(listener);
    notifier.addListener(listener);
  }

  notifier.addListener(() {
    notifierCounter++;
    show("notifier: ", start, notifierCounter, _completer, endInNs);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    notifier.value = 10;
    notifier.notifyListeners();
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
  stopWatch.start();
  for (int k = 0; k < 10; k++) {
    for (int j = 0; j <= i; j++) {
      callbackList[j] = notifier.add(Node(notifier, listener)).cancel;
    }
    print(notifier.length);
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
    print(notifier.length);
  }
  stopWatch.stop();

  print("done");
  print(notifier.length);
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    notifier.add(Node(notifier, (_) {}));
  }
  notifier.add(Node(notifier, (_) {
    notifierCounter++;
    show("newImplem: ", start, notifierCounter, _completer, endInNs);
  }));
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    notifier.value = 10;
    notifier.emit();
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
  stopWatch.start();
  for (int k = 0; k < loops; k++) {
    for (int j = 0; j <= i; j++) {
      callbackList[j] = streamController.stream.listen(listener).cancel;
    }
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
  }
  stopWatch.stop();
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    streamController.stream.listen(listener);
  }
  streamController.stream.listen((value) {
    streamCounter++;
    show("stream:   ", start, streamCounter, _completer, endInNs);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    streamController.add(10);
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
  stopWatch.start();
  for (int k = 0; k < loops; k++) {
    for (int j = 0; j <= i; j++) {
      callbackList[j] = rx.listen(listener);
    }
    for (int j = 0; j <= i; j++) {
      callbackList[j]!();
    }
  }
  stopWatch.stop();
  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  for (int j = 0; j < i; j++) {
    rx.listen(listener);
  }
  rx.listen((_) {
    notifierCounter++;
    show("obx:      ", start, notifierCounter, _completer, endInNs);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    rx.value = 10;
    rx.emit();
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
    show("getx:     ", start, notifierCounter, _completer, 0);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    rx.trigger(10);
  }
  return _completer.future;
}

class Node<T> {
  T? _value;
  T get value => _value as T;
  Node<T>? previous;
  Node<T>? next;
  NodeList _parent;

  Node(this._parent, [this._value]);

  void cancel() {
    if (previous == null && next == null) {
      _parent._first = _parent._last = null;
    }
    previous?.next = next;
    next?.previous = previous;
    previous = next = null;
  }
}

class NodeList<T> {
  T value;

  Node<Function(T e)>? _first;
  Node<Function(T e)>? _last;

  int get length {
    var current = _first;
    if (current == null) return 0;
    int len = 1;
    while (current.next != null) {
      len++;
    }
    return len;
  }

  NodeList(this.value);

  void emit() {
    if (_first == null) return;
    Node<Function(T e)>? first = _first?..value(value);
    try {
      while (!identical(first = first!.next, null)) {
        first!.value(value);
      }
    } catch (e) {
      print("Got error mesire");
    }
  }

  Node<Function(T e)> add(Node<Function(T e)> node) {
    if (_first == null) return _last = _first = node;
    node.previous = node.previous!.next = _last;
    _last = node;
    return node;
  }

  cancel(Node<T> node) {}
}
