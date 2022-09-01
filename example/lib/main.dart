import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

func(RxBool rxBool, RxNum rxNum, RxNum rxNum2) async {
  while (true) {
    await Future.delayed(Duration(microseconds: 1));

    rxNum((rxNum + 0.000001));
  }
}

ever<T>(T Function() data, Function(T value) clojure) {
  print("in data");
  print(data.hashCode);
}

bool printer() {
  print("called");
  return false;
}

int numeral = 0;

class MbEater {
  int seed;
  MbEater(this.seed) {
    data += seed.toString();
  }

  late String data =
      "lwakdlpawkdpolwakdpowakdopkawopodkawopkdopwhiouxhjcjcncn2idwopqkdfokwqmjdfqwkfpoweqjfp$seed" *
          200000;

  String eat() {
    final trol = data;
    print("eating${data[0]}");
    return toString();
  }

  @override
  String toString() => "value";
}

class Test extends StatelessWidget {
  final plep = Rx(true);

  final rxNum = RxDouble(20);
  final rxNum2 = RxDouble(20);
  final rxStr = Rx("");

  Test({Key? key}) : super(key: key) {
    // func(Rx(false), rxNum, rxNum2);
    /// Since observe outside of A reactive widget has no cost we can use it
    ever(() => equals, ((value) => value.toString()));
    ever(() => equals, print);
  }

  // Transparent composing of reactive elements
  bool get equals => observe(() => rxNum == rxNum2);

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ObxValue((data) {
        //   print("Building ObxValue");
        //   return Text(data.toString());
        // }, false.obs),
        // Obx(
        //   () {
        //     print("Building 1");
        //     return Text("$iCond");
        //   },
        // ),
        // TODO: fix non rebuild infinite loop
        Obx(() {
          print("built");
          return Text(observe(() {
            print("called");
            rxNum2(rxNum2 + 0.001);
            print(rxNum2);
            return rxNum2.toStringAsFixed(0);
          }));
        }),
        // Obx(
        //   () => plep.value
        //       ? Obx(() {
        //           print("Building");
        //           return Column(
        //             children: [
        //               // Text(rxNum2.toString()),
        //               Text(
        //                 () {
        //                   return observe(() {
        //                     return rxNum.toStringAsFixed(0);
        //                   });
        //                 }(),
        //               ),
        //             ],
        //           );
        //         })
        //       : Obx(
        //           () => Text("$rxStr"),
        //         ),
        // ),
        ElevatedButton(
            onPressed: () {
              rxNum2(rxNum2 + 0.001);
            },
            child: Text("Toggle")),
        // ElevatedButton(
        //     onPressed: () {
        //       rxNum((rxNum + 1) as int);
        //       rxNum((rxNum2 + 1) as int);
        //     },
        //     child: Text("Toggle")),
      ],
    );
  }
}
