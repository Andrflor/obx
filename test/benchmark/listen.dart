import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() async {
  for (int i = 0; i < 6; i++) {
    await notifierTest();
    await rxTrest();
    await streamTest();
    await getxTrest();
  }
}

const loops = 1000;

void show(String name, DateTime start, int notifierCount,
    [bool carriageReturn = false]) {
  if (notifierCount == loops) {
    final end = DateTime.now();
    print(
        "$name${(end.difference(start).inMicroseconds * 1000 / loops).toStringAsFixed(0)} ns");
    if (carriageReturn) {
      print("");
    }
  }
}

Future<void> notifierTest() async {
  await Future.delayed(const Duration(seconds: 3));
  final notifier = ValueNotifier<int?>(null);
  var notifierCounter = 0;
  final start = DateTime.now();
  notifier.addListener(() {
    notifierCounter++;
    show("notifier: ", start, notifierCounter);
  });
  for (int i = 0; i < loops; i++) {
    notifier.value = 10;
    notifier.notifyListeners();
  }
}

Future<void> streamTest() async {
  await Future.delayed(const Duration(seconds: 3));
  final streamController = StreamController.broadcast();
  var streamCounter = 0;
  final start = DateTime.now();
  streamController.stream.listen((value) {
    streamCounter++;
    show("stream:   ", start, streamCounter);
  });
  for (int i = 0; i < loops; i++) {
    streamController.add(10);
  }
}

Future<void> rxTrest() async {
  await Future.delayed(const Duration(seconds: 3));
  final rx = RxnInt.indistinct();
  var notifierCounter = 0;
  final start = DateTime.now();
  rx.listen((_) {
    notifierCounter++;
    show("obx:      ", start, notifierCounter);
  });
  for (int i = 0; i < loops; i++) {
    rx.value = 10;
  }
}

Future<void> getxTrest() async {
  await Future.delayed(const Duration(seconds: 3));
  final rx = getx.RxnInt();
  var notifierCounter = 0;
  final start = DateTime.now();
  rx.listen((_) {
    notifierCounter++;
    show("getx:     ", start, notifierCounter, true);
  });
  for (int i = 0; i < loops; i++) {
    rx.trigger(10);
  }
}
