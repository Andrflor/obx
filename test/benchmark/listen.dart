import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;

void main() async {
  for (int i = 0; i < 25; i++) {
    print("");
    print("With ${i + 1} listeners");
    // await streamTest(i);
    // await getxTrest(i);
    await notifierTest(i);
    await rxTrest(i);
  }
}

class Reactive<T> {
  int _count = 0;
  List<int> _nullIdx = [];

  List<Function(T e)?> _listeners = List<Function(T e)?>.filled(5, null);

  static bool debugAssertNotDisposed(Reactive notifier) {
    assert(() {
      if (notifier.disposed) {
        throw FlutterError(
          'A ${notifier.runtimeType} was used after being disposed.\n'
          'Once you have called dispose() on a ${notifier.runtimeType}, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  void _addListener(Function(T e) listener) {
    assert(Reactive.debugAssertNotDisposed(this));
    if (_count == _listeners.length) {
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(_listeners.length + 5, null);
      for (int i = 0; i < _count; i++) {
        newListeners[i] = _listeners[i];
      }
      _listeners = newListeners;
    }

    _listeners[_count++] = listener;
  }

  void _removeListener(Function(T e) listener) {
    for (int i = 0; i < _count; i++) {
      if (_listeners[i] == listener) {
        _listeners[i] = null;
        _nullIdx.add(i);
        scheduleMicrotask(() => _shift());
        break;
      }
    }
  }

  void _shift() {
    if (_nullIdx.isEmpty) return;
    final List<Function(T e)?> newListeners =
        List<Function(T e)?>.filled(_listeners.length, null);
    // TODO: shift this
    _listeners = newListeners;
    _count -= _nullIdx.length;
    _nullIdx = [];
  }

  bool get disposed => _listeners.isEmpty;

  @mustCallSuper
  void dispose() {
    assert(Reactive.debugAssertNotDisposed(this));
    _listeners = List<Function(T e)?>.filled(0, null);
    _count = 0;
  }

  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void emit() {
    assert(Reactive.debugAssertNotDisposed(this));
    if (_count == 0) {
      return;
    }
    for (int i = 0; i < _count; i++) {
      _listeners[i]?.call(_value as T);
    }
  }

  T? _value;

  Reactive([T? initial]) : _value = initial;

  set value(T val) {
    _value = val;
    emit();
  }

  void trigger(T val) {
    _value = val;
    emit();
  }

  VoidCallback listen(Function(T e) callback) {
    _addListener(callback);
    return () => _removeListener(callback);
  }
}

func(dynamic e) => true;

const loops = 1;

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
    late final VoidCallback listener;
    listener = () => notifier.removeListener(listener);
    notifier.addListener(listener);
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
  final rx = Reactive<int>(0);
  var notifierCounter = 0;
  final start = DateTime.now();
  for (int j = 0; j < i; j++) {
    late final VoidCallback callback;
    callback = rx.listen((_) {
      callback();
    });
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
