import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

func(RxBool rxBool, RxNum rxNum, RxInt rxNum2) async {
  while (true) {
    await Future.delayed(Duration(milliseconds: 1000));
    rxNum((rxNum + 0.1));
    print(rxNum.value);
    rxNum2((rxNum2 + 1) as int);
  }
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
  final rxNum2 = Rx(20);
  final rxStr = Rx("");

  Test({Key? key}) : super(key: key) {
    func(Rx(false), rxNum, rxNum2);
  }

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
        Obx(
          () => plep.value
              ? Obx(() {
                  print("Building");
                  return Column(
                    children: [
                      // Text(rxNum2.toString()),
                      Text(
                        () {
                          return observe(() {
                            return rxNum.value.toStringAsFixed(0);
                          });
                        }(),
                      ),
                    ],
                  );
                })
              : Obx(
                  () => Text("$rxStr"),
                ),
        ),
        // ElevatedButton(
        //     onPressed: () {
        //       plep.toggle();
        //     },
        //     child: Text("Toggle")),
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
