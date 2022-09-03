import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

// void main() => runApp(MaterialApp(home: Test()));
//
// func(RxBool rxBool, RxNum rxNum, RxNum rxNum2) async {
//   while (true) {
//     await Future.delayed(Duration(microseconds: 1));
//
//     rxNum((rxNum + 0.000001));
//     Rxn().emit();
//     Emitter().emit();
//   }
// }
//
// class Valuer {}
//
// extension Ext on Rx<Valuer> {
//   bool get plop => true;
// }
//
// bool printer() {
//   print("called");
//
//   return false;
// }
//
// someStringHandler(String data) {}
//
// int numeral = 0;
//
// class MbEater {
//   int seed;
//   MbEater(this.seed) {
//     data += seed.toString();
//   }
//
//   late String data =
//       "lwakdlpawkdpolwakdpowakdopkawopodkawopkdopwhiouxhjcjcncn2idwopqkdfokwqmjdfqwkfpoweqjfp$seed" *
//           200000;
//
//   String eat() {
//     final trol = data;
//     print("eating${data[0]}");
//     return toString();
//   }
//
//   @override
//   String toString() => "value";
// }
//
// class Test extends StatelessWidget {
//   final plep = Rx(true);
//
//   final rxNum = RxDouble(20);
//   final rxNum2 = RxDouble(20);
//   final rxStr = Rx("");
//
//   Test({Key? key}) : super(key: key) {
//     // func(Rx(false), rxNum, rxNum2);
//     print(Rx(null).runtimeType);
//     print(Rxn(Valuer()));
//     ever(() => equals, myHandler);
//
//     ever(
//         () => rxNum.toStringAsFixed(0) == rxNum2.toStringAsFixed(0)
//             ? "Equals"
//             : "Different",
//         someStringHandler);
//
//     print(ever(() => equals, (bool val) => val.toString()).cancel());
//     ever(() => equals, displayEqual);
//   }
//   bool tester = false;
//
//   void myHandler(bool value) =>
//       print("They are ${value ? "equals" : "diffrents"}!");
//
//   bool get equals => observe(() => rxNum == rxNum2);
//   void displayEqual(bool equality) =>
//       print("We have those ${equality ? "equals" : "inequals"}");
//   // Transparent composing of reactive elements
//
//   @override
//   Widget build(context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // ObxValue((data) {
//         //   print("Building ObxValue");
//         //   return Text(data.toString());
//         // }, false.obs),
//         // Obx(
//         //   () {
//         //     print("Building 1");
//         //     return Text("$iCond");
//         //   },
//         // ),
//         // TODO: fix non rebuild infinite loop
//         Obx(() {
//           print("built");
//           return Text(observe(() {
//             print(rxNum2);
//             return rxNum2.toStringAsFixed(0);
//           }));
//         }),
//         // Obx(
//         //   () => plep.value
//         //       ? Obx(() {
//         //           print("Building");
//         //           return Column(
//         //             children: [
//         //               // Text(rxNum2.toString()),
//         //               Text(
//         //                 () {
//         //                   return observe(() {
//         //                     return rxNum.toStringAsFixed(0);
//         //                   });
//         //                 }(),
//         //               ),
//         //             ],
//         //           );
//         //         })
//         //       : Obx(
//         //           () => Text("$rxStr"),
//         //         ),
//         // ),
//         ElevatedButton(
//             onPressed: () {
//               rxNum2(rxNum2 + 0.001);
//             },
//             child: Text("Toggle")),
//         // ElevatedButton(
//         //     onPressed: () {
//         //       rxNum((rxNum + 1) as int);
//         //       rxNum((rxNum2 + 1) as int);
//         //     },
//         //     child: Text("Toggle")),
//       ],
//     );
//   }
// }

main() async {
  final boolx = false.obs;
  final rxbool = Rx(false);
  final singleShot = SingleShot<bool>();
  final multiShot = MultiShot<bool>();

  await Future.delayed(Duration(milliseconds: 500));
  print("");
  await delay(() => false.obs);
  await delay(() => Rx(false));
  await delay(() => Shot());
  print("");
  await delay(() => boolx.toString());
  await delay(() => rxbool.toString());
  print("");
  await delay(() => boolx.value);
  await delay(() => rxbool.value);
  print("");
  await delay(() => boolx.value = false);
  await delay(() => rxbool.value = false);
  print("");
  await delay(() => boolx == 1);
  await delay(() => rxbool == 1);
  print("");
  await delay(() => boolx.value = true);
  await delay(() => rxbool.value = true);
  print("");
  await delay(() => singleShot.value);
  await delay(() => multiShot.value);

  while (true) {
    await Future.delayed(Duration(milliseconds: 500));
  }
}

Future<void> delay(Function() callback) async {
  final time = DateTime.now();
  for (int i = 0; i < 100000000; i++) {
    callback();
  }
  print(
      "Elasped: ${DateTime.now().difference(time).inMicroseconds / 100000} ns");
}

bool isSubtype<S, T>() => <S>[] is List<T>;

bool isCollection<T>() => isSubtype<T, Iterable>() || isSubtype<T, Map>();
