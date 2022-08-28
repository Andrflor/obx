import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:obx/obx.dart';

void main() async {
  Future<void> _notifierTest() async {
    await Future.delayed(Duration(seconds: 1));
    final iNotifier = ValueNotifier<int?>(null);
    var notifierCounter = 0;
    final date = DateTime.now();
    iNotifier.addListener(() {
      notifierCounter++;
      if (notifierCounter == 100) {
        print("iNotifier:${DateTime.now().difference(date).inMicroseconds} us");
      }
    });
    for (var i = 0; i < 100; i++) {
      iNotifier.value = 10;
      iNotifier.notifyListeners();
    }
  }

  Future<void> _streamTest() async {
    await Future.delayed(Duration(seconds: 1));
    final streamController = StreamController.broadcast();
    var streamCounter = 0;
    final date = DateTime.now();
    streamController.stream.listen((value) {
      streamCounter++;
      if (streamCounter == 100) {
        print("stream:${DateTime.now().difference(date).inMicroseconds} us");
        streamController.close();
      }
    });
    for (var i = 0; i < 100; i++) {
      streamController.add(10);
    }
  }

  Future<void> _rxTrest() async {
    await Future.delayed(Duration(seconds: 1));
    final iRx = (null as int?).obs;
    var notifierCounter = 0;
    final date = DateTime.now();
    iRx.addListener(() {
      notifierCounter++;
      if (notifierCounter == 100) {
        print("iRx:${DateTime.now().difference(date).inMicroseconds} us");
      }
    });
    for (var i = 0; i < 100; i++) {
      iRx.value = 10;
    }
  }

  await _notifierTest();
  await _streamTest();
  await _rxTrest();
  await _notifierTest();
  await _streamTest();
  await _rxTrest();
  await _notifierTest();
  await _streamTest();
  await _rxTrest();
  await _notifierTest();
  await _streamTest();
  await _rxTrest();

  await Future.delayed(Duration(seconds: 100));
}
