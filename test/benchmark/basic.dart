import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:get/get.dart' as getx;
import 'package:obx/obx.dart';

final expand = Expando<String>();
final map = HashMap<Rx, String>();

main() async {
  // await getxBench();
  final rx = Rx("Lol");
  Obx(() => const Text("Text"));
  final val = rx.value.obs;
  // lel[rx] = "strong";
  // lel[val] = "strong";
  val.stream.listen((_) {
    print(lel[val]);
  });
  RMemoryTest();
  ValueNotifier<int>(0);

  for (int i = 0; i <= 10000; i++) {
    print(lel[val]);
    print(lel[rx]);
    await Future.delayed(Duration(seconds: 3));
  }
}

final lel = Expando<String>();

class RMemoryTest {}

Future<void> getxBench() async {
  print("Getx vs Obx benchmark");
  await bench(false, true);
  await bench(3, 4);
  await bench(3 as num, 4 as num);
  await bench(1.3, 2.6);
  await bench("Some string", "Another string");
  await bench(Foo(1, "first"), Foo(2, "second"));
  await bench(<String>["some string", "another", "another", "again"],
      ["some string", "another", "no more"]);
  await bench({"lol", "lil"}, {"", "a", "d"});
  await bench({
    "my second key2": Foo(1, "second"),
    "my second key3": Foo(1, "second"),
    "my second key4": Foo(1, "second"),
    "my second key6": Foo(1, "second"),
    "my second key8": Foo(1, "second"),
    "my second key10": Foo(1, "second"),
    "my second key13": Foo(1, "second"),
    "my second key14": Foo(1, "second"),
    "my second key17": Foo(1, "second"),
    "my second key15": Foo(1, "second"),
    "my second key18": Foo(1, "second"),
    "my secon1d key2": Foo(1, "second"),
    "my second k1ey2": Foo(1, "second"),
    "my second ke11y2": Foo(1, "second"),
    "my seco1nd key2": Foo(1, "second"),
    "my key": Foo(1, "first"),
    "my second key": Foo(2, "second")
  }, {
    "my key": Foo(2, "first"),
    "my second key": Foo(1, "second"),
    "my second key14": Foo(1, "second"),
  });
  print("");
}

class Foo extends Equatable {
  int val;
  String otherVal;

  Foo(this.val, this.otherVal);

  @override
  List<Object?> get props => [val, otherVal];
}

Future<void> bench<S extends Object>(S value, S diff) async {
  final boolx = value.obs;
  final rxbool = Rx(value);
  print("");
  print("Testing for $S");
  print("");
  print("Instantiation");
  await delay(() => value.obs);
  await delay(() => Rx(value));
  print("");
  print("Accesss");
  await delay(() => boolx.value);
  await delay(() => rxbool.value);
  print("");
  print("Same value assign");
  await delay(() => boolx.value = value);
  await delay(() => rxbool.value = value);
  print("");
  print("Different value assign");
  await delay(() {
    boolx.value = diff;
    boolx.value = value;
  }, 2);
  await delay(() {
    rxbool.value = diff;
    rxbool.value = value;
  }, 2);
  print("");
  print("Minimal use case");
  await delay(() {
    final val = value.obs;
    final data = val.value;
    val.value = val.value;
    val.value = diff;
  });
  await delay(() {
    final val = Rx(value);
    final data = val.value;
    val.value = val.value;
    val.value = diff;
  });
}

int index = 0;
const loops = 10000000;
const div = loops / 1000;

Future<void> delay(Function() callback, [int divider = 1]) async {
  final lib = index % 2 == 0 ? "Getx" : "Obx";
  index += 1;
  final start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    callback();
  }
  final end = DateTime.now();
  print(
      "$lib: ${(end.difference(start).inMicroseconds / (div * divider)).toStringAsFixed(2)} ns");
}
