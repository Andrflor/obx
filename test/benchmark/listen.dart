import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

void main() async {
  print("Benchmark listen: (dispatch time | add+remove time)");
  for (int i = 0; i < 20; i++) {
    // for (int i in [0, 1, 9, 99]) {
    print("");
    print("With ${i + 1} listeners");
    await notifierTest(i);
    await rxTrest(i);
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
  print("Warning add time not working on getx");
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
