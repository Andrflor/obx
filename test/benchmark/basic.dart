import 'package:equatable/equatable.dart';
import 'package:get/get_utils/src/equality/equality.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

main() async {
  await getxBench();
}

getxBench() async {
  print("Getx vs Obx benchmark");
  await bench(false, true);
  await bench(<String>[], [""]);
  await bench(<String>{}, {""});
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
    "my second key18": Foo(1, "second"),
    "my second key22": Foo(1, "second"),
    "my second key14": Foo(1, "second"),
    "my s1econd key3": Foo(1, "second"),
    "my s2econd key2": Foo(1, "second"),
    "my s3econd key2": Foo(1, "second"),
    "my s4econd key2": Foo(1, "second"),
    "my s5econd key2": Foo(1, "second"),
    "my s6econd key2": Foo(1, "second"),
    "my s6econd key2": Foo(1, "second"),
    "my sec1ond key2": Foo(1, "second"),
    "my s7ec1ond key2": Foo(1, "second"),
    "my secon1d key2": Foo(1, "second"),
    "my sec1ond key2": Foo(1, "second"),
    "my sec1ond key2": Foo(1, "second"),
    "my second1 key2": Foo(1, "second"),
    "my second key2": Foo(1, "second"),
    "my second k1ey2": Foo(1, "second"),
    "my second k1ey2": Foo(1, "second"),
    "my second ke11y2": Foo(1, "second"),
    "my seco1nd key2": Foo(1, "second"),
    "my key": Foo(1, "first"),
    "my second key": Foo(2, "second")
  }, {
    "my key": Foo(2, "first"),
    "my second key": Foo(1, "second"),
  });
  await bench(3, 4);
  await bench(1.3, 2.6);
  await bench(Foo(1, "first"), Foo(2, "second"));
}

class Foo extends Equatable {
  int val;
  String otherVal;

  Foo(this.val, this.otherVal);

  @override
  List<Object?> get props => [val, otherVal];
}

void rx<T>(T value) {
  print(value.obs.runtimeType);
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
const loops = 10000000;
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
