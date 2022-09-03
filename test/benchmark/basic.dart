import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

main() async {
  print("Getx vs Obx benchmark");

  await bench(false, true);
  await bench(<String>[], [""]);
  await bench(<String>{}, {""});
  await bench({"my key": const Foo(1)}, {"my key": const Foo(2)});
  await bench(1.3, 2.6);
  await bench(const Foo(1), const Foo(2));
}

class Foo {
  const Foo(this.val);
  final int val;
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
  await delay(() => boolx.value = diff);
  await delay(() => rxbool.value = diff);
  print("");
  print("Equality");
  await delay(() => boolx == 1);
  await delay(() => rxbool == 1);
}

int index = 0;
const loops = 100000000;
const div = loops / 1000;

Future<void> delay(Function() callback) async {
  final lib = index % 2 == 0 ? "Getx" : "Obx";
  index += 1;
  final start = DateTime.now();
  for (int i = 0; i < loops; i++) {
    callback();
  }
  final end = DateTime.now();
  print(
      "$lib: ${(end.difference(start).inMicroseconds / div).toStringAsFixed(2)} ns");
}
