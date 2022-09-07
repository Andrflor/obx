import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() async {
  Future<void> _notifierTest() async {
    await Future.delayed(const Duration(seconds: 3));
    final notifier = ValueNotifier<int?>(null);
    var notifierCounter = 0;
    final date = DateTime.now();
    notifier.addListener(() {
      notifierCounter++;
      if (notifierCounter == 100) {
        print("notifier: ${DateTime.now().difference(date).inMicroseconds} us");
      }
    });
    for (var i = 0; i < 100; i++) {
      notifier.value = 10;
      notifier.notifyListeners();
    }
  }

  Future<void> _streamTest() async {
    await Future.delayed(const Duration(seconds: 3));
    final streamController = StreamController.broadcast();
    var streamCounter = 0;
    final date = DateTime.now();
    streamController.stream.listen((value) {
      streamCounter++;
      if (streamCounter == 100) {
        print("stream:   ${DateTime.now().difference(date).inMicroseconds} us");
        streamController.close();
      }
    });
    for (var i = 0; i < 100; i++) {
      streamController.add(10);
    }
  }

  Future<void> _rxTrest() async {
    await Future.delayed(const Duration(seconds: 3));
    final rx = RxnInt.indistinct();
    var notifierCounter = 0;
    final date = DateTime.now();
    rx.listen((_) {
      notifierCounter++;
      if (notifierCounter == 100) {
        print("obx:      ${DateTime.now().difference(date).inMicroseconds} us");
      }
    });
    for (var i = 0; i < 100; i++) {
      rx.value = 10;
    }
  }

  Future<void> _getxTrest() async {
    await Future.delayed(const Duration(seconds: 3));
    final rx = getx.RxnInt();
    var notifierCounter = 0;
    final date = DateTime.now();
    rx.listen((_) {
      notifierCounter++;
      if (notifierCounter == 100) {
        print("getx:     ${DateTime.now().difference(date).inMicroseconds} us");
        print("");
      }
    });
    for (var i = 0; i < 100; i++) {
      rx.trigger(10);
    }
  }

  await _notifierTest();
  await _rxTrest();
  await _streamTest();
  await _getxTrest();
  await _notifierTest();
  await _rxTrest();
  await _streamTest();
  await _getxTrest();
  await _notifierTest();
  await _rxTrest();
  await _streamTest();
  await _getxTrest();
  await _notifierTest();
  await _rxTrest();
  await _streamTest();
  await _getxTrest();

  await Future.delayed(Duration(seconds: 100));
}
