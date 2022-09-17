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
    await notifierTest(j);
    await rxTrest(j);
    await streamTest(i);
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
  final streamController = StreamController<int>.broadcast(sync: true);
  var streamCounter = 0;
  final stream = streamController.stream.asBroadcastStream();
  listener(_) {}
  final callbackList = List<Future Function()?>.filled(i + 1, null);
  late final DateTime start;
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j] = stream.listen(listener).cancel;
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
    stream.listen(listener);
  }
  stream.listen((value) {
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
  final newStream = rx.stream.async();
  final add = DateTime.now();
  final stopWatch = Stopwatch();
  final stopWatch2 = Stopwatch();
  for (int k = 0; k < loops; k++) {
    stopWatch.start();
    for (int j = 0; j <= i; j++) {
      callbackList[j] = newStream.listen(listener).cancel;
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
    newStream.listen(listener);
  }
  newStream.listen((_) {
    notifierCounter++;
    show("obx:       ", start, notifierCounter, _completer, endInNs, endInNs2);
  });
  start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    rx.data = 10;
    rx.emit();
  }
  return _completer.future;
}
