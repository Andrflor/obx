import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

void main() async {
  print("Benchmark listen: (dispatch time | add time | remove time)");
  for (int i = 1; i < 10; i++) {
    print("");
    print("With ${i + 1} listeners");
    // await notifierTest(i);
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
  // for (int k = 0; k < loops; k++) {
  //   stopWatch.start();
  //   for (int j = 0; j <= i; j++) {
  //     callbackList[j] = notifier.add(Node(notifier, listener)).cancel;
  //   }
  //   stopWatch.stop();
  //   stopWatch2.start();
  //   for (int j = 0; j <= i; j++) {
  //     callbackList[j]!();
  //   }
  //   stopWatch2.stop();
  // }

  final endInNs = (stopWatch.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final endInNs2 = (stopWatch2.elapsedMicroseconds * 1000) / (loops * (i + 1));
  final callbackList2 = List<VoidCallback?>.filled(i, null);
  for (int j = 0; j < i; j++) {
    callbackList2[j] = notifier
        .add(Node(notifier, (_) {
          // if (notifierCounter == 3) {
          //   notifierCounter++;
          //   final node = notifier.add(Node(notifier, (_) {}));
          //   final otherNode = notifier.add(Node(notifier, (_) {}));
          //   notifier.emit();
          //   node.cancel();
          //   otherNode.cancel();
          // }
        }))
        .cancel;
  }

  // notifier.add(Node(notifier, (_) {
  //   for (int j = 0; j < i; j++) {
  //     callbackList2[j]!();
  //   }
  // }));
  notifier.add(Node(notifier, (_) {
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

class Node<T> {
  Function(T e)? _listener;
  Node<T>? previous;
  Node<T>? next;
  NodeList<T>? _parent;

  Node(this._parent, [this._listener]);

  void cancel() {
    _parent?._unlink(this);
  }

  // void cancel() {
  //   // Already canceled
  //   if (_parent == null) return;
  //   if (previous == null) {
  //     if (next == null) {
  //       // Single node
  //       return _parent = _parent!._first = _parent!._last = null;
  //     }
  //     // First node
  //     return next = next!.previous = _parent = null;
  //   }
  //   if (next == null) {
  //     // Last node
  //     return previous = previous!.next = _parent = null;
  //   }
  //   // Random node
  //   previous?.next = next;
  //   next?.previous = previous;
  //   previous = next = _parent = null;
  // }
}

class NodeList<T> {
  T? _value;
  set value(T val) {
    if (_value != val) {
      _value = val;
      emit();
    }
  }

  Node<T>? _first;
  Node<T>? _last;

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
    Node<T>? first = _first?.._listener?.call(_value as T);
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

  void _unlink(Node<T> child) {
    if (child == _first) {
      _first = child.next;
      _first?.previous = child._parent = null;
      if (child == _last) {
        _last = child.previous;
        _last?.next = null;
        return;
      }
      return;
    }
    if (child == _last) {
      _last = child.previous;
      _last?.next = child._parent = null;
      return;
    }
    child.next!.previous = child.previous;
    child.previous!.next = child.previous;
    child._parent = null;
  }

  void addError() {
    if (_first == null) return;
    // TODO: add cancel on error
    // TODO: transform into error callback
    Node<T>? first = _first?.._listener?.call(_value as T);
    try {
      while (!identical(first = first!.next, null)) {
        first?._listener?.call(_value as T);
        // TODO: add cancel on error
        // TODO: transform into error callback
      }
    } catch (e) {
      print("Got error mesire");
      // TODO: add resume on error
    }
  }

  void dispose() {
    if (_first == null) return;
    // TODO: call the done on the sub
    Node<T>? first = _first!;
    _first = _first!.previous = _first!._parent = _last = null;
    while (!identical(first = first!.next, null)) {
      // TODO: call the done on the sub
      first!.previous = first._parent = null;
    }
  }

  Node<T> add(Node<T> node) {
    if (_first == null) return _last = _first = node;
    node.previous = _last;
    return _last = _last!.next = node;
  }

  cancel(Node<T> node) {}
}
