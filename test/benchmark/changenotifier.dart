import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';
import 'listen.dart';

class MyChangeNotifier extends ChangeNotifier {
  int? _value;
  int get value => _value as int;
  set value(int value) {
    _value = value;
    notifyListeners();
  }
}

class ChangeNotifierBenchmark extends BenchmarkBase {
  ChangeNotifierBenchmark(this.listenerCount)
      : super('Notifier $listenerCount');

  final int listenerCount;

  MyChangeNotifier? notifier;

  @override
  void run() {
    for (int i = 0; i < 100; i++) {
      notifier!.value = i;
    }
  }

  @override
  void setup() {
    notifier = MyChangeNotifier();
    for (int i = 0; i < listenerCount; i++) {
      notifier!.addListener(() {});
    }
  }

  @override
  void teardown() {
    notifier!.dispose();
    notifier = null;
  }
}

class NotifierAddBenchmark extends BenchmarkBase {
  NotifierAddBenchmark(this.listenerCount)
      : super('Notifier add $listenerCount');

  final int listenerCount;

  MyChangeNotifier? notifier;

  @override
  void run() {
    for (int i = 0; i < listenerCount; i++) {
      notifier!.addListener(() {});
    }
  }

  @override
  void setup() {
    notifier = MyChangeNotifier();
  }

  @override
  void teardown() {
    notifier!.dispose();
    notifier = null;
  }
}

class ReactiveAddBenchmark extends BenchmarkBase {
  ReactiveAddBenchmark(this.listenerCount)
      : super('Reactive add $listenerCount');

  final int listenerCount;

  Rx<int?>? notifier;

  @override
  void run() {
    for (int i = 0; i < listenerCount; i++) {
      notifier!.listen((_) {});
    }
  }

  @override
  void setup() {
    notifier = Rx<int?>(-1);
  }

  @override
  void teardown() {
    notifier!.dispose();
    notifier = null;
  }
}

class ReactiveBenchmark extends BenchmarkBase {
  ReactiveBenchmark(this.listenerCount) : super('Reactive $listenerCount');

  final int listenerCount;

  Rx<int?>? notifier;

  @override
  void run() {
    for (int i = 0; i < 100; i++) {
      notifier!.value = i;
    }
  }

  @override
  void setup() {
    notifier = Rx<int?>(-1);
    for (int i = 0; i < listenerCount; i++) {
      notifier!.listen((_) {});
    }
  }

  @override
  void teardown() {
    notifier!.dispose();
    notifier = null;
  }
}

class RxAddBenchmark extends BenchmarkBase {
  RxAddBenchmark(this.listenerCount) : super('Rx Add $listenerCount');

  final int listenerCount;

  NodeList<int?>? notifier;

  @override
  void run() {
    for (int i = 0; i < listenerCount; i++) {
      notifier!.add(Node(notifier, (_) {}));
    }
  }

  @override
  void setup() {
    notifier = NodeList<int?>(-1);
  }

  @override
  void teardown() {
    notifier!.dispose();
    notifier = null;
  }
}

class RxBenchmark extends BenchmarkBase {
  RxBenchmark(this.listenerCount) : super('Rx $listenerCount');

  final int listenerCount;

  NodeList<int?>? notifier;

  @override
  void run() {
    for (int i = 0; i < 100; i++) {
      notifier!.value = i;
    }
  }

  @override
  void setup() {
    notifier = NodeList<int?>(-1);
    for (int i = 0; i < listenerCount; i++) {
      notifier!.add(Node(notifier, (_) {}));
    }
  }

  @override
  void teardown() {
    notifier!.dispose();
    notifier = null;
  }
}

void main() {
  final toBench = [0, 1, 2, 3, 10, 12];

  bench(
      [NotifierAddBenchmark.new, RxAddBenchmark.new, ReactiveAddBenchmark.new],
      toBench);
  bench([ChangeNotifierBenchmark.new, RxBenchmark.new, ReactiveBenchmark.new],
      toBench);
}

typedef BenchContructor = BenchmarkBase Function(int);

void bench(List<BenchContructor> benchmarks, List<int> ids) {
  for (int i in ids) {
    for (BenchContructor benchmark in benchmarks) {
      benchmark(i).report();
    }
    print('');
  }
}
