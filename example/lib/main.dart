import 'package:flutter/material.dart';
import 'package:obx/obx.dart';
import 'package:get/get.dart' as getx;

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test({Key? key}) : super(key: key);

  final rxString = Rx("Some String");
  final rxString2 = "Some String".obs;

  int trolol = 0;
  int trolil = 0;

  final loops = 1000;
  bool val = false;

  @override
  Widget build(context) {
    final time = DateTime.now();
    return Column(
      children: [
        Obx(() {
          rxString.data;
          trolol++;
          print("Build");
          if (trolol < loops) {
            rxString.emit();
          } else {
            print(DateTime.now().difference(time).inMilliseconds);
          }
          return Text(rxString.data);
        }),
        // getx.Obx(() {
        //   trolil++;
        //   if (trolil < loops) {
        //     rxString2.value == "" ? rxString2("trolol") : rxString2("");
        //   } else {
        //     print(DateTime.now().difference(time).inMilliseconds);
        //   }
        //   return Text(rxString2.value);
        // }),
      ],
    );
  }
}
