import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() async {
  for (int i = 0; i < 1000; i++) {
    print("");
    print("With ${i + 1} listeners");
    await notifierTest(i);
    await rxTrest(i);
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
) {
  if (notifierCount == loops) {
    final end = DateTime.now();
    print(
        "$name${(end.difference(start).inMicroseconds * 1000 / loops).toStringAsFixed(0)} ns");
    completer.complete();
  }
}

Future<void> notifierTest(int i) async {
  final _completer = Completer<void>();
  final notifier = ValueNotifier<int?>(null);
  var notifierCounter = 0;
  final start = DateTime.now();
  for (int j = 0; j < i; j++) {
    notifier.addListener(() {});
  }
  notifier.addListener(() {
    notifierCounter++;
    show("notifier: ", start, notifierCounter, _completer);
  });
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
  final start = DateTime.now();
  for (int j = 0; j < i; j++) {
    streamController.stream.listen((_) {});
  }
  streamController.stream.listen((value) {
    streamCounter++;
    show("stream:   ", start, streamCounter, _completer);
  });
  for (int i = 0; i < loops; i++) {
    streamController.add(10);
  }
  return _completer.future;
}

Future<void> rxTrest(int i) async {
  final _completer = Completer<void>();
  final rx = RxnInt.indistinct();
  var notifierCounter = 0;
  final start = DateTime.now();
  for (int j = 0; j < i; j++) {
    rx.listen((_) {});
  }
  rx.listen((_) {
    notifierCounter++;
    show("obx:      ", start, notifierCounter, _completer);
  });
  for (int i = 0; i < loops; i++) {
    rx.value = 10;
  }
  return _completer.future;
}

Future<void> getxTrest(int i) async {
  final _completer = Completer<void>();
  final rx = getx.RxnInt();
  var notifierCounter = 0;
  final start = DateTime.now();
  for (int j = 0; j < i; j++) {
    rx.listen((_) {});
  }
  rx.listen((_) {
    notifierCounter++;
    show("getx:     ", start, notifierCounter, _completer);
  });
  for (int i = 0; i < loops; i++) {
    rx.trigger(10);
  }
  return _completer.future;
}
